provider "aws" {
  region = "ap-south-1"
}

# --------------------------------------------------
# Default VPC in ap-south-1
# --------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

# --------------------------------------------------
# Default Subnets in Default VPC
# --------------------------------------------------

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --------------------------------------------------
# Default Security Group
# --------------------------------------------------

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

# --------------------------------------------------
# IAM Role for EKS Cluster
# --------------------------------------------------

resource "aws_iam_role" "master" {
  name = "in-eks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

# --------------------------------------------------
# IAM Role for Worker Nodes
# --------------------------------------------------

resource "aws_iam_role" "worker" {
  name = "in-eks-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

# --------------------------------------------------
# Cluster Autoscaler Policy
# --------------------------------------------------

resource "aws_iam_policy" "autoscaler" {
  name = "autoscaler-mum-1"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]

      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "S3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

# --------------------------------------------------
# Instance Profile
# --------------------------------------------------

resource "aws_iam_instance_profile" "worker" {
  depends_on = [
    aws_iam_role.worker
  ]

  name = "mumbai-eks"

  role = aws_iam_role.worker.name
}

# --------------------------------------------------
# EKS Cluster
# --------------------------------------------------

resource "aws_eks_cluster" "eks" {
  name     = "eks"
  role_arn = aws_iam_role.master.arn

  vpc_config {
    subnet_ids = slice(data.aws_subnets.default.ids, 0, 2)

    security_group_ids = [
      data.aws_security_group.default.id
    ]
  }

  tags = {
    Name        = "eks"
    Environment = "dev"
    Terraform   = "true"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

# --------------------------------------------------
# EKS Node Group
# --------------------------------------------------

resource "aws_eks_node_group" "node_grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "project-eks-node-grou"
  node_role_arn   = aws_iam_role.worker.arn

  subnet_ids = slice(data.aws_subnets.default.ids, 0, 2)

  capacity_type  = "ON_DEMAND"
  disk_size      = 23
  instance_types = ["c7i-flex.large"]

  labels = {
    env = "dev"
  }

  tags = {
    Name = "eks-south-1"
  }

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.autoscaler
  ]
}

# --------------------------------------------------
# OIDC Provider
# --------------------------------------------------

data "aws_eks_cluster" "eks_oidc" {
  name = aws_eks_cluster.eks.name

  depends_on = [
    aws_eks_cluster.eks
  ]
}

data "tls_certificate" "oidc_thumbprint" {
  url = data.aws_eks_cluster.eks_oidc.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint
  ]

  url = data.aws_eks_cluster.eks_oidc.identity[0].oidc[0].issuer
}

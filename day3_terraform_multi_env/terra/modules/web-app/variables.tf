variable "environment" {
  description = "The name of the environment (e.g., test, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance (Ubuntu for prod, Amazon Linux for test)"
  type        = string
}

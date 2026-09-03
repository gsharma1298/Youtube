module "web_app" {
  source = "../../modules/web-app"

  environment   = "test"
  instance_type = "t3.micro"
  # Amazon Linux 2023 AMI for ap-south-1
  ami_id        = "ami-0f5ee92e2d63afc18"
}

module "web_app" {
  source = "../../modules/web-app"

  environment   = "prod"
  instance_type = "t3.micro"
  # Ubuntu 22.04 LTS AMI for ap-south-1
  ami_id        = "ami-0f58b397bc5c1f2e8"
}

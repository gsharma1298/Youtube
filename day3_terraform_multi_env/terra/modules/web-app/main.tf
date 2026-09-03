# Example: Creating an EC2 instance
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "${var.environment}"
    Environment = var.environment
  }
}

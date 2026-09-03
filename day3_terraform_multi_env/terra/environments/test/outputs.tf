output "instance_id" {
  description = "The ID of the test EC2 instance"
  value       = module.web_app.instance_id
}

output "instance_public_ip" {
  description = "The public IP of the test EC2 instance"
  value       = module.web_app.instance_public_ip
}

output "instance_private_ip" {
  description = "The private IP of the test EC2 instance"
  value       = module.web_app.instance_private_ip
}

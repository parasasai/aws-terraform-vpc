output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "The ID of the Security Group allowing HTTP/SSH"
  value       = aws_security_group.public_sg.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.nginx_asg.name
}

output "key_pair_name" {
  description = "The name of the generated AWS Key Pair"
  value       = aws_key_pair.deployer.key_name
}

output "private_key_path" {
  description = "Local path where the generated private key file is stored"
  value       = pathexpand("~/.ssh/${var.key_pair_name}.pem")
}

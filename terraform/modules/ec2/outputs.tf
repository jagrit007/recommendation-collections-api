# EC2 Module - outputs.tf

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.app[*].id
}

output "private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.app[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses of the EC2 instances (if applicable)"
  value       = aws_instance.app[*].public_ip
}
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "HTTP URL of the EC2 web server."
  value       = "http://${aws_instance.web.public_ip}"
}

output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.project.bucket
}

output "availability_zone" {
  description = "Availability Zone used for the public subnet."
  value       = aws_subnet.public.availability_zone
}

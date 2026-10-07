variable "aws_region" {
  description = "AWS region for the Lecture 19 project."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix used for AWS resources."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

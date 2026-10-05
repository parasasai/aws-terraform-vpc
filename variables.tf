variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_a_cidr" {
  description = "Public subnet A - AZ a"
  type        = string
  default     = "10.0.1.0/24"
}  

variable "subnet_b_cidr" {
  description = "Public subnet B - AZ b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ami_id" {
  description = "AMI ID for the launch template" 
  type        = string
  default     = "ami-0303e2e4a29f041a3"
}

variable "instance_type" {
  description = "EC2 instance type" 
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 key pair name" 
  type        = string
  default     = "terraform-key"
}

variable "asg_min" {
  description = "ASG minimum instance Count" 
  type        = number
  default     = 1
}

variable "asg_desired" {
  description = "ASG desired instance Count" 
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "ASG Maximum instance Count" 
  type        = number
  default     = 2
}

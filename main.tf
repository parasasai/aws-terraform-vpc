terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = { Name = "tf-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "tf-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = { Name = "tf-public-subnet-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  
  tags = { Name = "tf-public-subnet-b" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "tf-public-rt" }
}

resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "public_sg" {
  name        = "tf-public-sg"
  description = "Allow SSH, HTTP, HTTPS from anywhere"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tf-public-sg" }
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = pathexpand("~/.ssh/${var.key_pair_name}.pem")
  file_permission = "0400"
}

resource "aws_launch_template" "nginx_lt" {
  name_prefix   = "tf-nginx-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  
  user_data = filebase64("userdata.sh")

# ---> THIS BLOCK TO FIX THE BLANK INSTANCE ID <---
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforces secure IMDSv2
    http_put_response_hop_limit = 2          # Allows the token to pass to the script
  }

  
  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "tf-nginx-asg-instance" }
  }

  tags = { Name = "tf-nginx-launch-template" }
}

resource "aws_autoscaling_group" "nginx_asg" {
  name             = "tf-nginx-asg"
  min_size         = var.asg_min
  desired_capacity = var.asg_desired
  max_size         = var.asg_max
  
  vpc_zone_identifier = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  launch_template {
    id      = aws_launch_template.nginx_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "tf-asg-nginx"
    propagate_at_launch = true
  }

  tag {
    key                 = "managed by"
    value               = "terraform"
    propagate_at_launch = true
  }

  depends_on = [aws_internet_gateway.igw]
}

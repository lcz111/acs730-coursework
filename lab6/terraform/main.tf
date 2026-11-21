terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Course = "ACS730"
      Lab    = "lab6"
    }
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "lab6_web" {
  name_prefix = "acs730-lab6-web-"
  description = "Lab 6 web servers - HTTP only"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "acs730-lab6-web-sg"
  }
}

resource "aws_instance" "lab6_web" {
  count = 2

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile = "LabInstanceProfile"

  vpc_security_group_ids = [
    aws_security_group.lab6_web.id
  ]

  tags = {
    Name = "acs730-lab6-web-${count.index + 1}"
    Lab  = "lab6"
    Role = "web"
  }
}



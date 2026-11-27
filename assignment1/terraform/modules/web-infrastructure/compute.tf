data "aws_ami" "al2023" {
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

locals {
  ami_id      = data.aws_ami.al2023.id
  subnet_keys = sort(keys(aws_subnet.public))
}

resource "aws_instance" "web" {
  count = var.instance_count

  ami           = local.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public[
    local.subnet_keys[count.index % length(local.subnet_keys)]
  ].id

  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-SCRIPT
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>ACS730 Assignment 1 - ${var.environment}</h1>" > /usr/share/nginx/html/index.html
  SCRIPT

  tags = merge(local.common_tags, {
    Name = "${local.name}-web-${count.index + 1}"
  })

  depends_on = [aws_route_table_association.public]
}

resource "aws_s3_bucket" "artifacts" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = "${local.name}-artifacts"

  tags = merge(local.common_tags, {
    Name = "${local.name}-artifacts"
  })
}

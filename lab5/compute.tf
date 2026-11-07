
data "aws_ami" "al2023" {
  count       = var.use_localstack ? 0 : 1
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
  ami_id           = var.use_localstack ? var.localstack_ami_id : data.aws_ami.al2023[0].id
  first_subnet_key = sort(keys(aws_subnet.public))[0]
}

resource "aws_instance" "web" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[local.first_subnet_key].id
  vpc_security_group_ids = [aws_security_group.web.id]

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = merge(local.common_tags, { Name = "${local.name}-web" })

  depends_on = [aws_route_table_association.public]
}

resource "aws_s3_bucket" "artifacts" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = "${local.name}-artifacts"

  tags = merge(local.common_tags, { Name = "${local.name}-artifacts" })
}

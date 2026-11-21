packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "amazon-ebs" "webserver" {
  region        = "us-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"

  subnet_id     = "subnet-06672e496a39aec66"
  ssh_interface = "private_ip"

  temporary_security_group_source_cidrs = [
    "172.31.3.18/32"
  ]

  ami_name = "acs730-lab6-golden-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }

    owners      = ["amazon"]
    most_recent = true
  }

  tags = {
    Course = "ACS730"
    Lab    = "lab6"
    Role   = "golden-webserver"
  }
}

build {
  sources = ["source.amazon-ebs.webserver"]

  provisioner "ansible" {
    playbook_file = "${path.root}/packer-playbook.yml"
    user          = "ec2-user"

    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=${path.root}/../ansible/roles"


    ]
  }
}

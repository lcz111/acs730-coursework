terraform {
  required_version = "= 1.10.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "acs730-tfstate-195356629135"
    key          = "lab3/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ssm_parameter" "lab3_demo" {
  name  = "/acs730/lab3/demo"
  type  = "String"
  value = "Created from workstation"

  tags = {
    Project = "ACS730-Lab3"
    Managed = "Terraform"
  }
}

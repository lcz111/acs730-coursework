module "web" {
  source = "../modules/web-infrastructure"

  project     = "acs730-a1"
  owner       = "chengzeli"
  environment = "staging"

  vpc_cidr = "10.43.0.0/16"

  public_subnets = {
    a = {
      cidr_block = "10.43.1.0/24"
      az_index   = 0
    }
    b = {
      cidr_block = "10.43.2.0/24"
      az_index   = 1
    }
  }

  instance_type        = "t3.micro"
  instance_count       = 1
  iam_instance_profile = "LabInstanceProfile"

  ingress_rules = [
    {
      description = "HTTP from anywhere"
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  create_artifact_bucket = false
}

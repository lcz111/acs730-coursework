terraform {
  backend "s3" {
    bucket       = "acs730-tfstate-195356629135"
    key          = "assignment1/staging/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

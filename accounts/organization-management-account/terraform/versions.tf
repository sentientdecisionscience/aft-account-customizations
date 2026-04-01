terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34.0"
    }
  }
}


terraform {
  required_version = ">= 1.11.0"
  backend "s3" {
    region       = "us-east-1"
    bucket       = "aft-backend-308471216192-primary-region"
    key          = "704601633428-aft-account-customizations/terraform.tfstate"
    use_lockfile = "true"
    encrypt      = "true"
    kms_key_id   = "40bb3195-226b-465b-90d6-569e00c2210b"
    assume_role = {
      role_arn = "arn:aws:iam::308471216192:role/AWSAFTExecution"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::704601633428:role/AWSAFTExecution"
  }

  default_tags {
    tags = {
      managed_by = "AFT"
    }
  }
}

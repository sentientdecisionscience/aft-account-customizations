provider "aws" {
  region = "us-east-2"

  assume_role {
    role_arn     = "arn:aws:iam::123456789123:role/terraform-administrator"
    session_name = "tf-use2"
  }

  default_tags {
    tags = {
      Owner              = "Caylent"
      ManagedByTerraform = "True"
    }
  }
}

provider "aws" {
  alias  = "aws-use1"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::123456789123:role/terraform-administrator"
    session_name = "tf-use1"
  }

  default_tags {
    tags = {
      Owner              = "Caylent"
      ManagedByTerraform = "True"
    }
  }
}

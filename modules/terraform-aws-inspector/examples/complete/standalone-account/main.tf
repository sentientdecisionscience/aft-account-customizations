#################################################################################################
# Inspector Standalone Account Configuration
#################################################################################################
module "inspector" {
  source = "../../../"

  enable_organization_configuration = false

  resource_scan_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
}

module "inspector_use1" {
  source = "../../../"

  providers = {
    aws = aws.aws-use1
  }

  enable_organization_configuration = false

  resource_scan_types = ["EC2", "ECR"]
}

module "conformance_packs_and_rules" {
  source = "../../modules/conformance-packs-and-rules"

  delivery_bucket_name = module.config.s3_delivery_bucket_name

  conformance_packs = [
    {
      #Conformance pack from a local file
      name     = "conformance-pack-template-local"
      template = file("${path.module}/conformance-pack-templates/conformance-pack-template-local.yaml")
    },
    {
      #Conformance pack with custom template
      name            = "conformance-pack-custom-template"
      deployment_mode = "LOCAL"
      template        = file("${path.module}/conformance-pack-templates/conformance-pack-custom-template.yaml")
      input_parameters = {
        "AccessKeysRotatedParameterMaxAccessKeyAge" = "90"
      }
    },
    {
      #Conformance pack from a URL
      name              = "conformance-pack-template-url"
      deployment_mode   = "ORGANIZATION"
      excluded_accounts = ["690032609951"]
      template_url      = "https://raw.githubusercontent.com/awslabs/aws-config-rules/refs/heads/master/aws-config-conformance-packs/Operational-Best-Practices-for-AWS-Identity-and-Access-Management.yaml"
      input_parameters = {
        "IamPasswordPolicyParamMaxPasswordAge"        = "90",
        "IamPasswordPolicyParamMinimumPasswordLength" = "14",
      }
    },
    {
      #Conformance pack from an S3 URI
      name            = "conformance-pack-template-s3-uri"
      template_s3_uri = "s3://${aws_s3_bucket.example.bucket}/${aws_s3_object.example.key}"
    }
  ]

  config_rules = [
    {
      #Config rule with AWS Managed source
      name            = "s3-bucket-versioning-enabled"
      description     = "Checks whether the versioning is enabled for the S3 buckets"
      deployment_mode = "ORGANIZATION"

      evaluation_mode      = "DETECTIVE"
      include_mgmt_account = false
      excluded_accounts    = ["690032609951"]
      source = {
        #List of AWS Managed Config Rules: https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html
        owner             = "AWS"
        source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
      }
      scope = {
        compliance_resource_types = ["AWS::S3::Bucket"]
      }
    },
    {
      #Config rule with custom policy detail
      name            = "rule-with-custom-policy-detail"
      description     = "Rule with custom policy detail"
      deployment_mode = "LOCAL"

      source = {
        owner = "CUSTOM_POLICY"
        source_detail = {
          message_type = "ConfigurationItemChangeNotification"
        }
        custom_policy_details = {
          policy_runtime = "guard-2.x.x"
          policy_text    = <<EOF
        rule tableisactive when
            resourceType == "AWS::DynamoDB::Table" {
            configuration.tableStatus == ['ACTIVE']
        }

        rule checkcompliance when
            resourceType == "AWS::DynamoDB::Table"
            tableisactive {
                supplementaryConfiguration.ContinuousBackupsDescription.pointInTimeRecoveryDescription.pointInTimeRecoveryStatus == "ENABLED"
        }
        EOF
        }
      }
    }
  ]
}

############################################
##          Supporting Resources         ##
###########################################
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket-${random_string.bucket_suffix.result}"
}

resource "aws_s3_object" "example" {
  bucket  = aws_s3_bucket.example.id
  key     = "example-conformance-pack"
  content = file("${path.module}/conformance-pack-templates/example-conformance-pack.yaml")
}

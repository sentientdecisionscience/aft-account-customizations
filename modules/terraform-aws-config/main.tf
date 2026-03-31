# ---------------------------------------------------------------------------------------------
# AWS Config
# ---------------------------------------------------------------------------------------------

resource "random_string" "config_suffix" {
  length  = 8
  special = false
  upper   = false
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status
resource "aws_config_configuration_recorder_status" "config_recorder_status" {
  name       = aws_config_configuration_recorder.config_recorder.name
  is_enabled = var.enable_recorder
  depends_on = [aws_config_delivery_channel.delivery_channel]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "delivery_bucket" {
  count         = var.create_delivery_bucket ? 1 : 0
  bucket        = "awsconfigconforms-delivery-bucket-${random_string.config_suffix.result}"
  force_destroy = false
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "delivery_bucket_versioning" {
  bucket = aws_s3_bucket.delivery_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel
resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "awsconfig-delivery-bucket-${random_string.config_suffix.result}"
  s3_bucket_name = var.create_delivery_bucket ? aws_s3_bucket.delivery_bucket[0].bucket : var.delivery_bucket_name
  s3_key_prefix  = var.delivery_bucket_prefix
  s3_kms_key_arn = var.delivery_bucket_kms_key_arn
  sns_topic_arn  = var.delivery_sns_topic_arn
  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency
  }

  depends_on = [aws_s3_bucket.delivery_bucket, aws_config_configuration_recorder.config_recorder]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "awsconfig-recorder-${random_string.config_suffix.result}"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = length(var.recording_group.resource_types) == 0 && length(var.recording_group.excluded_resource_types) == 0 ? true : false
    include_global_resource_types = length(var.recording_group.resource_types) == 0 && length(var.recording_group.excluded_resource_types) == 0 ? var.recording_group.include_global_resource_types : false
    #List of available resource types: https://docs.aws.amazon.com/config/latest/APIReference/API_ResourceIdentifier.html#config-Type-ResourceIdentifier-resourceType
    dynamic "exclusion_by_resource_types" {
      for_each = length(var.recording_group.excluded_resource_types) != 0 ? [1] : []
      content {
        resource_types = var.recording_group.excluded_resource_types
      }
    }
    resource_types = var.recording_group.resource_types

    #List of recording strategies: https://docs.aws.amazon.com/config/latest/APIReference/API_RecordingStrategy.html
    dynamic "recording_strategy" {
      for_each = length(var.recording_group.resource_types) == 0 && length(var.recording_group.excluded_resource_types) == 0 ? ["ALL_SUPPORTED_RESOURCE_TYPES"] : length(var.recording_group.resource_types) == 0 && length(var.recording_group.excluded_resource_types) != 0 ? ["EXCLUSION_BY_RESOURCE_TYPES"] : length(var.recording_group.resource_types) != 0 && length(var.recording_group.excluded_resource_types) == 0 ? ["INCLUSION_BY_RESOURCE_TYPES"] : []
      content {
        use_only = recording_strategy.value
      }
    }
  }

  dynamic "recording_mode" {
    for_each = var.recording_mode.recording_frequency != null ? [1] : []
    content {
      recording_frequency = var.recording_mode.recording_frequency
      dynamic "recording_mode_override" {
        for_each = var.recording_mode.recording_mode_override
        content {
          description         = recording_mode_override.value.description
          resource_types      = recording_mode_override.value.resource_types
          recording_frequency = recording_mode_override.value.recording_frequency
        }
      }
    }
  }
}

resource "aws_config_configuration_aggregator" "aggregator" {
  count = var.aggregator.enabled ? 1 : 0
  name  = "aws-config-aggregator-${random_string.config_suffix.result}"

  dynamic "account_aggregation_source" {
    for_each = var.aggregator["aggregation_mode"] == "SPECIFIC_ACCOUNTS" ? [1] : []
    content {
      account_ids = var.aggregator.member_account_ids
      all_regions = var.aggregator["all_regions"]
      regions     = var.aggregator["all_regions"] ? null : var.aggregator["scope_regions"]
    }
  }

  dynamic "organization_aggregation_source" {
    for_each = var.aggregator["aggregation_mode"] == "ORGANIZATION" ? [1] : []
    content {
      role_arn    = aws_iam_role.config_role.arn
      all_regions = var.aggregator["all_regions"]
      regions     = var.aggregator["all_regions"] ? null : var.aggregator["scope_regions"]
    }
  }
}


##############################
##      IAM Resources      ##
#############################

locals {
  s3_bucket_policy_resources = var.create_delivery_bucket ? ["${aws_s3_bucket.delivery_bucket[0].arn}", "${aws_s3_bucket.delivery_bucket[0].arn}/*"] : ["arn:aws:s3:::${var.delivery_bucket_name}", "arn:aws:s3:::${var.delivery_bucket_name}/*"]
}

data "aws_iam_policy_document" "config_policies" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket", "s3:PutObject"]
    resources = local.s3_bucket_policy_resources
  }
  dynamic "statement" {
    for_each = var.delivery_sns_topic_arn != null ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = [var.delivery_sns_topic_arn]
    }
  }
}

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
resource "aws_iam_role_policy" "delivery_bucket_policy" {
  name   = "awsconfig_policies-${random_string.config_suffix.result}"
  role   = aws_iam_role.config_role.name
  policy = data.aws_iam_policy_document.config_policies.json
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "config_role" {
  name               = "awsconfig-role-${random_string.config_suffix.result}"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "organization_aggregation_policy" {
  count      = var.aggregator.enabled ? 1 : 0
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "config_role_additional_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.config_role.name
  policy_arn = each.value
}

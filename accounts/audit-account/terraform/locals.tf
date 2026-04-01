#################################################### IMPORTANT #####################################################
# Utilize this locals block to track all Organization Account IDs and OU IDs.
#
# This allows us to reference all accounts & OUs in an easily identifiable and consistent manner throughout TF.
######################################################################################################################

locals {

  account_map = {
    "organization_management" = "704601633428"
    "log_archive"             = "931409206927"
    "audit"                   = "587402079603"
    "aft_management"          = "308471216192"
    "shared_services"         = "172201861437"
    "sandbox"                 = "513750743324"
    "networking"              = "627917840657"
    "development"             = "530310462919"
    "production"              = "739272173599"
  }

  ou_map = {
    "root"           = data.aws_organizations_organization.current.roots[0].id
    "security"       = "ou-v919-afmjp2rj"
    "suspended"      = "ou-v919-3gsfdalr"
    "aft"            = "ou-v919-hprwkjd6"
    "sandbox"        = "ou-v919-u3zg7y39"
    "workloads"      = "ou-v919-xyg1342j"
    "infrastructure" = "ou-v919-1abjeb6l"
  }

  partition = data.aws_partition.current.partition
  region    = data.aws_region.current.region

  security_standards = {
    "aws-foundational-security-best-practices" = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/aws-foundational-security-best-practices/v/1.0.0")
    "cis-aws-foundations-benchmark-v1.2.0"     = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "ruleset/cis-aws-foundations-benchmark/v/1.2.0")
    "cis-aws-foundations-benchmark-v1.4.0"     = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/cis-aws-foundations-benchmark/v/1.4.0")
    "cis-aws-foundations-benchmark-v3.0.0"     = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/cis-aws-foundations-benchmark/v/3.0.0")
    "nist-800-171-rev2"                        = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/nist-800-171/v/2.0.0")
    "nist-800-53-rev5"                         = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/nist-800-53/v/5.0.0")
    "pci-dss-v3.2.1"                           = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/pci-dss/v/3.2.1")
    "pci-dss-v4.0.1"                           = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/pci-dss/v/4.0.1")
  }

}

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
  }

  ou_map = {
    "root"      = data.aws_organizations_organization.current.roots[0].id
    "security"  = "ou-v919-afmjp2rj"
    "suspended" = "ou-v919-3gsfdalr"
    "aft"       = "ou-v919-hprwkjd6"
    "sandbox"   = "ou-v919-u3zg7y39"
    "workloads" = "ou-v919-xyg1342j"
  }

}

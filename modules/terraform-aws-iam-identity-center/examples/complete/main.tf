locals {
  # Account IDs
  account1_account_id = "014498644125" #Networking
  # account2_account_id = "222222222222"
  # account3_account_id = "333333333333"
  # account4_account_id = "444444444444"
}

locals {
  sso_groups = {
    Admin : {
      group_name        = "Admin"
      group_description = "Admin Group"
    },
    Billing : {
      group_name        = "Billing"
      group_description = "Billing Group"
    },
  }

  existing_sso_users = {
    "jeronimo.orlando" : {
      user_name        = "jeronimo.orlando@caylent.com"
      group_membership = ["Admin"]
    }
    "nicolas.diaz" : {
      user_name        = "nicolas.diaz@caylent.com"
      group_membership = ["Billing"]
    }
  }

  account_assignments = {
    Admin : {
      principal_name = "Admin"
      principal_type = "GROUP"
      principal_idp  = "INTERNAL"
      permission_sets = [
        "AdministratorAccess",
        "Billing"
      ]
      account_ids = [local.account1_account_id]
    },
    Billing : {
      principal_name = "Billing"
      principal_type = "GROUP"
      principal_idp  = "INTERNAL"
      permission_sets = [
        "Billing",
      ]
      account_ids = [local.account1_account_id]
    }
  }

  permission_sets = {
    AdministratorAccess = {
      description   = "AdministratorAccess"
      tags          = { ManagedBy = "Terraform" }
      inline_policy = data.aws_iam_policy_document.EC2Access.json,
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/IAMFullAccess",
        "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
      ]
      customer_managed_policies = []
      permission_boundary       = []
    },
    Billing = {
      description   = "Billing"
      tags          = { ManagedBy = "Terraform" }
      inline_policy = data.aws_iam_policy_document.S3Access.json
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
      ]
      customer_managed_policies = []
      permission_boundary       = []
    }
  }
}

module "aws-iam-identity-center" {
  source = "../.."

  sso_groups          = local.sso_groups
  permission_sets     = local.permission_sets
  account_assignments = local.account_assignments
}

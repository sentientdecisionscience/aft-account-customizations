locals {
  # Map of OUs to be used for target so users
  # don't have to remember or look up the OU IDs
  ou_map = {
    "test_ou1"   = "ou-qyyj-yjcjcdoj" # test_ou1
    "test_ou2"   = "ou-qyyj-r5eaoka2" # test_ou2
    "test_ou3"   = "ou-qyyj-w0yw6krm" # test_ou3
    "test_ou4"   = "ou-qyyj-cuxntp0t" # test_ou4
    "Level_2_ou" = "ou-qyyj-ads8zuff" # nested_ou_test1
    "Level_3_ou" = "ou-qyyj-rwmwd8n3" # nested_ou_level3
  }

  unrestricted_ous = [
    local.ou_map["test_ou4"]
  ]

  # Root OU
  org_root_ou = data.aws_organizations_organization.org.roots[0].id

  # All the direct, Level 1 children OUs under Root, not including OUs defined in local.unrestricted_ous
  org_root_ou_filtered = setsubtract([
    for ou in data.aws_organizations_organizational_units.main.children : ou.id
  ], local.unrestricted_ous)
}

module "controls" {
  source = "../../"

  map_ous_controls = {
    ########################################################################################################
    # Apply all strongly recommended controls to Sandbox OU                                                #
    # https://docs.aws.amazon.com/controltower/latest/controlreference/strongly-recommended-controls.html  #
    ########################################################################################################
    "sandbox_ou_controls" = {
      ou_ids                        = [local.ou_map["test_ou3"]]
      strongly_recommended_controls = true
    }
    ###########################################################################################################################
    # Apply all strongly recommended controls, elective controls, data residency controls and additional controls to lvl3_ou  #
    # https://docs.aws.amazon.com/controltower/latest/controlreference/strongly-recommended-controls.html                     #
    ###########################################################################################################################
    "Level_2_ou" = {
      ou_ids                        = [local.ou_map["Level_2_ou"]]
      strongly_recommended_controls = true
      elective_controls             = true
      data_residency_controls       = true
      individual_controls = [
        "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED"
      ]
    }

    ########################################################################################################
    # Apply elective controls, data residency controls and additional controls to lvl2_ou                  #
    # https://docs.aws.amazon.com/controltower/latest/controlreference/strongly-recommended-controls.html  #
    ########################################################################################################
    "Level_3_ou" = {
      ou_ids                  = [local.ou_map["Level_3_ou"]]
      elective_controls       = true
      data_residency_controls = true
      individual_controls = [
        "6rilu41n0gb9w6mxrkyewoer4",
        "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED"
      ]
    }
  }
}

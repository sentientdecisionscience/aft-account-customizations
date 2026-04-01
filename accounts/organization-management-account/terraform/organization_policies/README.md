# Table of Contents

- [Table of Contents](#table-of-contents)
- [General information](#general-information)
- [Service Control Policies (SCPs)](#service-control-policies-scps)
  - [DenyCreatingIAMUsers](#denycreatingiamusers)
  - [PreventsUsersFromDeletingAccessAnalyzer](#preventsusersfromdeletingaccessanalyzer)
  - [DenyDeletingCloudWatchLogs](#denydeletingcloudwatchlogs)
  - [DenyDeletingKMSKeys](#denydeletingkmskeys)
  - [DenyDeletingRoute53Zones](#denydeletingroute53zones)
  - [PreventsUserFromEditingCloudTrail](#preventsuserfromeditingcloudtrail)
  - [PreventsUsersFromEditingConfig](#preventsusersfromeditingconfig)
  - [DenyLeavingOrganizations](#denyleavingorganizations)
  - [PreventsExternalRAMshares](#preventsexternalramshares)
  - [DenyDisablingEBSEncryptionByDefault](#denydisablingebsencryptionbydefault)
  - [DenyRootAccountUsage](#denyrootaccountusage)
  - [DenyS3BucketsPublicAccess](#denys3bucketspublicaccess)
  - [DenyUnsupportedRegions](#denyunsupportedregions)


# General information

> [!TIP]
> Some policies may not include key arguments more than official documentations, but they are still present for completeness. In these cases, the reasoning remains the same: we are denying `deletion|update|creation|...` actions because the service or feature supports a critical security or compliance objective that you very likely want to be kept, preventing accidental or malicious modifications.

# Service Control Policies (SCPs)

Consider the following:

1. To see examples of SCPs that can be implemented, take a look at [AWS' Example SCPs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html) and also at the [Service Authorization Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/) to see all the actions and conditions you can define within them.
2. A certain Account, Role, or Service often needs to be an exception for an SCP. For that, we use Policy `Conditions`. E.g.:

```json
// Adds Control Tower's Execution role as an exception
"ArnNotLike": {
    "aws:PrincipalARN": "arn:aws:iam::*:role/AWSControlTowerExecution*"
}
```

For more governance-related `Condition`s such as [PrincipalAccount](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-principalaccount) and [RequestedRegion](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-requestedregion) take a look at [Global condition keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html). Another great source is AWS' post on how [IAM makes it easier for you to manage permissions for AWS services accessing your resources](https://aws.amazon.com/blogs/security/iam-makes-it-easier-to-manage-permissions-for-aws-services-accessing-resources/).

3. In some environments, you might have short-lived resources and/or managed by automation, such as networking resources within a VPC or EC2. Adding SCPs that restrict API calls to those services can disrupt those automation processes if they are not properly handled in `Condition` keys as stated in `(2)` or applied to the appropriate `Resource`s or OU/account targets.

> [!IMPORTANT]
> Service Control Policies do not have an effect on the management account, even if you define the `Root` OU as a target. This behavior is intentional. See AWS' [Service control policies (SCPs)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) for more.

## DenyCreatingIAMUsers

> [deny_creating_iam_users.json](./service_control_policies/json_policies/deny_creating_iam_users.json)

- [IAM Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- In a scenario where human access to AWS is granted through IAM Identity Center (SSO), this SCP will make sure that SSO is the only access method and no new IAM Users are created;
- A condition can be created for Cloud Administrators if any third party tool needs to assume role through automation processes. However, [OpenID Connect (OIDC) identity provider in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) is preferred if available

## PreventsUsersFromDeletingAccessAnalyzer

> [deny_deleting_access_analyzer.json](./service_control_policies/json_policies/deny_deleting_access_analyzer.json)

- [Identity and Access Management Access Analyzer Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)


## DenyDeletingCloudWatchLogs

> [deny_deleting_cloudwatch_logs.json](./service_control_policies/json_policies/deny_deleting_cloudwatch_logs.json)

- [IAM Management for CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/auth-and-access-control-cwl.html) 
- This is particularly important for data retention policies and compliance requirements


## DenyDeletingKMSKeys

> [deny_deleting_kms_keys.json](./service_control_policies/json_policies/deny_deleting_kms_keys.json)

- [KMS Security Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/kms-security.html) and [Deleting Keys](https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html)
- Any data encrypted with KMS keys is permanently lost after the scheduled deletion of the key occurs
- If any automation or application infrastructure requires dynamic creation of KMS keys, include the automation tool assume IAM Role as an exception in the `Condition`, and if possible, use standardized prefix/suffix to make sure the `Resource` block can also be defined

## DenyDeletingRoute53Zones

> [deny_deleting_route53_zones.json](./service_control_policies/json_policies/deny_deleting_route53_zones.json)

- [Route53 Security Best Practices](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/security.html)

## PreventsUserFromEditingCloudTrail

> [deny_disabling_cloudtrail.json](./service_control_policies/json_policies/deny_disabling_cloudtrail.json)

- [CloudTrail Security Best Practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Security.html)
- Cloudtrail is one of AWS's main auditing services, and many third-party services and SIEM platforms rely on Cloudtrail's delivery S3 bucket

## PreventsUsersFromEditingConfig

> [deny_disabling_config.json](./service_control_policies/json_policies/deny_disabling_config.json)

- [Config Official Docs](https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html)
- Config is responsible for tracking resource misconfiguration and is the [underlying service behind other AWS services](https://docs.aws.amazon.com/config/latest/developerguide/service-integrations.html) such as Security Hub and Control Tower
- Accidentally stopping or deleting Config can put Organizations in a non-compliant status and disrupt several downstream services

## DenyLeavingOrganizations

> [deny_leaving_organization.json](./service_control_policies/json_policies/deny_leaving_organization.json)

- [Official Docs](https://docs.aws.amazon.com/organizations/latest/APIReference/API_LeaveOrganization.html)
- By removing the ability of member accounts to leave the Organization, we guarantee that accounts can only be **removed** from the organization through the management account.
- If an account leaves, it could result in unexpected [billing changes](https://docs.aws.amazon.com/organizations/latest/userguide/pricing.html) or loss of negotiated discounts. Also, this account will no longer be subject to Service Control Policies (SCPs), security controls, and cost management policies enforced at the organization level.

## PreventsExternalRAMshares

> [prevent_external_ram_shares.json](./service_control_policies/json_policies/prevent_external_ram_shares.json)

- [RAM Official Docs](https://docs.aws.amazon.com/ram/latest/userguide/getting-started-sharing.html)
- Resource sharing with AWS accounts outside the organization is explicitly denied, even if the user has permissions to create or update shares. This does **not** block all resource sharing — only sharing with external AWS accounts. If you need more specific type of shares, you can check for [other examples](https://docs.aws.amazon.com/ram/latest/userguide/scp.html). 
- A user with these permissions could share critical/sensitive AWS resources with external accounts, leading to potential security breaches. 
- Organizations with strict data residency or compliance policies (e.g., GDPR, HIPAA) must control who can share resources, as external access may violate regulations.

## DenyDisablingEBSEncryptionByDefault

> [deny_disabling_ebs_encryption_by_default.json.tpl](./service_control_policies/template_policies/deny_disabling_ebs_encryption_by_default.json.tpl)

- [EBS Encryption Official Docs](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-encryption.html)
- Without automatic encryption, data stored on EBS volumes may remain in plaintext, increasing the risk of unauthorized access in case of a security breach.
- Many industry regulations and compliance frameworks mandate encryption of data at rest. Disabling default encryption could lead to non-compliance resources.

## DenyRootAccountUsage

> [deny_root_account_usage.json.tpl](./service_control_policies/template_policies/deny_root_account_usage.json.tpl)

- [Root User Official Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html)
- The root user operates outside IAM roles and permissions, making it impossible to track actions via IAM. Also, regular IAM User and Roles provide detailed logging and auditing via AWS CloudTrail, but root user actions do not follow the same governance [best practices](https://repost.aws/knowledge-center/security-best-practices).
- If the root account credentials are leaked or compromised, an attacker would have full, unrestricted control over the entire AWS environment, leading to irreversible damages, such as deleting all resources, changing billing settings, and removing IAM Users/Roles/Policies, making recovery nearly impossible. 

## DenyS3BucketsPublicAccess

> [deny_s3_buckets_public_access.json.tpl](./service_control_policies/template_policies/deny_s3_buckets_public_access.json.tpl)

- [S3 Public Access Official Docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- Unauthorized modifications might disable existing `PublicAccessBlock` settings, inadvertently allowing public access to sensitive data stored in S3 buckets. This exposure could lead to data breaches and unauthorized data retrieval.
- See [Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html) for more information

## DenyUnsupportedRegions

> [deny_unsupported_regions.json.tpl](./service_control_policies/template_policies/deny_unsupported_regions.json.tpl)

- [Enabling Regions Official Docs](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-regions.html)
- This SCP prevents deploying resources in unauthorized or non-compliant regions, reducing security risks like data breaches, misconfigurations, unauthorized access and ensuring compliance with regulations like GDPR, HIPAA, etc.
- Prevents accidental or malicious provisioning of resources in unmonitored regions, avoiding unexpected billing spikes.
- This SCP works with `NotActions` and `StringNotEquals`, meaning that the Regions included in `allowed_regions` will be able to perform all actions (if no further rectrictions are in place), but Regions not included in mentioned variable, will only be able to perform the actions under the `NotAction` list. [Docs here](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples_general.html#example-scp-deny-region).


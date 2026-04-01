{
  "Sid": "DenyDisablingEBSEncryptionByDefault",
  "Effect": "Deny",
  "Action": ["ec2:DisableEbsEncryptionByDefault"],
  "Resource": "*",
  "Condition": {
    "ArnNotLike": {
      "aws:PrincipalArn": "arn:${partition}:iam::*:role/AWSAFTExecution"
    }
  }
}

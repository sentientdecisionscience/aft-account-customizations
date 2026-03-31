{
  "Sid": "DenyRootAccountUsage",
  "Effect": "Deny",
  "Action": ["*"],
  "Resource": "*",
  "Condition": {
    "StringLike": {
      "aws:PrincipalArn": "arn:${partition}:iam::*:root"
    }
  }
}

{
  "Sid": "DenyS3BucketsPublicAccess",
  "Effect": "Deny",
  "Action": ["s3:PutAccountPublicAccessBlock"],
  "Resource": "*",
  "Condition": {
    "ArnNotLike": {
      "aws:PrincipalArn": "arn:${partition}:iam::*:role/AWSAFTExecution"
    }
  }
}

{
    "Sid": "RCPEnforceConfusedDeputyProtection",
    "Effect": "Deny",
    "Principal": "*",
    "Action": [
        "s3:*",
        "sqs:*",
        "secretsmanager:*"
    ],
    "Resource": "*",
    "Condition": {
        "StringNotEqualsIfExists": {
            "aws:SourceOrgID": "${organization_id}"
        },
        "Bool": {
            "aws:PrincipalIsAWSService": "true"
        },
        "Null": {
            "aws:SourceAccount": "false"
        }
    }
}

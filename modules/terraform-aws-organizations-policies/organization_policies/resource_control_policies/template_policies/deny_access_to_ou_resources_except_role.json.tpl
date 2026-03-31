{
    "Sid": "DenyExternalOuAccessExceptRole",
    "Effect": "Deny",
    "Principal": "*",
    "Action": [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:AssumeRole",
        "sts:DecodeAuthorizationMessage",
        "sts:GetAccessKeyInfo",
        "sts:GetFederationToken",
        "sts:GetServiceBearerToken",
        "sts:GetSessionToken",
        "sts:SetContext"
    ],
    "Resource": "*",
    "Condition": {
        "BoolIfExists": {
            "aws:PrincipalIsAWSService": "false"
        },
        "ArnNotLikeIfExists": {
            "aws:PrincipalARN":"arn:aws:iam::${account_id}:role/${role_name}"
        }
    }
}

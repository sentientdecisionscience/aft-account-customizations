{
    "Sid": "STSEnforceOrgIdentities",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "sts:AssumeRole",
    "Resource": "*",
    "Condition": {
        "StringNotEqualsIfExists": {
            "aws:PrincipalOrgID": "${org_id}",
            "aws:PrincipalAccount": [
                "{trusted_account_id}",
            ]
        },
        "BoolIfExists": {
            "aws:PrincipalIsAWSService": "false"
        }
    }
}

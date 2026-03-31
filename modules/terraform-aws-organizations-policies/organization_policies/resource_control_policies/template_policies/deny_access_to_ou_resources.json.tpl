{
    "Sid": "DenyExternalOuAccess",
    "Effect":"Deny",
    "Principal":"*",
    "Action":[
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*"
    ],
    "Resource":"*",
    "Condition":{
        "ForAllValues:StringLikeIfExists": {
            "aws:ResourceOrgPaths":"${org_id}/${root_id}/${ou_id}/*"
        },
        "ForAllValues:StringNotLikeIfExists": {
            "aws:PrincipalOrgPaths":"${org_id}/${root_id}/${ou_id}/*"
        },
        "BoolIfExists":{
            "aws:PrincipalIsAWSService":"false"
        }
    }
 }

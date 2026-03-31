{
    "Sid": "DenyKMSKeyDeletion",
    "Effect":"Deny",
    "Principal":"*",
    "Action":[
       "kms:ScheduleKeyDeletion",
       "kms:DeleteAlias",
       "kms:DeleteCustomKeyStore",
       "kms:DeleteImportedKeyMaterial"
    ],
    "Resource":"*",
    "Condition":{
       "ArnNotLike":{
          "aws:PrincipalArn":"arn:aws:iam::${account_id}:role/${role_name}"
       }
    }
}

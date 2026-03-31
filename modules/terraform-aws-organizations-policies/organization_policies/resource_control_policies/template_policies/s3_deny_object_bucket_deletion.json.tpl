{
    "Sid": "DenyS3ObjectBucketDeletion",
    "Effect":"Deny",
    "Principal":"*",
    "Action":[
       "s3:DeleteBucket",
       "s3:DeleteBucketPolicy",
       "s3:DeleteObject",
       "s3:DeleteObjectVersion",
       "s3:DeleteObjectTagging",
       "s3:DeleteObjectVersionTagging"
    ],
    "Resource":[
       "arn:aws:s3:::${bucket_name}",
       "arn:aws:s3:::${bucket_name}/*"
    ]
}

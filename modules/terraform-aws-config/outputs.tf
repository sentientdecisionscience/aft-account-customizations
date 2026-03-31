output "s3_delivery_bucket_name" {
  description = "The name of the S3 bucket used to store the configuration history."
  value       = var.create_delivery_bucket ? aws_s3_bucket.delivery_bucket[0].bucket : var.delivery_bucket_name

}

resource "aws_s3_bucket" "s3" {
  acceleration_status = "Enabled"
  request_payer       = "BucketOwner"
  force_destroy       = true
  acl                 = "private"
  bucket_prefix       = var.environment_name

  tags = {
    Environment = var.environment_name
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_block" {
  bucket                  = aws_s3_bucket.s3.id
  block_public_policy     = true
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
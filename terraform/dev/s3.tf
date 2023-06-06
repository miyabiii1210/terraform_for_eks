# TODO: A bucket to manage tfstat must be created separately on the AWS Management Console

resource "aws_s3_bucket" "dev" {
  bucket = "${local.sig}-front"
  tags   = local.default_tags
}

resource "aws_s3_bucket_versioning" "dev-versioning" {
  bucket = aws_s3_bucket.dev.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dev-encryption" {
  bucket = aws_s3_bucket.dev.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
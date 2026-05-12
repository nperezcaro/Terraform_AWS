locals {
  name = "${var.project}-${var.env}"
  tags = merge(
    {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

data "aws_caller_identity" "current" {}

# Account ID suffix avoids global name collisions without random suffixes.
resource "aws_s3_bucket" "this" {
  bucket        = "${local.name}-${var.bucket_suffix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy
  tags          = merge(local.tags, { Name = "${local.name}-${var.bucket_suffix}" })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count      = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket     = aws_s3_bucket.this.id
  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {}

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content { days = rule.value.expiration_days }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [1] : []
        content { noncurrent_days = rule.value.noncurrent_version_expiration }
      }

      dynamic "transition" {
        for_each = rule.value.transition_days != null ? [1] : []
        content {
          days          = rule.value.transition_days
          storage_class = rule.value.transition_storage_class
        }
      }
    }
  }
}

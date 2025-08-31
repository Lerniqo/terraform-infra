# S3 Bucket Module
# Creates S3 buckets with standard configurations

resource "aws_s3_bucket" "main" {
  for_each = toset(var.bucket_names)

  bucket = each.value != "" ? each.value : "${var.project_name}-${var.environment}-${var.bucket_suffix}"

  tags = merge(
    {
      Name        = each.value != "" ? each.value : "${var.project_name}-${var.environment}-${var.bucket_suffix}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  for_each = var.enable_versioning ? aws_s3_bucket.main : {}

  bucket = aws_s3_bucket.main[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = var.enable_encryption ? aws_s3_bucket.main : {}

  bucket = aws_s3_bucket.main[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.encryption_algorithm
    }
    bucket_key_enabled = var.enable_bucket_key
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  for_each = var.block_public_access ? aws_s3_bucket.main : {}

  bucket = aws_s3_bucket.main[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy (optional)
resource "aws_s3_bucket_policy" "main" {
  for_each = var.bucket_policy != "" ? aws_s3_bucket.main : {}

  bucket = aws_s3_bucket.main[each.key].id
  policy = var.bucket_policy
}

# S3 Bucket Lifecycle Configuration (optional)
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = length(var.lifecycle_rules) > 0 ? aws_s3_bucket.main : {}

  bucket = aws_s3_bucket.main[each.key].id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
}

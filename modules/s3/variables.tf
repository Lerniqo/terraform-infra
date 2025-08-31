variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "bucket_names" {
  description = "List of bucket names to create. If empty, no buckets will be created"
  type        = list(string)
  default     = []
}

variable "bucket_suffix" {
  description = "Suffix for generated bucket name"
  type        = string
  default     = "bucket"
}

variable "additional_tags" {
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
}

variable "enable_bucket_key" {
  description = "Enable bucket key for SSE-KMS"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

variable "bucket_policy" {
  description = "JSON policy document for the bucket"
  type        = string
  default     = ""
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id                           = string
    enabled                      = bool
    prefix                       = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration = object({
      days = number
    })
    noncurrent_version_expiration = object({
      days = number
    })
  }))
  default = []
}

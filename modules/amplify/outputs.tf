# AWS Amplify Module Outputs

output "app_id" {
  description = "ID of the Amplify app"
  value       = aws_amplify_app.main.id
}

output "app_arn" {
  description = "ARN of the Amplify app"
  value       = aws_amplify_app.main.arn
}

output "default_domain" {
  description = "Default domain for the Amplify app"
  value       = aws_amplify_app.main.default_domain
}

output "app_url" {
  description = "URL of the deployed Amplify application"
  value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.main.id}.amplifyapp.com"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.domain_name != "" ? "https://${var.environment == "prod" ? "" : "${var.environment}."}${var.domain_name}" : ""
}

output "branch_name" {
  description = "Name of the main branch"
  value       = aws_amplify_branch.main.branch_name
}

output "webhook_url" {
  description = "Webhook URL for GitHub integration"
  value       = aws_amplify_webhook.main.url
  sensitive   = true
}

output "webhook_arn" {
  description = "ARN of the webhook"
  value       = aws_amplify_webhook.main.arn
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket for Amplify assets"
  value       = var.create_s3_bucket ? aws_s3_bucket.amplify_assets[0].id : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Amplify assets"
  value       = var.create_s3_bucket ? aws_s3_bucket.amplify_assets[0].arn : null
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Amplify assets"
  value       = var.create_s3_bucket ? aws_s3_bucket.amplify_assets[0].bucket : null
}

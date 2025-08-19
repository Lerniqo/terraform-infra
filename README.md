# Terraform Infrastructure for AWS App Runner

This project contains Terraform configurations for deploying applications using AWS App Runner, designed to work within AWS Free Tier limits.

## Project Structure

```
terraform-infra/
├── README.md                    # This file
├── providers.tf                 # AWS provider configuration
├── variables.tf                 # Root-level variables
├── main.tf                      # Root configuration
├── outputs.tf                   # Root-level outputs
├── modules/
│   └── apprunner/              # Reusable App Runner module
│       ├── main.tf             # Module resources
│       ├── variables.tf        # Module variables
│       └── outputs.tf          # Module outputs
└── environments/
    └── dev/                    # Development environment
        ├── main.tf             # Environment-specific configuration
        ├── variables.tf        # Environment variables
        ├── outputs.tf          # Environment outputs
        └── terraform.tfvars    # Variable values
```

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **GitHub repository** with your Node.js application
4. **AWS App Runner connection** to GitHub (see setup instructions below)

## AWS Free Tier Configuration

This setup is optimized for AWS Free Tier:
- **CPU**: 0.25 vCPU
- **Memory**: 0.5 GB
- **Build time**: Up to 20 minutes per month (included)
- **Compute time**: Up to 40 hours per month (included)

## Setup Instructions

### 1. Configure GitHub Connection

Before deploying, you need to create an App Runner connection to GitHub:

1. Go to AWS Console → App Runner → Manage connections
2. Create a new connection to GitHub
3. Authorize AWS to access your GitHub repositories
4. Note the Connection ARN for later use

### 2. Prepare Your Node.js Application

Ensure your Node.js app has:
- `package.json` with start script
- Health check endpoint (default: `/health`)
- Listens on port 3000 (or set PORT environment variable)

Example health check endpoint:
```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});
```

### 3. Configure Variables

1. Copy and modify the variables file:
```bash
cd environments/dev
cp terraform.tfvars terraform.tfvars.local
```

2. Edit `terraform.tfvars.local` with your values:
```hcl
github_repository_url = "https://github.com/yourusername/your-nodejs-app"
github_branch         = "main"
health_check_path     = "/health"
auto_deployments_enabled = true
```

### 4. Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="environments/dev/terraform.tfvars.local"

# Apply the configuration
terraform apply -var-file="environments/dev/terraform.tfvars.local"
```

## Adding More Applications

To add another App Runner service:

1. **Create a new environment** (e.g., `environments/staging/`) or
2. **Add another module call** in the existing environment:

```hcl
module "api_app" {
  source = "../../modules/apprunner"
  
  service_name   = "my-api-dev"
  repository_url = "https://github.com/yourusername/my-api"
  # ... other configuration
}
```

## Useful Commands

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var-file="environments/dev/terraform.tfvars.local"

# Apply changes
terraform apply -var-file="environments/dev/terraform.tfvars.local"

# Show current state
terraform show

# Destroy resources
terraform destroy -var-file="environments/dev/terraform.tfvars.local"

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

## Outputs

After successful deployment, you'll get:
- **App Runner Service URL**: Your application's public URL
- **Service ARN**: For reference in other AWS services
- **Service Status**: Current deployment status

## Troubleshooting

### Common Issues

1. **Connection ARN Error**: Make sure you've created the GitHub connection in AWS Console
2. **Build Failures**: Check that your `package.json` has the correct scripts
3. **Health Check Failures**: Ensure your app responds to the health check path
4. **Port Issues**: Make sure your app listens on the PORT environment variable

### Monitoring

- View logs in AWS Console → App Runner → Your Service → Logs
- Monitor costs in AWS Billing Dashboard
- Set up CloudWatch alarms for monitoring

## Security Best Practices

1. **Use environment variables** for sensitive configuration
2. **Store secrets** in AWS Systems Manager Parameter Store
3. **Review IAM permissions** regularly
4. **Enable CloudTrail** for audit logging

## Cost Optimization

- Monitor usage in AWS Cost Explorer
- Use auto-scaling to minimize costs
- Consider scheduling for development environments
- Regular cleanup of unused resources

## Next Steps

1. Set up CI/CD pipeline for automated deployments
2. Add monitoring and alerting
3. Configure custom domains
4. Implement blue-green deployments
5. Add staging and production environments

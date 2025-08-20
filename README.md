# Terraform Infrastructure for AWS ECS Fargate Multi-App Deployment

This project contains Terraform configurations for deploying multiple containerized applications using AWS ECS Fargate with comprehensive secret management and environment variable handling.

## Project Structure

```
terraform-infra/
├── README.md                          # This file
├── SECRETS_AND_ENV_VARS_GUIDE.md     # Comprehensive guide for secrets management
├── DEPLOYMENT_GUIDE.md               # Deployment instructions
├── providers.tf                       # AWS provider configuration
├── variables.tf                       # Root-level variables
├── main.tf                           # Root configuration
├── outputs.tf                        # Root-level outputs
├── modules/
│   ├── ecr/                          # ECR repositories with secrets management
│   │   ├── main.tf                   # ECR resources + Secrets Manager + Parameter Store
│   │   ├── variables.tf              # Module variables
│   │   └── outputs.tf                # Module outputs
│   ├── ecs/                          # ECS Fargate cluster and services
│   │   ├── main.tf                   # ECS resources with secret injection
│   │   ├── variables.tf              # Module variables
│   │   └── outputs.tf                # Module outputs
│   ├── iam/                          # IAM roles and policies
│   │   ├── main.tf                   # IAM resources with secrets permissions
│   │   ├── variables.tf              # Module variables
│   │   └── outputs.tf                # Module outputs
│   └── networking/                   # VPC, subnets, security groups
│       ├── main.tf                   # Networking resources
│       ├── variables.tf              # Module variables
│       └── outputs.tf                # Module outputs
├── environments/
│   └── dev/                          # Development environment
│       ├── main.tf                   # Environment-specific configuration
│       ├── variables.tf              # Environment variables
│       ├── outputs.tf                # Environment outputs
│       └── terraform.tfvars          # Variable values with sample secrets
└── examples/
    └── sample-app-config.tfvars      # Sample configuration examples
```

## Features

### Core Infrastructure
- **AWS ECS Fargate**: Serverless container orchestration
- **AWS ECR**: Private container registries for each application
- **AWS VPC**: Isolated networking with public subnets
- **Application Load Balancer**: Traffic distribution and health checks

### Security & Configuration Management
- **AWS Secrets Manager**: Secure storage for sensitive data (passwords, API keys)
- **AWS Systems Manager Parameter Store**: Non-sensitive configuration management
- **IAM Roles**: Least-privilege access for container secrets and parameters
- **Environment Isolation**: Separate secrets and configs per environment

### Monitoring & Logging
- **CloudWatch Logs**: Centralized logging for all containers
- **Container Insights**: Enhanced ECS monitoring
- **Health Checks**: Automatic container health monitoring

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **Docker installed** for building and pushing container images
4. **Container images** ready to deploy to ECR

## Quick Start

### 1. Configure Applications and Secrets

Edit `environments/dev/terraform.tfvars`:

```hcl
# Application configuration
apps = {
  "user-service" = {
    image  = "placeholder"
    port   = 3000
    public = true
    environment_vars = {
      LOG_LEVEL = "debug"
      SERVICE_NAME = "user-service"
    }
    secrets = {}
  }
}

# Secrets (stored in AWS Secrets Manager)
app_secrets = {
  "user-service" = {
    DB_PASSWORD = "your-secure-password"
    JWT_SECRET  = "your-jwt-secret"
  }
}

# Environment variables (stored in Parameter Store)
app_env_vars = {
  "user-service" = {
    DB_HOST = "localhost"
    DB_PORT = "5432"
    DB_NAME = "userdb"
  }
}
```

### 2. Deploy Infrastructure

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. Build and Push Container Images

```bash
# Get ECR login command
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and tag your image
docker build -t user-service .
docker tag user-service:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/ecs-multi-app-dev-user-service:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/ecs-multi-app-dev-user-service:latest
```

## Secrets and Environment Variables

### Managing Secrets
Secrets are automatically stored in AWS Secrets Manager and injected into containers as environment variables:

```javascript
// In your Node.js application
const dbPassword = process.env.DB_PASSWORD;  // From Secrets Manager
const jwtSecret = process.env.JWT_SECRET;    // From Secrets Manager
```

### Managing Configuration
Non-sensitive configuration is stored in AWS Systems Manager Parameter Store:

```javascript
// In your Node.js application
const dbHost = process.env.DB_HOST;  // From Parameter Store
const dbPort = process.env.DB_PORT;  // From Parameter Store
```

For detailed information, see [SECRETS_AND_ENV_VARS_GUIDE.md](./SECRETS_AND_ENV_VARS_GUIDE.md)

## Adding More Applications

To add another application:

1. **Add to app_names list**:
```hcl
app_names = ["user-service", "auth-service", "api-gateway"]
```

2. **Configure the application**:
```hcl
apps = {
  "auth-service" = {
    image  = "placeholder"
    port   = 3001
    public = true
    environment_vars = {
      SERVICE_NAME = "auth-service"
    }
    secrets = {}
  }
}
```

3. **Add secrets and environment variables**:
```hcl
app_secrets = {
  "auth-service" = {
    JWT_SECRET = "auth-service-jwt-secret"
  }
}

app_env_vars = {
  "auth-service" = {
    DB_NAME = "authdb"
  }
}
```

## Useful Commands

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# Destroy resources (be careful!)
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Get ECR login command
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# List ECS services
aws ecs list-services --cluster dev-cluster

# View container logs
aws logs get-log-events --log-group-name /ecs/dev-cluster/user-service --log-stream-name <stream-name>
```

## Outputs

After successful deployment, you'll get:
- **ECR Repository URLs**: For pushing container images
- **ECS Cluster ARN**: Reference to the ECS cluster
- **Load Balancer DNS**: Public endpoint for your applications
- **Secret ARNs**: References to stored secrets
- **Parameter ARNs**: References to stored parameters

## Troubleshooting

### Common Issues

1. **IAM Permission Errors**: Ensure AWS credentials have proper permissions
2. **Secret Access Denied**: Check IAM roles have access to secrets and parameters
3. **Container Startup Failures**: Check CloudWatch logs for detailed error messages
4. **Image Pull Errors**: Verify ECR repository exists and image is pushed
5. **Health Check Failures**: Ensure your app responds to `/health` endpoint

### Monitoring

- **ECS Console**: Monitor service status and task health
- **CloudWatch Logs**: View application logs by service
- **CloudWatch Metrics**: Monitor CPU, memory, and network usage
- **AWS Cost Explorer**: Track spending across services

## Security Best Practices

1. **Secrets Management**:
   - Never commit secrets to version control
   - Use different secrets for different environments
   - Rotate secrets regularly
   - Use AWS Secrets Manager for sensitive data

2. **IAM Security**:
   - Follow least-privilege principle
   - Regular review of IAM policies
   - Use IAM roles instead of access keys

3. **Network Security**:
   - Use security groups to control traffic
   - Consider private subnets for sensitive services
   - Enable VPC Flow Logs for monitoring

4. **Container Security**:
   - Use minimal base images
   - Scan images for vulnerabilities
   - Keep base images updated
   - Use non-root users in containers

## Cost Optimization

### ECS Fargate Costs
- **vCPU**: $0.04048 per vCPU per hour
- **Memory**: $0.004445 per GB per hour
- **Storage**: $0.000111 per GB per hour

### Optimization Strategies
1. **Right-size containers**: Use appropriate CPU and memory allocations
2. **Auto-scaling**: Scale down during low usage periods
3. **Spot instances**: Consider ECS with EC2 for cost savings
4. **Reserved capacity**: For predictable workloads
5. **Lifecycle policies**: Clean up old ECR images automatically

## Environment Management

### Development Environment
- Use minimal resources
- Enable debug logging
- Use development secrets
- Allow public access for testing

### Production Environment
- Use appropriate resource allocations
- Enable production logging levels
- Use strong, rotated secrets
- Implement proper monitoring and alerting

### Multi-Environment Setup
```bash
# Development
cd environments/dev
terraform apply

# Staging
cd environments/staging
terraform apply

# Production
cd environments/prod
terraform apply
```

## Next Steps

1. **CI/CD Pipeline**: Set up automated deployments with GitHub Actions or AWS CodePipeline
2. **Custom Domains**: Configure Route 53 and SSL certificates
3. **Advanced Monitoring**: Implement custom CloudWatch dashboards and alarms
4. **Blue-Green Deployments**: Implement zero-downtime deployments
5. **Service Mesh**: Consider AWS App Mesh for service-to-service communication
6. **Database Integration**: Add RDS, DynamoDB, or other data stores
7. **Caching**: Implement ElastiCache for Redis or Memcached

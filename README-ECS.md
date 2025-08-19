# ECS Fargate Multi-App Infrastructure

This Terraform infrastructure provisions AWS ECS Fargate resources for running multiple containerized applications without a load balancer. Each application gets its own public IP address for direct access.

## Architecture

The infrastructure consists of:

- **VPC with Public Subnets**: Custom VPC with 2 public subnets across different AZs
- **Internet Gateway**: For outbound internet access
- **Security Group**: Allows inbound traffic on all ports (to be restricted later)
- **ECR Repositories**: Container registries for each application
- **ECS Cluster**: Fargate cluster for running containerized applications
- **IAM Roles**: Task execution and task roles with appropriate permissions
- **CloudWatch Logs**: Log groups for each application

## Module Structure

```
modules/
├── networking/          # VPC, subnets, security groups
├── ecr/                # ECR repositories
├── ecs/                # ECS cluster, services, task definitions
└── iam/                # IAM roles and policies

environments/
└── dev/                # Development environment configuration
```

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Docker images pushed to ECR repositories

## Quick Start

### 1. Clone and Navigate

```bash
cd terraform-infra/environments/dev
```

### 2. Configure Variables

Edit `terraform.tfvars` with your specific configuration:

```hcl
# AWS Configuration
aws_region   = "us-east-1"
project_name = "ecs-multi-app"
environment  = "dev"

# Application Configuration
app_names = ["node-app-1", "python-app-1"]

apps = {
  node-app-1 = {
    image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest"
    port  = 3000
  }
  python-app-1 = {
    image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/python-app-1:latest"
    port  = 8000
  }
}

cluster_name = "dev-cluster"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

### 4. Build and Push Docker Images

After the ECR repositories are created, build and push your Docker images:

```bash
# Get ECR login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Build and push Node.js app
cd /path/to/node-app-1
docker build -t node-app-1 .
docker tag node-app-1:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest

# Build and push Python app
cd /path/to/python-app-1
docker build -t python-app-1 .
docker tag python-app-1:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/python-app-1:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/python-app-1:latest
```

### 5. Access Applications

Each ECS task gets a dynamic public IP. To find the public IPs:

```bash
# List running tasks
aws ecs list-tasks --cluster dev-cluster

# Get task details with network information
aws ecs describe-tasks --cluster dev-cluster --tasks <task-arn> --query 'tasks[*].attachments[*].details[?name==`networkInterfaceId`].value' --output table

# Get public IP from network interface
aws ec2 describe-network-interfaces --network-interface-ids <eni-id> --query 'NetworkInterfaces[*].Association.PublicIp' --output table
```

## Module Documentation

### Networking Module

Creates VPC infrastructure with public subnets and internet connectivity.

**Inputs:**
- `project_name`: Project name for resource naming
- `environment`: Environment name (dev, staging, prod)
- `vpc_cidr`: CIDR block for VPC (default: 10.0.0.0/16)
- `availability_zones`: List of AZs to use
- `public_subnet_cidrs`: CIDR blocks for public subnets

**Outputs:**
- `vpc_id`: VPC ID
- `public_subnets`: List of public subnet IDs
- `security_group_id`: Security group ID

### ECR Module

Creates ECR repositories for application images.

**Inputs:**
- `app_names`: List of application names
- `environment`: Environment name

**Outputs:**
- `repository_urls`: Map of repository URLs
- `repository_arns`: Map of repository ARNs

### IAM Module

Creates necessary IAM roles for ECS tasks.

**Inputs:**
- `project_name`: Project name
- `environment`: Environment name

**Outputs:**
- `execution_role_arn`: Task execution role ARN
- `task_role_arn`: Task role ARN

### ECS Module

Creates ECS cluster, task definitions, and services.

**Inputs:**
- `cluster_name`: ECS cluster name
- `environment`: Environment name
- `apps`: Map of app configurations (image, port)
- `subnets`: List of subnet IDs
- `security_group_id`: Security group ID
- `execution_role_arn`: Task execution role ARN
- `task_role_arn`: Task role ARN

**Outputs:**
- `cluster_id`: ECS cluster ID
- `service_arns`: Map of service ARNs
- `task_definition_arns`: Map of task definition ARNs

## Resource Specifications

### ECS Task Configuration
- **Platform**: Fargate
- **CPU**: 256 (0.25 vCPU)
- **Memory**: 512 MB
- **Network Mode**: awsvpc
- **Public IP**: Enabled

### Logging
- **Log Driver**: awslogs
- **Log Retention**: 7 days
- **Log Groups**: `/ecs/{cluster_name}/{app_name}`

## Security Considerations

⚠️ **Security Notice**: The current security group allows inbound traffic on all ports from all sources. This is intentional for initial setup but should be restricted in production:

```hcl
# Restrict to specific ports and sources
ingress {
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP
}
```

## Cost Optimization

This infrastructure uses:
- **Fargate**: Pay-per-use compute
- **ECR**: Pay for storage and data transfer
- **CloudWatch Logs**: Pay for log ingestion and storage
- **VPC**: No additional charges for VPC components

Estimated cost for 2 applications running 24/7: ~$15-25/month

## Troubleshooting

### Common Issues

1. **ECS Tasks Not Starting**
   - Check if Docker images exist in ECR
   - Verify IAM roles have correct permissions
   - Check CloudWatch logs for error messages

2. **Cannot Access Applications**
   - Verify security group allows inbound traffic
   - Check if tasks have public IPs assigned
   - Ensure applications are listening on 0.0.0.0, not localhost

3. **ECR Push Failures**
   - Verify AWS credentials are configured
   - Check ECR repository exists
   - Ensure proper ECR login

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster dev-cluster --services <service-name>

# View ECS task logs
aws logs tail /ecs/dev-cluster/node-app-1 --follow

# Force new deployment
aws ecs update-service --cluster dev-cluster --service <service-name> --force-new-deployment

# Scale service
aws ecs update-service --cluster dev-cluster --service <service-name> --desired-count 2
```

## Cleanup

To destroy all resources:

```bash
cd environments/dev
terraform destroy
```

**Note**: Ensure ECR repositories are empty before destroying, or add `force_delete = true` to the ECR resource configuration.

## Next Steps

1. **Restrict Security Groups**: Limit inbound traffic to specific ports and sources
2. **Add Application Load Balancer**: For production workloads requiring load balancing
3. **Implement CI/CD**: Automate image builds and deployments
4. **Add Monitoring**: CloudWatch alarms for CPU, memory, and application metrics
5. **Secret Management**: Use AWS Secrets Manager for sensitive configuration
6. **Database Integration**: Add RDS or other database services as needed

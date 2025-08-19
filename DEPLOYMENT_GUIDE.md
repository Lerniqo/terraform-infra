# ECS Fargate Multi-App Deployment Guide

This guide walks you through deploying multiple containerized applications on AWS ECS Fargate using the provided Terraform infrastructure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Application Examples](#application-examples)
5. [Testing Your Deployment](#testing-your-deployment)
6. [Troubleshooting](#troubleshooting)
7. [Clean Up](#clean-up)

## Prerequisites

### Required Tools

1. **AWS CLI** - Configure with appropriate credentials
   ```bash
   aws configure
   ```

2. **Terraform** - Version 1.0 or later
   ```bash
   # macOS
   brew install terraform
   
   # Verify installation
   terraform --version
   ```

3. **Docker** - For building container images
   ```bash
   docker --version
   ```

4. **jq** - For parsing JSON output (optional but recommended)
   ```bash
   # macOS
   brew install jq
   ```

### AWS Permissions

Your AWS user/role needs permissions for:
- VPC management (EC2)
- ECS (Elastic Container Service)
- ECR (Elastic Container Registry)
- IAM (Identity and Access Management)
- CloudWatch Logs

## Quick Start

### 1. Automated Deployment

Use the provided deployment script for a guided setup:

```bash
cd /Users/devinda/VS/sem-5-project/terraform-infra
./scripts/deploy.sh dev
```

This script will:
- Validate your configuration
- Initialize and apply Terraform
- Provide instructions for pushing Docker images
- Show you how to get public IPs

### 2. Manual Deployment

If you prefer manual control:

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Step-by-Step Deployment

### Step 1: Configure Variables

Edit `environments/dev/terraform.tfvars` with your configuration:

```hcl
# AWS Configuration
aws_region   = "us-east-1"  # Change to your preferred region
project_name = "ecs-multi-app"
environment  = "dev"

# Networking Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

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

**Important**: Replace `123456789012` with your actual AWS account ID.

### Step 2: Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

### Step 3: Deploy Infrastructure

```bash
cd environments/dev

# Initialize Terraform (first time only)
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Step 4: Build and Push Docker Images

After the infrastructure is created, you'll have ECR repositories. Build and push your images:

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# For each application:
cd /path/to/your/node-app-1
docker build -t node-app-1 .
docker tag node-app-1:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest
```

### Step 5: Wait for Services to Start

ECS will automatically start your services once the images are available. Monitor the progress:

```bash
# Check service status
aws ecs describe-services --cluster dev-cluster --services $(aws ecs list-services --cluster dev-cluster --query 'serviceArns[]' --output text)
```

### Step 6: Get Public IPs

Use the provided script to get public IPs:

```bash
./scripts/get-task-ips.sh dev-cluster
```

## Application Examples

### Node.js Application Structure

```
node-app-1/
├── Dockerfile
├── package.json
├── app.js
└── healthcheck.js
```

Use the example files in the `examples/` directory:

1. Copy `examples/Dockerfile.nodejs` to your app as `Dockerfile`
2. Copy `examples/package.json` and modify as needed
3. Copy `examples/app.js` as your main application file
4. Copy `examples/healthcheck.js` for health checks

### Python Application Structure

```
python-app-1/
├── Dockerfile
├── requirements.txt
├── app.py
└── healthcheck.py
```

Use the example files in the `examples/` directory:

1. Copy `examples/Dockerfile.python` to your app as `Dockerfile`
2. Copy `examples/requirements.txt` and modify as needed
3. Copy `examples/app.py` as your main application file
4. Copy `examples/healthcheck.py` for health checks

### Required Endpoints

Each application must have:

1. **Health Check Endpoint**: `/health`
   - Must return HTTP 200
   - Used by ECS for health monitoring

2. **Application Endpoints**: Your custom API endpoints

Example health check response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "service": "node-app-1"
}
```

## Testing Your Deployment

### 1. Get Public IPs

```bash
./scripts/get-task-ips.sh dev-cluster
```

### 2. Test Health Endpoints

```bash
# Test Node.js app
curl http://PUBLIC_IP:3000/health

# Test Python app
curl http://PUBLIC_IP:8000/health
```

### 3. Test Application Endpoints

```bash
# Test Node.js app
curl http://PUBLIC_IP:3000/
curl http://PUBLIC_IP:3000/api/status

# Test Python app
curl http://PUBLIC_IP:8000/
curl http://PUBLIC_IP:8000/api/status
```

### 4. Monitor Logs

```bash
# View logs for specific application
aws logs tail /ecs/dev-cluster/node-app-1 --follow

# View all log groups
aws logs describe-log-groups --log-group-name-prefix "/ecs/dev-cluster"
```

## Troubleshooting

### Common Issues

#### 1. ECS Tasks Not Starting

**Symptoms**: Services show 0/1 running tasks

**Solutions**:
- Check if Docker images exist in ECR
- Verify IAM roles have correct permissions
- Check CloudWatch logs for error messages
- Ensure images are built for the correct architecture (linux/amd64)

```bash
# Check service events
aws ecs describe-services --cluster dev-cluster --services YOUR_SERVICE_NAME

# Check task definition
aws ecs describe-task-definition --task-definition YOUR_TASK_DEFINITION
```

#### 2. Cannot Access Applications

**Symptoms**: Connection timeouts when accessing public IPs

**Solutions**:
- Verify security group allows inbound traffic on the correct ports
- Check if tasks have public IPs assigned
- Ensure applications are listening on `0.0.0.0`, not `localhost` or `127.0.0.1`
- Verify the application is running on the correct port

#### 3. ECR Push Failures

**Symptoms**: Docker push commands fail

**Solutions**:
- Verify AWS credentials are configured correctly
- Check if ECR repositories exist
- Ensure proper ECR login
- Verify you're pushing to the correct region

```bash
# Debug ECR login
aws ecr get-login-password --region us-east-1

# List ECR repositories
aws ecr describe-repositories
```

#### 4. High CPU/Memory Usage

**Symptoms**: Tasks restarting frequently

**Solutions**:
- Increase CPU/memory in task definition (edit `modules/ecs/main.tf`)
- Optimize application code
- Check for memory leaks in application logs

### Debug Commands

```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters dev-cluster

# List all services
aws ecs list-services --cluster dev-cluster

# Describe specific service
aws ecs describe-services --cluster dev-cluster --services SERVICE_NAME

# List tasks
aws ecs list-tasks --cluster dev-cluster

# Describe tasks (with network info)
aws ecs describe-tasks --cluster dev-cluster --tasks TASK_ARN

# Force new deployment
aws ecs update-service --cluster dev-cluster --service SERVICE_NAME --force-new-deployment
```

## Updating Applications

### 1. Build and Push New Image

```bash
# Build new version
docker build -t node-app-1:v2 .

# Tag for ECR
docker tag node-app-1:v2 YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest

# Push to ECR
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/node-app-1:latest
```

### 2. Force New Deployment

```bash
aws ecs update-service --cluster dev-cluster --service dev-cluster-node-app-1-service --force-new-deployment
```

### 3. Rolling Updates

ECS automatically performs rolling updates when you force a new deployment with updated images.

## Scaling Applications

### Scale Service

```bash
# Scale to 2 instances
aws ecs update-service --cluster dev-cluster --service SERVICE_NAME --desired-count 2

# Scale back to 1 instance
aws ecs update-service --cluster dev-cluster --service SERVICE_NAME --desired-count 1
```

### Update Task Resources

Edit `modules/ecs/main.tf` and change:

```hcl
cpu    = "512"  # From 256
memory = "1024" # From 512
```

Then apply the changes:

```bash
terraform apply
```

## Clean Up

### Option 1: Automated Cleanup

```bash
./scripts/cleanup.sh dev
```

### Option 2: Manual Cleanup

```bash
cd environments/dev
terraform destroy
```

### Complete Cleanup

To remove all Terraform files:

```bash
cd environments/dev
rm -rf .terraform terraform.tfstate*
```

## Security Hardening

### 1. Restrict Security Group

Edit `modules/networking/main.tf` to restrict inbound access:

```hcl
# Replace the current ingress rule with specific ports
ingress {
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Your IP only
}

ingress {
  from_port   = 8000
  to_port     = 8000
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Your IP only
}
```

### 2. Use Secrets Manager

For sensitive configuration, integrate AWS Secrets Manager:

```hcl
# In task definition
environment_secrets = [
  {
    name      = "DATABASE_PASSWORD"
    valueFrom = "arn:aws:secretsmanager:region:account:secret:name"
  }
]
```

### 3. Enable VPC Flow Logs

Add VPC flow logs for network monitoring:

```hcl
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

## Performance Optimization

### 1. Use Application Load Balancer

For production workloads, consider adding an Application Load Balancer:

```hcl
module "alb" {
  source = "terraform-aws-modules/alb/aws"
  
  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = "application"
  vpc_id             = module.networking.vpc_id
  subnets            = module.networking.public_subnets
  security_groups    = [module.networking.security_group_id]
}
```

### 2. Container Insights

Enable Container Insights for better monitoring (already enabled in the ECS module).

### 3. Optimize Docker Images

- Use multi-stage builds
- Minimize image layers
- Use smaller base images (alpine)
- Remove unnecessary packages

## Cost Optimization

### 1. Use Spot Capacity (Fargate Spot)

Modify the ECS service to use Spot capacity:

```hcl
capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  weight           = 100
}
```

### 2. Right-size Resources

Monitor CPU and memory usage and adjust:

```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=YOUR_SERVICE --start-time 2024-01-01T00:00:00Z --end-time 2024-01-02T00:00:00Z --period 300 --statistics Average
```

### 3. Implement Auto Scaling

Add auto scaling based on CPU/memory:

```hcl
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

## Next Steps

1. **CI/CD Pipeline**: Set up GitHub Actions or AWS CodePipeline for automated deployments
2. **Monitoring**: Add CloudWatch alarms and dashboards
3. **Backup Strategy**: Implement backup for persistent data
4. **Multi-Environment**: Create staging and production environments
5. **Service Mesh**: Consider AWS App Mesh for advanced traffic management
6. **Database Integration**: Add RDS or DynamoDB as needed

## Support

For issues and questions:

1. Check CloudWatch logs for application errors
2. Review AWS ECS documentation
3. Check Terraform AWS provider documentation
4. Open an issue in the project repository

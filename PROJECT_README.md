# Terraform Infrastructure - Comprehensive AWS & GitHub Management

This project provides a complete Terraform infrastructure setup for deploying containerized applications on AWS with integrated GitHub repository management and automated CI/CD pipelines.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  GitHub Repos   │    │   AWS Amplify   │    │   ECS Fargate   │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Frontend    │ │───▶│ │ React App   │ │    │ │ Backend API │ │
│ │ Repository  │ │    │ │ Deployment  │ │    │ │ Services    │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │                 │    │ ┌─────────────┐ │
│ │ Backend     │ │    │                 │    │ │ Database    │ │
│ │ Repository  │ │    │                 │    │ │ Services    │ │
│ └─────────────┘ │    │                 │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
terraform-infra/
├── README.md                          # This documentation
├── DEPLOYMENT_GUIDE.md               # Detailed deployment instructions
├── SECRETS_AND_ENV_VARS_GUIDE.md     # Secrets management guide
├── main.tf                           # Root configuration
├── variables.tf                      # Root variables
├── outputs.tf                        # Root outputs
├── providers.tf                      # Provider configurations
│
├── environments/                     # Environment-specific configurations
│   └── dev/                         # Development environment
│       ├── main.tf                  # Environment-specific config
│       ├── variables.tf             # Environment variables
│       ├── outputs.tf               # Environment outputs
│       └── terraform.tfvars         # Environment values
│
├── modules/                         # Reusable Terraform modules
│   ├── github/                      # 🆕 GitHub repository management
│   │   ├── main.tf                  # Repository creation & configuration
│   │   ├── variables.tf             # Module variables
│   │   ├── outputs.tf               # Module outputs
│   │   ├── versions.tf              # Provider requirements
│   │   └── README.md                # Module documentation
│   │
│   ├── amplify/                     # AWS Amplify for frontend hosting
│   │   ├── main.tf                  # Amplify app configuration
│   │   ├── variables.tf             # Module variables
│   │   └── outputs.tf               # Module outputs
│   │
│   ├── networking/                  # VPC, subnets, security groups
│   ├── ecs/                         # ECS Fargate cluster and services
│   ├── ecr/                         # Elastic Container Registry
│   ├── alb/                         # Application Load Balancer
│   ├── apigateway/                  # API Gateway configuration
│   ├── apprunner/                   # AWS App Runner
│   ├── iam/                         # IAM roles and policies
│   ├── elastic-ip/                  # Elastic IP management
│   └── s3-frontend/                 # S3 static website hosting
│
└── examples/                        # Complete usage examples
    ├── github-amplify-frontend/     # 🆕 GitHub + Amplify integration
    │   ├── README.md                # Example documentation
    │   ├── main.tf                  # Complete setup configuration
    │   ├── variables.tf             # Example variables
    │   ├── outputs.tf               # Example outputs
    │   ├── terraform.tfvars.example # Configuration template
    │   ├── .env.github.example      # GitHub auth template
    │   ├── .gitignore               # Security-focused gitignore
    │   └── templates/               # Configuration templates
    │       ├── frontend-readme.md   # Generated README template
    │       ├── amplify.yml          # Amplify build config
    │       ├── amplify-buildspec.yml # Detailed build spec
    │       └── env-example          # Environment variables template
    │
    ├── amplify-integration-example.tf # Basic Amplify usage
    └── sample-app-config.tfvars      # Sample configurations
```

## 🚀 Features

### 🆕 GitHub Repository Management
- **Automated Repository Creation**: Create and configure GitHub repositories with Terraform
- **Branch Protection Rules**: Implement security policies and code review requirements
- **Deploy Keys Management**: Secure deployment key configuration
- **Repository Files**: Automatically create initial project files and documentation
- **GitHub App Authentication**: Secure, token-free authentication using GitHub Apps

### AWS Infrastructure Management
- **AWS ECS Fargate**: Serverless container orchestration
- **AWS ECR**: Private container registries for each application
- **AWS Amplify**: Automated frontend deployment and hosting
- **AWS VPC**: Isolated networking with public/private subnets
- **Application Load Balancer**: Traffic distribution and health checks
- **API Gateway**: RESTful API management and routing
- **App Runner**: Simplified container deployment for microservices

### Security & Best Practices
- **Comprehensive Secret Management**: AWS Secrets Manager and Parameter Store integration
- **IAM Role-Based Access**: Principle of least privilege
- **VPC Security Groups**: Network-level security controls
- **GitHub App Authentication**: Secure repository access without personal tokens
- **Environment Isolation**: Separate configurations for different environments

## 🏃‍♂️ Quick Start

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Organization** or personal account
3. **GitHub App** configured for repository management
4. **Terraform** v1.0+ installed
5. **AWS CLI** configured

### Option 1: Full Stack Deployment (GitHub + AWS)

Deploy a complete frontend repository with AWS Amplify integration:

```bash
# 1. Navigate to the example
cd examples/github-amplify-frontend/

# 2. Configure GitHub authentication
cp .env.github.example .env.github
# Edit .env.github with your GitHub App credentials
export $(cat .env.github | xargs)

# 3. Configure deployment variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

# 4. Deploy
terraform init
terraform plan
terraform apply
```

### Option 2: AWS Infrastructure Only

Deploy just the AWS infrastructure for existing applications:

```bash
# 1. Navigate to development environment
cd environments/dev/

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit with your configuration

# 3. Deploy
terraform init
terraform plan
terraform apply
```

## 📖 Detailed Guides

### 🆕 GitHub Repository Management

Create and manage GitHub repositories with automated configuration:

```hcl
module "frontend_repo" {
  source = "./modules/github"

  repository_name        = "my-awesome-frontend"
  repository_description = "Frontend application with automated deployment"
  repository_visibility  = "private"
  
  # Branch protection
  enable_branch_protection         = true
  required_status_checks          = ["build", "test", "lint"]
  required_approving_review_count = 1
  
  # Initial files
  repository_files = {
    "README.md" = {
      content = "# My Awesome Frontend\\n\\nBuilt with React and deployed with AWS Amplify"
    }
  }
}
```

### Frontend + Amplify Integration

Complete setup from repository creation to live deployment:

```hcl
# Creates GitHub repository
module "frontend_repository" {
  source = "./modules/github"
  # ... repository configuration
}

# Creates Amplify app connected to repository
module "amplify_app" {
  source = "./modules/amplify"
  
  project_name   = "my-frontend"
  repository_url = module.frontend_repository.repository_https_clone_url
  # ... Amplify configuration
}
```

### ECS Fargate Backend Services

Deploy containerized backend services:

```hcl
module "backend_service" {
  source = "./modules/ecs"
  
  project_name = "my-backend"
  environment  = "production"
  
  services = {
    api = {
      image           = "my-org/api:latest"
      cpu             = 256
      memory          = 512
      desired_count   = 2
      container_port  = 3000
    }
  }
}
```

## 🔧 Configuration Examples

### React Frontend with Amplify

```hcl
# GitHub repository
frontend_repo_name = "react-frontend"
frontend_topics = ["react", "typescript", "amplify"]

# Amplify configuration
amplify_build_commands = [
  "npm ci",
  "npm run build"
]
amplify_artifact_base_dir = "build"

# Environment variables
amplify_environment_variables = {
  REACT_APP_API_URL = "https://api.example.com"
  NODE_ENV = "production"
}
```

### Vue.js Frontend with Amplify

```hcl
# Repository configuration
frontend_repo_name = "vue-frontend"
frontend_gitignore_template = "Node"

# Build configuration
amplify_build_commands = [
  "npm ci",
  "npm run build"
]
amplify_artifact_base_dir = "dist"
```

### Angular Frontend with Amplify

```hcl
# Repository and build configuration
frontend_repo_name = "angular-frontend"
amplify_build_commands = [
  "npm ci",
  "npm run build --prod"
]
amplify_artifact_base_dir = "dist/my-app"
```

## 🛡️ Security Features

### GitHub Security
- **GitHub App Authentication** - No personal access tokens required
- **Branch Protection Rules** - Enforce code review and status checks
- **Repository Privacy Controls** - Fine-grained access management
- **Deploy Key Management** - Secure deployment access

### AWS Security
- **IAM Role-Based Access** - Principle of least privilege
- **VPC Network Isolation** - Private subnets for backend services
- **Secrets Manager Integration** - Encrypted secret storage
- **Security Group Rules** - Network-level access controls

## 📊 Monitoring & Observability

- **AWS CloudWatch** - Application and infrastructure monitoring
- **ECS Service Health Checks** - Automated health monitoring
- **Application Load Balancer Health Checks** - Traffic routing based on health
- **Amplify Build Monitoring** - Frontend deployment status tracking

## 🌍 Multi-Environment Support

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

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Frontend
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      # Amplify will automatically build and deploy
```

## 📚 Additional Resources

- **[GitHub Module Documentation](./modules/github/README.md)** - Detailed GitHub module usage
- **[Amplify Integration Example](./examples/github-amplify-frontend/README.md)** - Complete frontend setup guide
- **[Deployment Guide](./DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[Secrets Management Guide](./SECRETS_AND_ENV_VARS_GUIDE.md)** - Security best practices

## 🆘 Troubleshooting

### Common Issues

1. **GitHub Authentication Errors**
   ```bash
   # Verify environment variables
   echo $GITHUB_APP_ID
   echo $GITHUB_APP_INSTALLATION_ID
   ls -la $GITHUB_APP_PEM_FILE
   ```

2. **AWS Permission Issues**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify Terraform AWS provider
   terraform providers
   ```

3. **Module Dependencies**
   ```bash
   # Reinitialize Terraform
   terraform init -upgrade
   
   # Check module sources
   terraform get
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test thoroughly
4. Update documentation as needed
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**🔗 Quick Links:**
- [AWS Console](https://console.aws.amazon.com/)
- [GitHub Apps Documentation](https://docs.github.com/en/developers/apps)
- [Terraform Registry](https://registry.terraform.io/)
- [AWS Amplify Console](https://console.aws.amazon.com/amplify/)

# Infrastructure Architecture and Access Guide

## Overview
This Terraform project sets up a complete microservices architecture on AWS with proper routing for frontend and backend services.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Users         │    │   AWS Amplify   │    │   API Gateway   │
│                 │    │   (Frontend)    │    │   (APIs only)   │
│                 │    │                 │    │                 │
│  Frontend  ────────▶│  React App      │    │                 │
│  Access    ────────▶│  Static Hosting │    │                 │
│                 │    │                 │    │                 │
│  API Calls ─────────────────────────────────▶│  /api/*        │
│            ─────────────────────────────────▶│  Routes        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   VPC Link      │
                                               │   Integration   │
                                               └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │ Application     │
                                               │ Load Balancer   │
                                               │ (Internal)      │
                                               └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   ECS Fargate   │
                                               │   Services      │
                                               │   (Private)     │
                                               └─────────────────┘
```

## Access URLs

### Frontend Access
- **Primary URL**: `https://main.d1mn6jr8nzp84k.amplifyapp.com`
- **Custom Domain** (when configured): `https://dev.learniqo.linkpc.net`
- **Route Pattern**: `/` (root and all frontend routes)

### API Access
- **API Gateway Base URL**: `https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev`
- **Route Pattern**: `/api/{service-name}/` 

### Microservice Endpoints
1. **User Service**: `https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/user-service`
2. **Progress Service**: `https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/progress-service`
3. **Content Service**: `https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/content-service`
4. **AI Service**: `https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/ai-service`

## Frontend Configuration

The React frontend is configured with the following environment variables:
- `REACT_APP_API_URL`: `https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev`
- `REACT_APP_ENV`: `dev`

### Making API Calls from Frontend

In your React application, make API calls like this:

```javascript
// Get the API base URL from environment
const API_BASE_URL = process.env.REACT_APP_API_URL;

// Example API calls
const getUserData = async () => {
  const response = await fetch(`${API_BASE_URL}/api/user-service/users`);
  return response.json();
};

const getProgress = async () => {
  const response = await fetch(`${API_BASE_URL}/api/progress-service/progress`);
  return response.json();
};

const getContent = async () => {
  const response = await fetch(`${API_BASE_URL}/api/content-service/content`);
  return response.json();
};

const getAIInsights = async () => {
  const response = await fetch(`${API_BASE_URL}/api/ai-service/insights`);
  return response.json();
};
```

## Security Configuration

### CORS Settings
The API Gateway is configured with CORS to allow:
- **Origins**: `*` (should be restricted to your domain in production)
- **Methods**: `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`
- **Headers**: `Content-Type`, `X-Amz-Date`, `Authorization`, `X-Api-Key`, `X-Amz-Security-Token`

### Network Security
- **ECS Services**: Run in private subnets with no direct internet access
- **Load Balancer**: Internal ALB, only accessible via VPC Link
- **API Gateway**: Public-facing with VPC Link to private resources
- **Amplify**: Public CDN for static content

## Deployment Status

### Current Infrastructure
✅ VPC with public/private subnets
✅ ECS Fargate cluster with 4 microservices
✅ Internal Application Load Balancer
✅ API Gateway with VPC Link integration
✅ AWS Amplify for frontend hosting
✅ ECR repositories for container images
✅ IAM roles and security groups
✅ CloudWatch logging

### Service Health Check
All ECS services should be running with:
- **Desired Count**: 1
- **Health Check**: HTTP GET `/` on port 3000
- **Status**: Check ECS console for service status

## Testing the Setup

### 1. Test Frontend Access
```bash
curl -I https://main.d1mn6jr8nzp84k.amplifyapp.com
# Should return 200 OK
```

### 2. Test API Gateway
```bash
# Test user service
curl https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/user-service/

# Test progress service  
curl https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/progress-service/

# Test content service
curl https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/content-service/

# Test AI service
curl https://fqbtpwjfb5.execute-api.us-east-1.amazonaws.com/dev/api/ai-service/
```

## Troubleshooting

### Common Issues

1. **503 Service Unavailable**
   - Check if ECS services are running
   - Verify target group health in ALB
   - Check VPC Link status

2. **CORS Errors**
   - Ensure API calls include proper headers
   - Verify CORS configuration in API Gateway

3. **404 Not Found**
   - Check API Gateway route configuration
   - Verify service paths in requests

4. **Amplify Build Failures**
   - Check GitHub repository access
   - Verify build specifications
   - Check environment variables

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster dev-cluster --services dev-cluster-user-service-service

# Check ALB target groups
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check API Gateway logs
aws logs describe-log-groups --log-group-name-prefix "/aws/apigateway/ecs-multi-app-dev"
```

## Next Steps

1. **Domain Configuration**: Set up custom domain for API Gateway
2. **SSL Certificates**: Configure ACM certificates for HTTPS
3. **Authentication**: Implement Cognito or custom auth
4. **Monitoring**: Set up CloudWatch dashboards and alarms
5. **CI/CD**: Implement automated deployments for services

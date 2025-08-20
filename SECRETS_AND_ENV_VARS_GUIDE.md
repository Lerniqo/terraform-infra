# Secrets and Environment Variables Management Guide

This guide explains how to use the enhanced ECR setup with secret handling and environment variable passing for containers.

## Overview

The infrastructure now supports:
1. **AWS Secrets Manager** for sensitive data (passwords, API keys, etc.)
2. **AWS Systems Manager Parameter Store** for non-sensitive environment variables
3. **Container-level environment variables** for app-specific configuration
4. **Automatic injection** of secrets and environment variables into ECS containers

## Architecture

### Secrets Management
- **AWS Secrets Manager**: Stores sensitive data like database passwords, API keys, JWT secrets
- **AWS Systems Manager Parameter Store**: Stores non-sensitive configuration like database hosts, ports, service names
- **IAM Roles**: Automatically configured with permissions to access secrets and parameters

### Environment Variables
- **Static Environment Variables**: Defined directly in the app configuration
- **Parameter Store Variables**: Retrieved from AWS Systems Manager at runtime
- **Secret Variables**: Retrieved from AWS Secrets Manager at runtime

## Configuration

### 1. Application Configuration in terraform.tfvars

```hcl
apps = {
  "user-service" = {
    image  = "placeholder"
    port   = 3000
    public = true
    environment_vars = {
      LOG_LEVEL = "debug"
      SERVICE_NAME = "user-service"
    }
    secrets = {}  # Can be used for individual secret ARNs
  }
}
```

### 2. Secrets Configuration

```hcl
app_secrets = {
  "user-service" = {
    DB_PASSWORD = "your-secure-db-password"
    JWT_SECRET  = "your-jwt-secret-key"
    API_KEY     = "your-api-key"
  }
}
```

### 3. Environment Variables Configuration

```hcl
app_env_vars = {
  "user-service" = {
    DB_HOST = "localhost"
    DB_PORT = "5432"
    DB_NAME = "userdb"
    CACHE_TTL = "3600"
  }
}
```

## Usage Examples

### Basic Setup
1. Configure your applications in `terraform.tfvars`
2. Add secrets to `app_secrets` map
3. Add environment variables to `app_env_vars` map
4. Run `terraform apply`

### Adding New Secrets
```hcl
app_secrets = {
  "my-app" = {
    NEW_SECRET = "secret-value"
    ANOTHER_SECRET = "another-secret-value"
  }
}
```

### Adding New Environment Variables
```hcl
app_env_vars = {
  "my-app" = {
    NEW_CONFIG = "config-value"
    FEATURE_FLAG = "enabled"
  }
}
```

### Individual Secret ARNs
You can also reference existing secrets by their ARNs:
```hcl
apps = {
  "my-app" = {
    # ... other config
    secrets = {
      EXTERNAL_SECRET = "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-external-secret"
    }
  }
}
```

## Security Features

### IAM Permissions
- **Task Execution Role**: Can read secrets and parameters for container startup
- **Task Role**: Can read secrets and parameters during container runtime
- **Least Privilege**: Only access to secrets/parameters for the specific project and environment

### Resource Naming
- Secrets: `{project_name}-{environment}-{app_name}-secrets`
- Parameters: `/{project_name}/{environment}/{app_name}`
- This ensures environment isolation and easy management

## Best Practices

### Secrets Management
1. **Never commit secrets to version control**
2. **Use different secrets for different environments**
3. **Rotate secrets regularly**
4. **Use AWS Secrets Manager for sensitive data**
5. **Use Parameter Store for non-sensitive configuration**

### Environment Variables
1. **Use descriptive names**
2. **Group related variables logically**
3. **Use consistent naming conventions**
4. **Document environment variables**

### Development Workflow
1. **Local Development**: Use `.env` files (not committed)
2. **Development Environment**: Use terraform.tfvars with dev values
3. **Production Environment**: Use separate terraform.tfvars with prod values

## Container Access

### Environment Variables
Environment variables are automatically available in your containers:
```bash
echo $LOG_LEVEL
echo $DB_HOST
```

### Secrets
Secrets are automatically injected as environment variables:
```bash
echo $DB_PASSWORD
echo $JWT_SECRET
```

## Troubleshooting

### Common Issues
1. **IAM Permission Errors**: Check that the execution and task roles have proper permissions
2. **Secret Not Found**: Verify the secret exists in AWS Secrets Manager
3. **Parameter Not Found**: Verify the parameter exists in AWS Systems Manager
4. **Container Startup Errors**: Check CloudWatch logs for detailed error messages

### Debugging
1. **Check ECS Task Logs**: View logs in CloudWatch
2. **Verify IAM Policies**: Ensure roles have required permissions
3. **Test Secret Access**: Use AWS CLI to verify secret/parameter access
4. **Check Resource Naming**: Verify resource names match expected patterns

## Migration Guide

### From Static Environment Variables
1. Move sensitive variables to `app_secrets`
2. Move non-sensitive configuration to `app_env_vars`
3. Keep app-specific variables in `environment_vars`
4. Update application code if needed

### Adding to Existing Applications
1. Add `environment_vars` and `secrets` to existing app configurations
2. Add `app_secrets` and `app_env_vars` maps to terraform.tfvars
3. Run `terraform plan` to review changes
4. Run `terraform apply` to apply changes

## Advanced Usage

### Cross-Application Secrets
Use Parameter Store for shared configuration:
```hcl
app_env_vars = {
  "app1" = {
    SHARED_SERVICE_URL = "https://shared-service.example.com"
  }
  "app2" = {
    SHARED_SERVICE_URL = "https://shared-service.example.com"
  }
}
```

### External Secret References
Reference existing secrets by ARN:
```hcl
apps = {
  "my-app" = {
    secrets = {
      EXTERNAL_DB_PASSWORD = "arn:aws:secretsmanager:us-east-1:123456789012:secret:external-db-password"
    }
  }
}
```

### Environment-Specific Configuration
Use different terraform.tfvars files for different environments:
- `environments/dev/terraform.tfvars`
- `environments/staging/terraform.tfvars`
- `environments/prod/terraform.tfvars`

## Monitoring and Alerts

### CloudWatch Metrics
- Monitor secret access patterns
- Set up alerts for failed secret retrievals
- Track parameter access frequency

### Security Monitoring
- Monitor IAM role usage
- Set up alerts for unauthorized access attempts
- Review access logs regularly

## Cost Optimization

### AWS Secrets Manager
- **Cost**: $0.40 per secret per month + $0.05 per 10,000 API calls
- **Optimization**: Combine multiple secrets into single JSON secret when appropriate

### AWS Systems Manager Parameter Store
- **Standard Parameters**: Free
- **Advanced Parameters**: $0.05 per advanced parameter per month
- **API Calls**: $0.05 per 10,000 API calls

### Recommendations
1. Use Parameter Store for non-sensitive, frequently accessed data
2. Use Secrets Manager for sensitive data that needs rotation
3. Cache parameters in application when possible to reduce API calls

# GitHub Repository Module

A reusable Terraform module for creating and managing GitHub repositories with comprehensive configuration options.

## Features

- ✅ Repository creation with customizable settings
- ✅ Branch protection rules
- ✅ Deploy key management
- ✅ Repository file creation
- ✅ Comprehensive security settings
- ✅ Flexible merge and review policies

## Usage

### Basic Repository

```terraform
module "my_repo" {
  source = "./modules/github"

  repository_name        = "my-awesome-repo"
  repository_description = "An awesome repository"
  repository_visibility  = "private"
  
  topics = ["terraform", "automation"]
}
```

### Frontend Repository for Amplify

```terraform
module "frontend_repo" {
  source = "./modules/github"

  repository_name        = "my-frontend-app"
  repository_description = "Frontend application deployed with AWS Amplify"
  repository_visibility  = "private"
  
  # Frontend-specific settings
  auto_init          = true
  gitignore_template = "Node"
  license_template   = "mit"
  
  topics = ["frontend", "react", "amplify", "aws"]
  
  # Branch protection for production
  enable_branch_protection         = true
  required_status_checks          = ["ci/build", "ci/test"]
  required_approving_review_count = 1
  require_conversation_resolution = true
  
  # Create initial files
  repository_files = {
    "README.md" = {
      content = "# My Frontend App\n\nA React application deployed with AWS Amplify."
      branch  = "main"
    }
    ".nvmrc" = {
      content = "18.17.0"
      branch  = "main"
    }
  }
}
```

### Repository with Deploy Keys

```terraform
module "deployment_repo" {
  source = "./modules/github"

  repository_name = "deployment-repo"
  
  deploy_keys = {
    "ci-deploy" = {
      title     = "CI/CD Deploy Key"
      key       = "ssh-rsa AAAAB3NzaC1yc2E..."
      read_only = false
    }
    "monitoring" = {
      title     = "Monitoring Read Key"
      key       = "ssh-rsa AAAAB3NzaC1yc2E..."
      read_only = true
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repository_name | Name of the repository to create | `string` | n/a | yes |
| repository_description | Description for the repository | `string` | `"Repository managed by Terraform"` | no |
| repository_visibility | Visibility of the repository (public or private) | `string` | `"private"` | no |
| auto_init | Whether to auto-initialize the repository with a README | `bool` | `true` | no |
| gitignore_template | Template to use for .gitignore file | `string` | `null` | no |
| license_template | License template to use for the repository | `string` | `null` | no |
| topics | List of topics for the repository | `list(string)` | `[]` | no |
| enable_branch_protection | Whether to enable branch protection rules | `bool` | `false` | no |
| required_status_checks | List of required status checks for branch protection | `list(string)` | `[]` | no |
| required_approving_review_count | Number of required approving reviews | `number` | `1` | no |

See [variables.tf](./variables.tf) for the complete list of available inputs.

## Outputs

| Name | Description |
|------|-------------|
| repository_id | ID of the repository |
| repository_name | Name of the repository |
| repository_full_name | Full name of the repository (owner/repo) |
| repository_url | URL of the repository web page |
| repository_git_clone_url | Git clone URL for the repository |
| repository_ssh_clone_url | SSH clone URL for the repository |
| repository_https_clone_url | HTTPS clone URL for the repository |
| default_branch | Default branch of the repository |
| branch_protection_enabled | Whether branch protection is enabled |

See [outputs.tf](./outputs.tf) for the complete list of available outputs.

## Examples

### Frontend Application Repository

Perfect for React, Vue, Angular, or other frontend applications that will be deployed with AWS Amplify:

```terraform
module "frontend_app" {
  source = "./modules/github"

  repository_name        = "my-react-app"
  repository_description = "React application with AWS Amplify deployment"
  repository_visibility  = "private"
  
  auto_init          = true
  gitignore_template = "Node"
  license_template   = "mit"
  homepage_url       = "https://my-react-app.amplifyapp.com"
  
  topics = ["react", "frontend", "amplify", "aws", "typescript"]
  
  # Enable branch protection for main branch
  enable_branch_protection         = true
  protected_branch                = "main"
  enforce_admins                  = false
  required_status_checks          = ["build", "test", "lint"]
  strict_status_checks            = true
  required_approving_review_count = 1
  require_code_owner_reviews      = false
  dismiss_stale_reviews           = true
  require_conversation_resolution = true
  
  # Repository files
  repository_files = {
    "README.md" = {
      content = file("${path.module}/templates/frontend-readme.md")
      branch  = "main"
    }
    ".nvmrc" = {
      content = "18.17.0"
      branch  = "main"
    }
    "amplify.yml" = {
      content = file("${path.module}/templates/amplify.yml")
      branch  = "main"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| github | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| github | ~> 6.0 |

## Resources

- `github_repository`
- `github_branch_protection`
- `github_repository_deploy_key`
- `github_repository_file`

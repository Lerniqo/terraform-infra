# Multi-Environment Kafka Infrastructure with Terraform

This repository contains Terraform configuration for running Apache Kafka in multiple environments:
- **Development**: Local Docker containers
- **Production**: Docker containers on AWS EC2 instances

## Architecture Overview

### Development Environment (Local)
- **Kafka**: Running in KRaft mode (no Zookeeper required) using Confluent Platform
- **Docker Network**: Dedicated network for Kafka
- **Data Persistence**: Docker volumes for Kafka data

### Production Environment (AWS)
- **EC2 Instances**: 3 EC2 instances running Docker containers with Kafka and Zookeeper
- **VPC**: Dedicated VPC with public/private subnets across 3 AZs
- **Security**: VPC security groups, encrypted EBS volumes, SSH key access
- **Networking**: NAT gateways for internet access from private subnets
- **DNS**: Private Route53 hosted zone for internal service discovery
- **Load Balancer**: Application Load Balancer for external access

### Service Ports

#### Development (Local Docker)
| Service | Internal Port | External Port | Description |
|---------|---------------|---------------|-------------|
| Kafka (Internal) | 9092 | 9092 | Container-to-container communication |
| Kafka (External) | 9094 | 9094 | Host machine access |

#### Production (AWS EC2 + Docker)
| Service | Port | Description |
|---------|------|-------------|
| Kafka (Internal) | 9092 | Inter-broker communication |
| Kafka (External) | 9094 | External client access via ALB |
| Zookeeper | 2181 | Cluster coordination |
| SSH | 22 | Instance management |

## Prerequisites

### Development Environment
- [Docker](https://docs.docker.com/get-docker/) (version 20.10+)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (version 1.6+)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed on macOS/Linux)

### Production Environment
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with permissions for EC2, VPC, Route53, CloudWatch, IAM services
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (version 1.6+)
- SSH key pair for EC2 instance access

## Quick Start

### Development Environment (Local Docker)

#### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd terraform-infra
```

#### 2. Configure Variables (Optional)

Copy the example variables file and modify if needed:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to set environment = "dev" (default)
```

#### 3. Start Kafka

```bash
make dev-apply
# or using generic command
make apply ENV=dev
```

#### 4. Verify Kafka is Running

```bash
make dev-status
```

#### 5. Test Kafka Connection

```bash
# Create a test topic
docker exec kafka-dev-kafka kafka-topics --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# List topics
docker exec kafka-dev-kafka kafka-topics --list --bootstrap-server localhost:9092

# Produce test messages
docker exec -it kafka-dev-kafka kafka-console-producer --topic test-topic --bootstrap-server localhost:9092

# Consume test messages (in another terminal)
docker exec -it kafka-dev-kafka kafka-console-consumer --topic test-topic --bootstrap-server localhost:9092 --from-beginning
```

#### 6. Stop Development Environment

```bash
make dev-destroy
```

### Production Environment (AWS EC2 + Docker)

#### 1. Configure AWS Credentials

```bash
aws configure
# or set environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

#### 2. Generate SSH Key Pair

```bash
# Generate a new SSH key pair if you don't have one
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Add your public key to terraform.prod.tfvars
cat ~/.ssh/id_rsa.pub
```

#### 3. Review Production Configuration

Edit `terraform.prod.tfvars` to customize:
- AWS region
- VPC CIDR block
- EC2 instance type
- Kafka version
- SSH public key
- Tags

#### 4. Deploy Production Environment

```bash
make prod-plan    # Review changes
make prod-apply   # Deploy to AWS
```

#### 5. Get Connection Information

```bash
terraform output -var-file="terraform.prod.tfvars" aws_bootstrap_servers
terraform output -var-file="terraform.prod.tfvars" load_balancer_dns
```

#### 6. SSH to Kafka Instances

```bash
# Get instance IPs
terraform output -var-file="terraform.prod.tfvars" kafka_private_ips

# SSH via bastion or direct access if in VPC
ssh -i ~/.ssh/id_rsa ec2-user@<instance-ip>
```

#### 7. Stop Production Environment

```bash
make prod-destroy  # This will delete all AWS resources
```

## Available Commands

### Environment-Specific Commands

| Command | Description |
|---------|-------------|
| `make dev-init` | Initialize Terraform for development |
| `make dev-plan` | Plan development environment changes |
| `make dev-apply` | Deploy development environment |
| `make dev-destroy` | Destroy development environment |
| `make dev-status` | Check development environment status |
| `make dev-logs` | View development Kafka logs |
| `make prod-init` | Initialize Terraform for production |
| `make prod-plan` | Plan production environment changes |
| `make prod-apply` | Deploy production environment |
| `make prod-destroy` | Destroy production environment |
| `make prod-status` | Check production environment status |

### Generic Commands

| Command | Description |
|---------|-------------|
| `make init ENV=<env>` | Initialize Terraform for specific environment |
| `make plan ENV=<env>` | Show Terraform execution plan for environment |
| `make apply ENV=<env>` | Apply Terraform changes for environment |
| `make destroy ENV=<env>` | Destroy resources for environment |
| `make up` | Start Kafka (alias for apply) |
| `make down` | Stop Kafka (alias for destroy) |
| `make validate` | Validate Terraform configuration |
| `make fmt` | Format Terraform files |
| `make clean` | Clean up Terraform state and cache files |
| `make help` | Show all available commands |

## Environment Configuration

### Development Environment Variables

The following variables can be configured in `terraform.dev.tfvars`:

```hcl
environment  = "dev"
project_name = "kafka"

kafka_ports = {
  external = 9094
  internal = 9092
}

docker_host = "unix:///Users/username/.docker/run/docker.sock"

common_tags = {
  Project     = "kafka"
  Environment = "dev"
  Owner       = "development-team"
}
```

### Production Environment Variables

The following variables can be configured in `terraform.prod.tfvars`:

```hcl
environment  = "prod"
project_name = "kafka"

# AWS configuration
aws_region = "us-west-2"
vpc_cidr   = "10.0.0.0/16"

# Kafka configuration (Docker-based)
kafka_version = "7.4.0"
instance_type = "t3.medium"  # Use larger instances for production

# SSH access (replace with your actual public key)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAA... your-public-key-here"

common_tags = {
  Project     = "kafka"
  Environment = "prod"
  Owner       = "platform-team"
  CostCenter  = "engineering"
}
```

## Kafka Infrastructure with Terraform

This Terraform project deploys Apache Kafka in KRaft mode (without ZooKeeper) on AWS in production mode using Docker inside an EC2 instance.

## Architecture Overview

### Production Environment (AWS)

- **VPC**: Dedicated VPC (10.10.0.0/16) with public subnet (10.10.1.0/24)
- **Networking**: Internet Gateway, Route Table for public access
- **Security**: Security Group with restrictive access from trusted IPs only
- **Compute**: EC2 instance (t3.medium) with Amazon Linux 2023 AMI
- **Storage**: 50 GiB encrypted root EBS volume
- **Kafka**: Bitnami Kafka 3.7.0 in KRaft mode via Docker Compose

### Security Features

- **SSH Access**: Only from configured trusted CIDR blocks
- **Kafka External Access**: Port 9094 only from trusted IPs
- **Egress**: Open to 0.0.0.0/0 for Docker pulls and updates
- **Encryption**: EBS volumes encrypted at rest
- **IAM**: Least privilege IAM roles for CloudWatch and SSM

### Kafka Configuration

- **Mode**: KRaft (no ZooKeeper dependency)
- **Listeners**:
  - PLAINTEXT (9092): Internal container communication
  - CONTROLLER (9093): KRaft controller protocol
  - EXTERNAL (9094): External client connections via public IP
- **Data Persistence**: `/data/kafka` on host filesystem
- **Management**: Helper scripts for topic creation and cluster management

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured or environment variables set
4. **Trusted IP addresses** for secure access

## Quick Start

### 1. Configure Variables

Edit `terraform.prod.tfvars` and set your trusted IP addresses:

```hcl
trusted_cidr_blocks = [
  "YOUR_OFFICE_CIDR/24",     # Replace with your office network
  "YOUR_VPN_IP/32",          # Replace with your VPN exit IP
]
```

Optionally, configure an SSH key pair:

```hcl
ssh_key_name = "your-aws-key-pair"
```

### 2. Set AWS Credentials

**Option A: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-south-1"
```

**Option B: AWS CLI Profile**
```bash
aws configure
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.prod.tfvars"

# Apply changes
terraform apply -var-file="terraform.prod.tfvars"
```

### 4. Get Connection Information

After deployment, Terraform will output:

```bash
kafka_bootstrap_servers_prod = "1.2.3.4:9094"
kafka_public_ip = "1.2.3.4"
ssh_command = "ssh -i ~/.ssh/your-key.pem ec2-user@1.2.3.4"
```

## Usage

### Connecting to Kafka

**External Connection (from your local machine):**
```bash
# Use the public IP and port 9094
kafka-console-producer.sh --bootstrap-server PUBLIC_IP:9094 --topic test-topic
kafka-console-consumer.sh --bootstrap-server PUBLIC_IP:9094 --topic test-topic --from-beginning
```

**SSH into Instance:**
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@PUBLIC_IP
```

### Helper Scripts (on EC2 instance)

**Create a new topic:**
```bash
kafka-topic-create my-topic 6 1
```

**Check Kafka status:**
```bash
kafka-status
```

**Restart Kafka:**
```bash
kafka-restart
```

**Show cluster information:**
```bash
kafka-info
```

### Docker Commands (on EC2 instance)

**View Kafka logs:**
```bash
docker logs kafka-kraft -f
```

**Access Kafka container:**
```bash
docker exec -it kafka-kraft bash
```

**Restart Kafka container:**
```bash
cd /opt/kafka
docker-compose restart kafka
```

## Configuration Files

### Directory Structure

```
terraform-infra/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── providers.tf               # Provider configurations
├── versions.tf                # Version constraints
├── terraform.prod.tfvars      # Production environment config
├── modules/
│   ├── aws/
│   │   ├── main.tf           # AWS infrastructure
│   │   ├── variables.tf      # AWS module variables
│   │   ├── outputs.tf        # AWS module outputs
│   │   └── user_data.sh      # EC2 bootstrap script
│   └── local/                # Local development module
└── README.md
```

### Key Configuration Files

**Kafka Docker Compose** (`/opt/kafka/docker-compose.yml` on EC2):
- Bitnami Kafka image with KRaft mode
- Proper listener configuration for internal/external access
- Volume mounting for data persistence
- Health checks and restart policies

**Bootstrap Script** (`modules/aws/user_data.sh`):
- System updates and Docker installation
- Docker Compose v2 setup
- Kafka configuration deployment
- Helper script creation
- Systemd service setup

## Monitoring and Troubleshooting

### Health Checks

**Instance Health:**
```bash
# Check if instance is running
aws ec2 describe-instances --instance-ids INSTANCE_ID

# Check system logs
sudo journalctl -u kafka.service -f
```

**Kafka Health:**
```bash
# On the EC2 instance
kafka-status

# Check if topics can be listed
docker exec kafka-kraft kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Common Issues

1. **Cannot connect from external IP:**
   - Verify your IP is in `trusted_cidr_blocks`
   - Check security group rules
   - Ensure Kafka is listening on the external interface

2. **Kafka fails to start:**
   - Check Docker logs: `docker logs kafka-kraft`
   - Verify data directory permissions: `ls -la /data/kafka`
   - Check disk space: `df -h`

3. **Bootstrap script errors:**
   - Check cloud-init logs: `sudo cat /var/log/cloud-init-output.log`
   - Review setup logs: `sudo cat /var/log/kafka-setup.log`

## Security Considerations

### Network Security

- **Restricted Access**: Only trusted IPs can access SSH (22) and Kafka (9094)
- **No Default Routes**: No 0.0.0.0/0 access except for egress
- **VPC Isolation**: Dedicated VPC with controlled routing

### Data Security

- **Encryption at Rest**: EBS volumes encrypted
- **Encryption in Transit**: Configure TLS for production (requires additional setup)
- **Access Control**: IAM roles with minimal required permissions

### Operational Security

- **Regular Updates**: Use latest AMIs and Docker images
- **Log Monitoring**: CloudWatch integration via IAM roles
- **Session Manager**: Alternative to SSH key access

## Maintenance

### Updates

**Update Kafka version:**
1. Modify `kafka_version` in `terraform.prod.tfvars`
2. Run `terraform apply -var-file="terraform.prod.tfvars"`
3. Instance will be recreated with new version

**Update infrastructure:**
```bash
terraform plan -var-file="terraform.prod.tfvars"
terraform apply -var-file="terraform.prod.tfvars"
```

### Backup and Recovery

**Data Backup:**
- Kafka data is stored in `/data/kafka`
- Consider EBS snapshots for backup
- Implement topic-level backup strategies

**Configuration Backup:**
- Store Terraform state securely
- Version control all configuration files
- Document any manual configuration changes

## Cost Optimization

### Instance Sizing

- **t3.medium**: Good for development and small production workloads
- **t3.large/xlarge**: Consider for higher throughput requirements
- **m5/c5 instances**: For consistent performance needs

### Storage

- **gp3 volumes**: Cost-effective with configurable IOPS
- **Monitor usage**: Use CloudWatch to track actual usage
- **Lifecycle management**: Set up log retention policies

## Development Workflow

### Local Development

The project supports local development using the `local` module:

```bash
terraform apply -var="environment=dev" -var-file="terraform.dev.tfvars"
```

### CI/CD Integration

**Example GitHub Actions workflow:**
```yaml
name: Deploy Kafka Infrastructure
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Apply
        run: |
          terraform init
          terraform apply -auto-approve -var-file="terraform.prod.tfvars"
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Support and Contributing

### Getting Help

1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Examine Terraform state and plan output
4. Consult Kafka documentation for application-specific issues

### Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes in development environment
4. Submit pull request with detailed description

## License

This project is provided as-is for educational and production use. Ensure compliance with your organization's policies and AWS terms of service.

## Environment-Specific Features

### Development Environment (Local Docker)
- **KRaft Mode**: No Zookeeper required
- **Auto-topic Creation**: Enabled for development ease
- **Data Persistence**: Docker volumes for data retention
- **Single Node**: Suitable for development and testing
- **Port Mapping**: Host machine access via localhost:9094

### Production Environment (AWS EC2 + Docker)
- **Multi-Instance Deployment**: 3 EC2 instances across availability zones
- **Docker Containerization**: Kafka and Zookeeper running in Docker containers
- **Service Discovery**: Private Route53 hosted zone for internal DNS
- **Security**: VPC isolation, security groups, encrypted EBS volumes
- **Load Balancer**: Application Load Balancer for external access
- **Monitoring**: CloudWatch integration for logs and metrics
- **High Availability**: Data replication across multiple instances

## Kafka Configuration

### Development (KRaft Mode)
- **Node ID**: 1
- **Cluster ID**: MkU3OEVBNTcwNTJENDM2Qk
- **Auto-create topics**: Enabled
- **Replication Factor**: 1 (single-node development)
- **Data Persistence**: Docker volume for data retention

### Production (AWS EC2 + Docker)
- **Broker Nodes**: 3 (across multiple AZs)
- **Auto-create topics**: Enabled
- **Replication Factor**: 3 (high availability)
- **Storage**: 100GB EBS per instance
- **Encryption**: EBS encryption at rest
- **Docker Images**: Confluent Platform containers

## Accessing Kafka

### Development Environment
- **Host Machine**: `localhost:9094`
- **Docker Containers**: `kafka:9092`

### Production Environment
- **Applications**: Use bootstrap brokers from Terraform output
- **Internal Access**: kafka-1.kafka-prod.internal:9092, kafka-2.kafka-prod.internal:9092, kafka-3.kafka-prod.internal:9092
- **External Access**: Via Application Load Balancer DNS
- **VPC Access**: Deploy applications in same VPC or configure VPC peering

## Cost Optimization (Production)

To minimize AWS costs for production:

1. **Instance Types**: Start with `t3.medium`, scale up as needed based on load
2. **Storage**: Monitor usage and adjust EBS volume sizes
3. **Auto Scaling**: Consider implementing auto scaling for variable workloads
4. **Monitoring**: Use CloudWatch to track usage and optimize resources
5. **Environment Management**: Destroy non-production environments when not in use

## Security Best Practices

### Development
- Use local development only for trusted applications
- Don't expose Docker ports beyond localhost

### Production
- **Network Security**: Private subnets, security groups, NACLs
- **Instance Security**: SSH key-based access, security groups
- **Data Encryption**: EBS volume encryption at rest
- **Access Control**: IAM roles and policies for EC2 instances
- **Monitoring**: CloudWatch logs and metrics
- **VPC Flow Logs**: Monitor network traffic

## Troubleshooting

### Development Environment

**Container Issues:**

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using the port
   lsof -i :9094
   
   # Modify ports in terraform.tfvars if needed
   ```

2. **Container not starting**
   ```bash
   # Check container logs
   make kafka-logs
   
   # Check container status
   docker ps -a --filter "name=kafka"
   ```

3. **Permission issues**
   ```bash
   # Ensure Docker daemon is running
   docker info
   ```

### Cleanup

To completely remove all Kafka data and containers:

```bash
# Stop and remove containers
make down

# Remove Docker volumes (WARNING: This will delete all Kafka data)
docker volume rm kafka-local-kafka-data

# Clean Terraform state
make clean
```

### Connection Details
- **Bootstrap Servers**: `localhost:9094` (for external clients)
- **Internal Communication**: `kafka:9092` (container-to-container)
- **Protocol**: PLAINTEXT (suitable for local development)

### Example Client Configuration
## Application Integration Examples

**Java/Spring Boot:**
```properties
spring.kafka.bootstrap-servers=localhost:9094
```

**Python (kafka-python):**
```python
from kafka import KafkaProducer, KafkaConsumer

producer = KafkaProducer(bootstrap_servers=['localhost:9094'])
consumer = KafkaConsumer('my-topic', bootstrap_servers=['localhost:9094'])
```

**Node.js (kafkajs):**
```javascript
// Development configuration
const { Kafka } = require('kafkajs')

const kafka = Kafka({
  clientId: 'my-app',
  brokers: ['localhost:9094']
})
```

### Production Environment

**Java/Spring Boot:**
```properties
# application-prod.properties
spring.kafka.bootstrap-servers=${MSK_BOOTSTRAP_SERVERS}
spring.kafka.security.protocol=SSL
spring.kafka.ssl.trust-store-location=${TRUST_STORE_PATH}
spring.kafka.ssl.trust-store-password=${TRUST_STORE_PASSWORD}
```

**Python (kafka-python):**
```python
from kafka import KafkaProducer

# Production configuration
bootstrap_servers = [
    'kafka-1.kafka-prod.internal:9092',
    'kafka-2.kafka-prod.internal:9092', 
    'kafka-3.kafka-prod.internal:9092'
]

producer = KafkaProducer(bootstrap_servers=bootstrap_servers)
```

**Node.js (kafkajs):**
```javascript
// Production configuration
const { Kafka } = require('kafkajs')

const kafka = Kafka({
  clientId: 'my-app',
  brokers: [
    'kafka-1.kafka-prod.internal:9092',
    'kafka-2.kafka-prod.internal:9092',
    'kafka-3.kafka-prod.internal:9092'
  ]
})
```

## Data Persistence

### Development Environment
- **Docker Volume**: `kafka-dev-kafka-data` for data persistence
- **Behavior**: Data persists between container restarts
- **Cleanup**: Data removed when running `make dev-destroy`

### Production Environment
- **EBS Storage**: 100GB per broker node
- **Replication**: Data replicated across 3 broker nodes
- **Backup**: Automated EBS snapshots (configure separately)

## Migration from Development to Production

1. **Update Configuration**: Change bootstrap servers from localhost to internal DNS names or ALB endpoint
2. **Network Access**: Ensure applications can reach EC2 instances in VPC 
3. **Security Setup**: Configure security groups and VPC access
4. **Monitoring**: Set up CloudWatch dashboards and alerts
5. **Testing**: Verify connectivity and performance in staging first

## Best Practices

### Development
- Use environment-specific variable files
- Keep sensitive data out of version control
- Test configuration changes locally first
- Use `make validate` before applying changes

### Production
- Use separate AWS accounts for environments
- Implement proper IAM roles and policies
- Enable CloudWatch monitoring and alerting
- Regular backup and disaster recovery testing
- Use Terraform state locking and remote state

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes following Terraform best practices
4. Test both development and production environments
5. Update documentation if needed
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Terraform and AWS documentation
3. Open an issue in this repository

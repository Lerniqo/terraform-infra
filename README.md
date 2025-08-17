# Kafka Local Development with Terraform

This repository contains Terraform configuration for running Apache Kafka locally using Docker containers. It provides a simple, reproducible way to set up Kafka for local development.

## Architecture Overview

### Local Development Setup
- **Kafka**: Running in KRaft mode (no Zookeeper required) using Confluent Platform
- **Docker Network**: Dedicated network for Kafka
- **Data Persistence**: Docker volumes for Kafka data

### Service Ports

| Service | Internal Port | External Port | Description |
|---------|---------------|---------------|-------------|
| Kafka (Internal) | 9092 | 9092 | Container-to-container communication |
| Kafka (External) | 9094 | 9094 | Host machine access |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (version 20.10+)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (version 1.6+)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed on macOS/Linux)

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd terraform-infra
```

### 2. Configure Variables (Optional)

Copy the example variables file and modify if needed:

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Start Kafka

```bash
make up
```

### 4. Verify Kafka is Running

```bash
# Create a test topic
docker exec kafka-local-kafka kafka-topics --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# List topics
docker exec kafka-local-kafka kafka-topics --list --bootstrap-server localhost:9092

# Produce test messages
docker exec -it kafka-local-kafka kafka-console-producer --topic test-topic --bootstrap-server localhost:9092

# Consume test messages (in another terminal)
docker exec -it kafka-local-kafka kafka-console-consumer --topic test-topic --bootstrap-server localhost:9092 --from-beginning
```

### 6. Stop Kafka

```bash
make down
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make up` | Start Kafka (initialize and apply Terraform) |
| `make down` | Stop Kafka (destroy Terraform resources) |
| `make init` | Initialize Terraform |
| `make plan` | Show Terraform execution plan |
| `make apply` | Apply Terraform changes |
| `make destroy` | Destroy Terraform-managed resources |
| `make validate` | Validate Terraform configuration |
| `make fmt` | Format Terraform files |
| `make kafka-status` | Show Kafka container status |
| `make kafka-logs` | Show Kafka container logs |
| `make clean` | Clean up Terraform state and cache files |

## Configuration

### Variables

The following variables can be configured in `terraform.tfvars`:

```hcl
project_name = "kafka-local"

kafka_ports = {
  external = 9094
  internal = 9092
}

# Optional: Override Docker host if needed
# docker_host = "unix:///var/run/docker.sock"
```

## Project Structure

```
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── providers.tf               # Provider configurations
├── outputs.tf                 # Output definitions
├── versions.tf                # Terraform and provider version constraints
├── terraform.tfvars.example  # Example variables file
├── Makefile                   # Automation commands
├── .gitignore                 # Git ignore patterns
└── modules/
    └── local/                 # Local Docker-based Kafka infrastructure
        ├── main.tf            # Docker containers and networks
        ├── variables.tf       # Module variables
        └── outputs.tf         # Module outputs
```

## Kafka Configuration

### KRaft Mode (No Zookeeper)
This setup uses Kafka in KRaft mode, which eliminates the need for Zookeeper. Benefits include:
- Simplified architecture
- Reduced operational overhead
- Better performance and scalability
- Official recommendation for new deployments

### Default Configuration
- **Node ID**: 1
- **Cluster ID**: MkU3OEVBNTcwNTJENDM2Qk
- **Auto-create topics**: Enabled
- **Replication Factor**: 1 (suitable for single-node development)
- **Data Persistence**: Docker volume for data retention across container restarts

## Accessing Kafka

### From Host Machine
Connect to Kafka from your host machine using:
```
localhost:9094
```

### From Other Docker Containers
If you have other containers that need to connect to Kafka, use:
```
kafka:9092
```

## Troubleshooting

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
const kafka = require('kafkajs');

const client = kafka({
  clientId: 'my-app',
  brokers: ['localhost:9094']
});
```

## Data Persistence

Kafka uses a Docker volume (`kafka-local-kafka-data`) for data persistence. Data persists between container restarts but is removed when running `make down`.

## Security Considerations

### Development Environment
- Uses PLAINTEXT Kafka protocol (no encryption)
- All services exposed on localhost only
- Suitable for local development only

### Production Considerations
For production use, consider:
- TLS/SSL encryption
- SASL authentication
- Network isolation
- Proper secrets management

## Contributing

1. Make changes to the Terraform configuration
2. Test locally with `make up`
3. Update documentation if needed
4. Submit a pull request

---

**Note**: This setup is optimized for local development. For production use, additional security, monitoring, and backup configurations will be required.

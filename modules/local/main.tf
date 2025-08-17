# Terraform configuration for local Kafka development environment
# Uses Docker container for Kafka in KRaft mode (no Zookeeper required)

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Create a dedicated Docker network for Kafka
resource "docker_network" "kafka_network" {
  name   = "${var.project}-kafka-network"
  driver = "bridge"
}

# Docker volume for Kafka data persistence
resource "docker_volume" "kafka_data" {
  name = "${var.project}-kafka-data"
}

# Kafka Docker image
resource "docker_image" "kafka" {
  name         = "confluentinc/cp-kafka:7.5.0"
  keep_locally = true
}

# Kafka in KRaft mode (no Zookeeper required)
resource "docker_container" "kafka" {
  name    = "${var.project}-kafka"
  image   = docker_image.kafka.image_id
  restart = "unless-stopped"

  networks_advanced {
    name    = docker_network.kafka_network.name
    aliases = ["kafka"]
  }

  ports {
    internal = 9092
    external = var.ports.internal
  }

  ports {
    internal = 9094
    external = var.ports.external
  }

  # Run as root to avoid permission issues with Docker volumes
  user = "root"

  env = [
    "KAFKA_NODE_ID=1",
    "KAFKA_PROCESS_ROLES=broker,controller",
    "KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:29093",
    "KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:29093,EXTERNAL://0.0.0.0:9094",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,EXTERNAL://localhost:${var.ports.external}",
    "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT",
    "KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT",
    "KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER",
    "KAFKA_LOG_DIRS=/var/lib/kafka/data",
    "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1",
    "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1",
    "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1",
    "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0",
    "KAFKA_AUTO_CREATE_TOPICS_ENABLE=true",
    "CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk"
  ]

  mounts {
    target = "/var/lib/kafka/data"
    source = docker_volume.kafka_data.name
    type   = "volume"
  }

  # Health check
  healthcheck {
    test         = ["CMD", "kafka-topics", "--bootstrap-server", "localhost:9092", "--list"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "60s"
  }
}

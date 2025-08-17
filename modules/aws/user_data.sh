#!/bin/bash
set -e

# Variables
KAFKA_VERSION="${kafka_version}"
PROJECT="${project}"
ENVIRONMENT="${environment}"
KAFKA_DATA_DIR="/data/kafka"
COMPOSE_DIR="/opt/kafka"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/kafka-setup.log
}

log "Starting Kafka setup for $${PROJECT}-$${ENVIRONMENT}"

# Update and install Docker
log "Installing Docker"
dnf update -y
dnf install -y docker

# Configure and start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Configure Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {"max-size": "100m", "max-file": "3"},
  "live-restore": true,
  "storage-driver": "overlay2"
}
EOF
systemctl restart docker

# Install Docker Compose
COMPOSE_VERSION="v2.24.5"
curl -L "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create directories
mkdir -p $${KAFKA_DATA_DIR} $${COMPOSE_DIR}
chown -R 1001:1001 $${KAFKA_DATA_DIR}
chown -R ec2-user:ec2-user $${COMPOSE_DIR}

# Get public IP
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

# Create Docker Compose file
cat > $${COMPOSE_DIR}/docker-compose.yml << EOF
version: '3.8'
services:
  kafka:
    image: bitnami/kafka:${kafka_version}
    container_name: kafka-kraft
    hostname: kafka-kraft
    restart: unless-stopped
    ports:
      - "9092:9092"
      - "9093:9093"
      - "9094:9094"
    volumes:
      - $${KAFKA_DATA_DIR}:/bitnami/kafka
    environment:
      KAFKA_CFG_NODE_ID: 1
      KAFKA_CFG_PROCESS_ROLES: controller,broker
      KAFKA_CFG_CONTROLLER_QUORUM_VOTERS: 1@kafka-kraft:9093
      KAFKA_CFG_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://:9094
      KAFKA_CFG_ADVERTISED_LISTENERS: PLAINTEXT://kafka-kraft:9092,EXTERNAL://$${PUBLIC_IP}:9094
      KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_CFG_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CFG_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE: false
      KAFKA_CFG_LOG_RETENTION_HOURS: 168
      KAFKA_CFG_LOG_RETENTION_BYTES: 1073741824
      KAFKA_CFG_NUM_PARTITIONS: 3
      KAFKA_CFG_DEFAULT_REPLICATION_FACTOR: 1
      KAFKA_CFG_MIN_INSYNC_REPLICAS: 1
      KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_CFG_GROUP_INITIAL_REBALANCE_DELAY_MS: 3000
      KAFKA_HEAP_OPTS: "-Xmx512M -Xms512M"
      KAFKA_JVM_PERFORMANCE_OPTS: "-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:+UseContainerSupport"
    networks:
      - kafka-network
    healthcheck:
      test: ["CMD-SHELL", "kafka-topics.sh --bootstrap-server localhost:9092 --list > /dev/null 2>&1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

networks:
  kafka-network:
    driver: bridge
EOF

# Create helper scripts
cat > /usr/local/bin/kafka-topic-create << 'EOF'
#!/bin/bash
TOPIC=$1; PART=$${2:-3}; REPL=$${3:-1}
[ -z "$TOPIC" ] && echo "Usage: kafka-topic-create <topic> [partitions] [replication]" && exit 1
docker exec kafka-kraft kafka-topics.sh --create --bootstrap-server localhost:9092 --topic "$TOPIC" --partitions "$PART" --replication-factor "$REPL"
EOF

cat > /usr/local/bin/kafka-status << 'EOF'
#!/bin/bash
echo "=== Container Status ==="; docker ps | grep kafka
echo "=== Topics ==="; docker exec kafka-kraft kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "Not ready"
echo "=== Recent Logs ==="; docker logs kafka-kraft --tail 10
EOF

cat > /usr/local/bin/kafka-restart << 'EOF'
#!/bin/bash
echo "Restarting Kafka..."; systemctl restart kafka.service; sleep 30; echo "Done. Check: kafka-status"
EOF

chmod +x /usr/local/bin/kafka-*

# Create systemd service
cat > /etc/systemd/system/kafka.service << EOF
[Unit]
Description=Kafka KRaft Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$${COMPOSE_DIR}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=300
User=root
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start services
systemctl daemon-reload
systemctl enable kafka.service
systemctl start kafka.service

# Wait and verify
sleep 60
if systemctl is-active --quiet kafka.service && docker ps | grep -q kafka-kraft; then
    log "✓ Kafka is running and ready"
    # Create test topic
    docker exec kafka-kraft kafka-topics.sh --create --bootstrap-server localhost:9092 --topic test-topic --partitions 3 --replication-factor 1 2>/dev/null || true
else
    log "✗ Kafka startup may have failed - check logs"
fi

# Create MOTD
cat > /etc/motd << EOF

=== Kafka KRaft Cluster ($${PROJECT}-$${ENVIRONMENT}) ===
Instance IP: $${PUBLIC_IP}
Bootstrap Servers: $${PUBLIC_IP}:9094

Commands: kafka-status, kafka-restart, kafka-topic-create
Config: $${COMPOSE_DIR}/docker-compose.yml
Data: $${KAFKA_DATA_DIR}

EOF

log "Setup completed at $(date)"

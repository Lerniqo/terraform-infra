output "kafka_public_ip" {
  description = "Public IP address of the Kafka EC2 instance"
  value       = aws_instance.kafka.public_ip
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap server connection string"
  value       = "${aws_instance.kafka.public_ip}:9094"
}

output "ssh_command" {
  description = "SSH command to connect to the Kafka instance"
  value       = var.ssh_key_name != null ? "ssh -i ~/.ssh/${var.ssh_key_name}.pem ec2-user@${aws_instance.kafka.public_ip}" : "SSH key not configured. Use Session Manager or configure a key pair."
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the Kafka security group"
  value       = aws_security_group.kafka.id
}

output "instance_id" {
  description = "ID of the Kafka EC2 instance"
  value       = aws_instance.kafka.id
}

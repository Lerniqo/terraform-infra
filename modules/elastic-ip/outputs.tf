output "elastic_ips" {
  description = "Map of application names to their assigned Elastic IP addresses"
  value = {
    for app_name, eip in aws_eip.app_eip : app_name => eip.public_ip
  }
}

output "elastic_ip_ids" {
  description = "Map of application names to their Elastic IP allocation IDs"
  value = {
    for app_name, eip in aws_eip.app_eip : app_name => eip.id
  }
}

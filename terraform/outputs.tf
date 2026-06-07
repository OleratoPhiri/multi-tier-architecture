output "nlb_dns_name" {
  description = "Load balancer URL — paste this in your browser"
  value       = aws_lb.web.dns_name
}

output "rds_endpoint" {
  description = "RDS database endpoint for application config"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
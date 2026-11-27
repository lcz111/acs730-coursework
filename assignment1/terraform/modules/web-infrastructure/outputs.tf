output "vpc_id" {
  description = "ID of the environment VPC."
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Public subnet IDs keyed by subnet name."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "instance_ids" {
  description = "IDs of the web server instances."
  value       = aws_instance.web[*].id
}

output "web_public_ips" {
  description = "Public IP addresses of the web server instances."
  value       = aws_instance.web[*].public_ip
}

output "web_urls" {
  description = "HTTP URLs of the web server instances."
  value       = [for instance in aws_instance.web : "http://${instance.public_ip}"]
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "artifact_bucket" {
  description = "Name of the optional S3 artifact bucket."
  value       = one(aws_s3_bucket.artifacts[*].bucket)
}

output "environment" {
  description = "Name of the deployment environment."
  value       = var.environment
}

output "ssm_parameter_value" {
  description = "Application configuration read from SSM Parameter Store"
  value       = data.aws_ssm_parameter.app_config.value
  sensitive   = true
}

output "cloudwatch_alarm_name" {
  description = "Name of the CPU utilization alarm when enabled"
  value       = var.enable_cloudwatch_alarm ? aws_cloudwatch_metric_alarm.cpu_high[0].alarm_name : null
}

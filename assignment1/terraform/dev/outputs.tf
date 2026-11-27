output "environment" {
  value = module.web.environment
}

output "vpc_id" {
  value = module.web.vpc_id
}

output "subnet_ids" {
  value = module.web.subnet_ids
}

output "instance_ids" {
  value = module.web.instance_ids
}

output "web_public_ips" {
  value = module.web.web_public_ips
}

output "web_urls" {
  value = module.web.web_urls
}

output "security_group_id" {
  value = module.web.security_group_id
}

output "artifact_bucket" {
  value = module.web.artifact_bucket
}

output "ssm_parameter_value" {
  description = "Application configuration read from SSM Parameter Store"
  value       = module.web.ssm_parameter_value
  sensitive   = true
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch CPU utilization alarm name"
  value       = module.web.cloudwatch_alarm_name
}

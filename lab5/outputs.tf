
output "vpc_id" {
  description = "ID of the lab VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Public subnet IDs keyed by subnet name"
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "web_public_ip" {
  description = "Public IP of the web instance"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL of the web instance"
  value       = "http://${aws_instance.web.public_ip}"
}

output "artifact_bucket" {
  description = "Name of the optional S3 artifact bucket"
  value       = one(aws_s3_bucket.artifacts[*].bucket)
}

output "provider_target" {
  description = "Shows whether Terraform targeted LocalStack or real AWS"
  value       = local.provider_target
}

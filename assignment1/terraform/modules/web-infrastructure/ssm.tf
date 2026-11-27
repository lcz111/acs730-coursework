data "aws_ssm_parameter" "app_config" {
  name = var.ssm_parameter_name
}

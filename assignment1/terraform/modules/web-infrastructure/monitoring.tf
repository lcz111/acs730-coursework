resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_cloudwatch_alarm ? 1 : 0

  alarm_name          = "${local.name}-cpu-high"
  alarm_description   = "EC2 average CPU utilization exceeds 80 percent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "missing"

  dimensions = {
    InstanceId = aws_instance.web[0].id
  }

  tags = local.common_tags
}

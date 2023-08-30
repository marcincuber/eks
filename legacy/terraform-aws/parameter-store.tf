resource "aws_ssm_parameter" "newrelic_key" {
  name  = "/newrelic/${var.tags["Environment"]}/license_key"
  type  = "SecureString"
  value = "default"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

output "ssm_parameter_newrelic_key_name" {
  value = aws_ssm_parameter.newrelic_key.name
}

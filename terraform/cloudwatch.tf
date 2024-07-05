resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  for_each = { for k, v in local.events : k => v }

  name_prefix   = "${var.name_prefix}-"
  description   = each.value.description
  event_pattern = jsonencode(each.value.event_pattern)
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  for_each = { for k, v in local.events : k => v }

  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption[each.key].name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_spot_interruption.arn
}

# CloudWatch Log Groups for container insights
resource "aws_cloudwatch_log_group" "cluster_performance" {
  count = var.eks_addon_version_cloudwatch != null ? 1 : 0

  name = "/aws/containerinsights/${var.name_prefix}/performance"

  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "cluster_application" {
  count = var.eks_addon_version_cloudwatch != null ? 1 : 0

  name = "/aws/containerinsights/${var.name_prefix}/application"

  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "cluster_dataplane" {
  count = var.eks_addon_version_cloudwatch != null ? 1 : 0

  name = "/aws/containerinsights/${var.name_prefix}/dataplane"

  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "cluster_host" {
  count = var.eks_addon_version_cloudwatch != null ? 1 : 0

  name = "/aws/containerinsights/${var.name_prefix}/host"

  retention_in_days = 180
}

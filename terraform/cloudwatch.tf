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

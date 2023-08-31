resource "aws_sqs_queue" "karpenter_spot_interruption" {
  name = "${var.name_prefix}-karpenter-spot-interruption"

  message_retention_seconds = 86400
  receive_wait_time_seconds = 5
  kms_master_key_id         = module.eks_cluster.key_arn
}

resource "aws_sqs_queue_policy" "karpenter_spot_interruption" {
  queue_url = aws_sqs_queue.karpenter_spot_interruption.url
  policy    = data.aws_iam_policy_document.karpenter_spot_interruption.json
}

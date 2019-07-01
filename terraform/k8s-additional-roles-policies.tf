##### Additional IAM roles and policies
# Assumed by external DNS service deployed inside K8s cluster

resource "aws_iam_role" "external_dns" {
  name = "${var.cluster_name}-${var.environment}-external-dns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowToBeAssumedByWorkerNodes",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${aws_iam_role.worker_node.arn}"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_policy" "external_dns_policy" {
  name = "${var.cluster_name}-${var.environment}-external-dns-policy"
  policy = templatefile("policies/external_dns_policy.json", {})
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attach" {
  role = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

#####
# Outputs
#####

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "external_dns_policy_arn" {
  value = aws_iam_policy.external_dns_policy.arn
}


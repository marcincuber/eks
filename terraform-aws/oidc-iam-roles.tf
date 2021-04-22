#####
# Additional IAM roles and policies for service running inside EKS
# All IAM roles in this configuration make use of OIDC provider
#####

# Used by alb_ingress_controller service account

resource "aws_iam_role" "load_balancer_controller" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-load-balancer-controller"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster[0].arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "aws-load-balancer-controller" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "aws-load-balancer-controller"
      "ServiceAccountNameSpace" = "kube-system"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy" "load_balancer_controller" {
  count = var.create_cluster ? 1 : 0

  name = "CustomPolicy"
  role = aws_iam_role.load_balancer_controller[0].id

  policy = data.aws_iam_policy_document.load_balancer_controller.json
}

# Used by cluster_autoscaler service account

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-cluster-autoscaler"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster[0].arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "cluster-autoscaler" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "cluster-autoscaler"
      "ServiceAccountNameSpace" = "kube-system"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  count = var.create_cluster ? 1 : 0

  name = "CustomPolicy"
  role = aws_iam_role.cluster_autoscaler[0].id

  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

# Used by external_secrets service account

resource "aws_iam_role" "external_secrets" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-external-secrets"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster[0].arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", ""), NAMESPACE = "default", SA_NAME = "external-secrets" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "external-secrets"
      "ServiceAccountNameSpace" = "default"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy" "external_secrets" {
  count = var.create_cluster ? 1 : 0

  name = "CustomPolicy"
  role = aws_iam_role.external_secrets[0].id

  policy = data.aws_iam_policy_document.external_secrets.json
}


# Used by external-dns service account

resource "aws_iam_role" "external_dns" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-external-dns"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster[0].arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "external-dns" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "external-dns"
      "ServiceAccountNameSpace" = "kube-system"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy" "external_dns" {
  count = var.create_cluster ? 1 : 0

  name = "CustomPolicy"
  role = aws_iam_role.external_dns[0].id

  policy = data.aws_iam_policy_document.external_dns.json
}

# Used by cloudwatch-agent service account

resource "aws_iam_role" "cloudwatch_agent" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-cloudwatch-agent"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster[0].arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", ""), NAMESPACE = "amazon-cloudwatch", SA_NAME = "cloudwatch-agent" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "cloudwatch-agent"
      "ServiceAccountNameSpace" = "amazon-cloudwatch"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_CloudWatchAgentServerPolicy" {
  count = var.create_cluster ? 1 : 0

  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/CloudWatchAgentServerPolicy" : "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_agent[0].name
}

#####
# Outputs
#####

output "iam_role_arn_load_balancer_controller" {
  value = join("", aws_iam_role.load_balancer_controller.*.arn)
}

output "iam_role_arn_cluster_autoscaler" {
  value = join("", aws_iam_role.cluster_autoscaler.*.arn)
}

output "iam_role_arn_external_secrets" {
  value = join("", aws_iam_role.external_secrets.*.arn)
}

output "iam_role_arn_external_dns" {
  value = join("", aws_iam_role.external_dns.*.arn)
}

output "iam_role_arn_cloudwatch_agent" {
  value = join("", aws_iam_role.cloudwatch_agent.*.arn)
}

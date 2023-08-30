# Used by Load Balancer Controller service account
resource "aws_iam_role" "load_balancer_controller" {
  name = "${var.name_prefix}-load-balancer-controller"

  description = "Allow load-balancer-controller to manage ALBs and NLBs."

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""),
    NAMESPACE = "kube-system",
    SA_NAME   = "aws-load-balancer-controller"
  })

  force_detach_policies = true

  tags = {
    "ServiceAccountName"      = "aws-load-balancer-controller"
    "ServiceAccountNamespace" = "kube-system"
  }
}

resource "aws_iam_role_policy" "load_balancer_controller" {
  name = "CustomPolicy"
  role = aws_iam_role.load_balancer_controller.id

  policy = data.aws_iam_policy_document.load_balancer_controller.json
}

# Used by external-dns service account
resource "aws_iam_role" "external_dns" {
  name = "${var.name_prefix}-external-dns"

  description = "Allow external-dns to upsert DNS records."

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""),
    NAMESPACE = "kube-system",
    SA_NAME   = "external-dns"
  })

  force_detach_policies = true

  tags = {
    "ServiceAccountName"      = "external-dns"
    "ServiceAccountNamespace" = "kube-system"
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name = "CustomPolicy"
  role = aws_iam_role.external_dns.id

  policy = data.aws_iam_policy_document.external_dns.json
}

# Used by cert-manager
resource "aws_iam_role" "cert_manager" {
  name        = "${var.name_prefix}-cert-manager"
  description = "Allow cert-manager to manage DNS records for LetsEncrypt validation purposes."

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""),
    NAMESPACE = "cert-manager",
    SA_NAME   = "cert-manager"
  })

  force_detach_policies = true

  tags = {
    "ServiceAccountName"      = "cert-manager"
    "ServiceAccountNamespace" = "cert-manager"
  }
}

resource "aws_iam_role_policy" "cert_manager" {
  name = "CustomPolicy"
  role = aws_iam_role.cert_manager.id

  policy = data.aws_iam_policy_document.cert_manager.json
}

# Used by karpenter-controller
resource "aws_iam_role" "karpenter_controller" {
  name        = "${var.name_prefix}-karpenter-controller"
  description = "Allow karpenter-controller EC2 read and write operations."

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""),
    NAMESPACE = "karpenter",
    SA_NAME   = "karpenter"
  })

  force_detach_policies = true

  tags = {
    "ServiceAccountName"      = "karpenter"
    "ServiceAccountNamespace" = "karpenter"
  }
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "KarpenterControllerPolicy"
  role = aws_iam_role.karpenter_controller.id

  policy = data.aws_iam_policy_document.karpenter_controller.json
}

# Used by adot-addon
resource "aws_iam_role" "adot_collector" {
  name        = "${var.name_prefix}-adot-collector"
  description = "Allow ADOT to write to Prometheus, X-ray and Cloudwatch."

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""),
    NAMESPACE = "opentelemetry-operator-system",
    SA_NAME   = "adot-collector"
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]

  force_detach_policies = true

  tags = {
    "ServiceAccountName"      = "adot-collector"
    "ServiceAccountNamespace" = "opentelemetry-operator-system"
  }
}

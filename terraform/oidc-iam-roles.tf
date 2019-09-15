#####
# Additional IAM roles and policies for service running inside EKS
# All IAM roles in this configuration make use of OIDC provider
#####

# Used by aws-node service account

resource "aws_iam_role" "aws_node" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-aws-node"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster.arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "aws-node" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "aws-node"
      "ServiceAccountNameSpace" = "kube-system"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy_attachment" "aws_node" {
  role       = aws_iam_role.aws_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  depends_on = [aws_iam_role.aws_node]
}

# Used by alb_ingress_controller service account

resource "aws_iam_role" "alb_ingress_controller" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-alb-ingress-controller"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster.arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "alb-ingress-controller" })

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "alb-ingress-controller"
      "ServiceAccountNameSpace" = "kube-system"
    }
  )

  depends_on = [aws_iam_openid_connect_provider.cluster]
}

resource "aws_iam_role_policy" "alb_ingress_controller" {
  name = "CustomPolicy"
  role = aws_iam_role.alb_ingress_controller.id

  policy = templatefile("policies/alb_ingress_controller_policy.json", {})

  depends_on = [
    aws_iam_role.alb_ingress_controller
  ]
}

# Used by cluster_autoscaler service account

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-cluster-autoscaler"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster.arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "cluster-autoscaler" })

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
  name = "CustomPolicy"
  role = aws_iam_role.cluster_autoscaler.id

  policy = templatefile("policies/cluster_autoscaler_policy.json", {})

  depends_on = [
    aws_iam_role.cluster_autoscaler
  ]
}

# Used by external_secrets service account

resource "aws_iam_role" "external_secrets" {
  name = "${var.tags["ServiceType"]}-${var.tags["Environment"]}-external-secrets"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster.arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""), NAMESPACE = "default", SA_NAME = "external-secrets" })

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
  name = "CustomPolicy"
  role = aws_iam_role.external_secrets.id

  policy = templatefile("policies/external_secrets_policy.json", {})

  depends_on = [
    aws_iam_role.external_secrets
  ]
}



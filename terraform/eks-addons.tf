locals {
  core_dns_config = file("${path.module}/configs/core-dns.json")
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.eks_addon_version_kube_proxy != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "kube-proxy"
  addon_version = var.eks_addon_version_kube_proxy

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  preserve = true

  tags = {
    "eks_addon" = "kube-proxy"
  }
}

resource "aws_eks_addon" "core_dns" {
  count = var.eks_addon_version_core_dns != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "coredns"
  addon_version = var.eks_addon_version_core_dns

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = local.core_dns_config

  preserve = true

  tags = {
    "eks_addon" = "coredns"
  }
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count = var.eks_addon_version_ebs_csi_driver != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = var.eks_addon_version_ebs_csi_driver

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  service_account_role_arn = aws_iam_role.ebs_csi_controller_sa.arn

  preserve = true

  tags = {
    "eks_addon" = "aws-ebs-csi-driver"
  }
}

resource "aws_iam_role" "ebs_csi_controller_sa" {
  name = "ebs-csi-controller-sa"

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster.arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""),
    NAMESPACE = "kube-system",
    SA_NAME   = "ebs-csi-controller-sa"
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
}

resource "aws_eks_addon" "kubecost" {
  count = var.eks_addon_version_kubecost != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "kubecost_kubecost"
  addon_version = var.eks_addon_version_kubecost

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  preserve = true

  tags = {
    "eks_addon" = "kubecost"
  }
}

resource "aws_eks_addon" "guardduty" {
  count = var.eks_addon_version_guardduty != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "aws-guardduty-agent"
  addon_version = var.eks_addon_version_guardduty

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  preserve = true

  tags = {
    "eks_addon" = "guardduty"
  }
}

resource "aws_eks_addon" "adot" {
  count = var.eks_addon_version_adot != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "adot"
  addon_version = var.eks_addon_version_adot

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  service_account_role_arn = aws_iam_role.adot_collector.arn

  preserve = true

  tags = {
    "eks_addon" = "adot"
  }
}

resource "aws_eks_addon" "cloudwatch" {
  count = var.eks_addon_version_cloudwatch != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = var.eks_addon_version_cloudwatch

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  preserve = true

  tags = {
    "eks_addon" = "amazon-cloudwatch-observability"
  }
}

resource "aws_eks_addon" "snapshot_controller" {
  count = var.eks_addon_version_snapshot_controller != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "snapshot-controller"
  addon_version = var.eks_addon_version_snapshot_controller

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  preserve = true

  tags = {
    "eks_addon" = "snapshot-controller"
  }
}

resource "aws_eks_addon" "identity_agent" {
  count = var.eks_addon_version_identity_agent != null ? 1 : 0

  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = var.eks_addon_version_identity_agent

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  preserve = true

  tags = {
    "eks_addon" = "eks-pod-identity-agent"
  }
}

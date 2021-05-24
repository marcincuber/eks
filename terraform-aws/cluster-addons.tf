resource "aws_eks_addon" "kube_proxy" {
  count = alltrue([var.create_cluster, var.create_eks_addons]) ? 1 : 0

  cluster_name      = aws_eks_cluster.cluster[0].name
  addon_name        = "kube-proxy"
  addon_version     = var.eks_addon_version_kube_proxy
  resolve_conflicts = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      "eks_addon" = "kube-proxy"
    }
  )
}

resource "aws_eks_addon" "core_dns" {
  count = alltrue([var.create_cluster, var.create_eks_addons]) ? 1 : 0

  cluster_name      = aws_eks_cluster.cluster[0].name
  addon_name        = "coredns"
  addon_version     = var.eks_addon_version_core_dns
  resolve_conflicts = "OVERWRITE"

  tags = merge(
    var.tags,
    {
      "eks_addon" = "coredns"
    }
  )
}

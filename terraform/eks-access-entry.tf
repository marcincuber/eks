resource "aws_eks_access_entry" "roles" {
  for_each = { for role in var.eks_access_entry_roles : role.rolearn => role }

  cluster_name      = aws_eks_cluster.cluster.id
  principal_arn     = each.value.principal_arn
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  user_name         = try(each.value.user_name, null)
  type              = try(each.value.type, "STANDARD")
}

resource "aws_eks_access_entry" "cluster_admin_role" {
  cluster_name = aws_eks_cluster.cluster.id

  principal_arn = try(data.aws_iam_session_context.current.issuer_arn, "")
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin_role" {
  cluster_name = aws_eks_cluster.cluster.id

  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = try(data.aws_iam_session_context.current.issuer_arn, "")
  access_scope {
    type = "cluster"
  }
}

#####
# Karpenter Node IAM Role
#####
resource "aws_iam_role" "eks_node_karpenter" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-node-karpenter"

  assume_role_policy = data.aws_iam_policy_document.eks_node_karpenter_assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "eks_node_karpenter" {
  count = var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-node-karpenter"
  role = aws_iam_role.eks_node_karpenter[0].name
}

# Used by karpenter-controller
resource "aws_iam_role" "karpenter_controller" {
  count = var.create_cluster ? 1 : 0

  name        = "${local.name_prefix}-karpenter-controller"
  description = "Allow karpenter-controller EC2 read and write operations."

  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", {
    OIDC_ARN  = aws_iam_openid_connect_provider.cluster[0].arn,
    OIDC_URL  = replace(aws_iam_openid_connect_provider.cluster[0].url, "https://", ""),
    NAMESPACE = "karpenter",
    SA_NAME   = "karpenter"
  })

  force_detach_policies = true

  tags = merge(
    var.tags,
    {
      "ServiceAccountName"      = "karpenter"
      "ServiceAccountNamespace" = "karpenter"
    }
  )
}

resource "aws_iam_role_policy" "karpenter_controller" {
  count = var.create_cluster ? 1 : 0

  name = "KarpenterControllerPolicy"
  role = aws_iam_role.karpenter_controller[0].id

  policy = data.aws_iam_policy_document.karpenter_controller[0].json
}

#####
# Karpenter Node SG
#####
resource "aws_security_group" "node" {
  count = var.create_cluster ? 1 : 0

  name_prefix = "${local.name_prefix}-node-sg-"
  description = "EKS Karpenter Node security group."
  vpc_id      = module.vpc.vpc_id

  tags = {
    "Name"                                       = "${local.name_prefix}-node-sg"
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
    "karpenter.sh/discovery"                     = local.local.name_prefix
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_all_allow_access_from_control_plane" {
  count = var.create_cluster ? 1 : 0

  security_group_id = aws_security_group.node[0].id
  description       = "Allow communication from control plan security group."

  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_eks_cluster.cluster[0].vpc_config.0.cluster_security_group_id
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_self" {
  count = var.create_cluster ? 1 : 0

  security_group_id = aws_security_group.node[0].id
  description       = "Self Reference all traffic"

  protocol  = "-1"
  from_port = 0
  to_port   = 65535
  type      = "ingress"
  self      = true
}

resource "aws_security_group_rule" "egress_to_cluster" {
  count = var.create_cluster ? 1 : 0

  security_group_id = aws_security_group.node.id
  description       = "Node groups to cluster API"

  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
  type                     = "egress"
  source_security_group_id = aws_eks_cluster.cluster[0].vpc_config.0.cluster_security_group_id
}

resource "aws_security_group_rule" "egress_to_internet" {
  count = var.create_cluster ? 1 : 0

  security_group_id = aws_security_group.node[0].id
  description       = "All egress allowed."

  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  type        = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

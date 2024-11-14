#####
# Karpenter Node IAM Role
#####
resource "aws_iam_role" "eks_node_karpenter" {
  name = "${var.name_prefix}-node-karpenter"

  assume_role_policy = data.aws_iam_policy_document.eks_node_karpenter_assume_role_policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "eks_node_karpenter" {
  role_name = aws_iam_role.eks_node_karpenter.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/CloudWatchApplicationInsightsFullAccess"
  ]
}

resource "aws_iam_role_policy" "eks_node_karpenter" {
  name   = "custom-policy"
  role   = aws_iam_role.eks_node_karpenter.id
  policy = data.aws_iam_policy_document.eks_node_custom_inline_policy.json
}

resource "aws_iam_instance_profile" "eks_node_karpenter" {
  name = "${var.name_prefix}-node-karpenter"
  role = aws_iam_role.eks_node_karpenter.name
}

#####
# Karpenter Node Security Group
#####
resource "aws_security_group" "node" {
  name_prefix = "${var.name_prefix}-node-sg-"

  description = "EKS Karpenter Node security group."
  vpc_id      = module.vpc_eks.vpc_id

  tags = {
    "Name"                                     = "${var.name_prefix}-node-sg"
    "kubernetes.io/cluster/${var.name_prefix}" = "owned"
    "karpenter.sh/discovery"                   = var.name_prefix
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "all_allow_access_from_control_plane" {
  security_group_id = aws_security_group.node.id
  description       = "Allow communication from control plan security group."

  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "self" {
  security_group_id = aws_security_group.node.id
  description       = "Self Reference all traffic."

  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_from_coredns_to_karpenter_nodes" {
  security_group_id = aws_security_group.node.id
  description       = "All traffic from CoreDNS."

  referenced_security_group_id = aws_security_group.core_dns.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "node_to_cluster" {
  security_group_id = aws_security_group.node.id
  description       = "Nodes access to cluster API."

  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "node_to_internet" {
  security_group_id = aws_security_group.node.id
  description       = "Allow all egress."

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Access to vpc endpoint sg
resource "aws_vpc_security_group_ingress_rule" "node_to_vpc_endpoints" {
  security_group_id = aws_security_group.eks_vpc_endpoint.id
  description       = "Allow EKS Karpenter nodes access to VPC endpoints."

  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id
}

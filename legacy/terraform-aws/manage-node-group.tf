module "eks-node-group-a" {
  source = "native-cube/eks-node-group/aws"
  version = "~> 1.0.0"

  count           = var.enable_managed_workers ? 1 : 0
  create_iam_role = false

  cluster_name  = var.create_cluster ? aws_eks_cluster.cluster[0].name : null
  node_role_arn = var.enable_managed_workers ? aws_iam_role.managed_workers[0].arn : 0
  subnet_ids    = [module.vpc.private_subnets[0]]

  desired_size = 1
  min_size     = 1
  max_size     = 3

  instance_types = ["m5.2xlarge", "m5d.2xlarge", "m5a.2xlarge"]

  capacity_type = "SPOT"

  ec2_ssh_key               = var.ssh_key_name
  source_security_group_ids = [module.bastion.security_group_id]

  labels = {
    lifecycle = "Ec2Spot"
  }

  tags = var.tags
}

module "eks-node-group-b" {
  source = "native-cube/eks-node-group/aws"
  version = "~> 1.0.0"
  
  count           = var.enable_managed_workers ? 1 : 0
  create_iam_role = false

  cluster_name  = var.create_cluster ? aws_eks_cluster.cluster[0].name : null
  node_role_arn = var.enable_managed_workers ? aws_iam_role.managed_workers[0].arn : 0
  subnet_ids    = [module.vpc.private_subnets[1]]

  desired_size = 1
  min_size     = 1
  max_size     = 3

  instance_types = ["m5.2xlarge", "m5d.2xlarge", "m5a.2xlarge"]

  capacity_type = "SPOT"

  ec2_ssh_key               = var.ssh_key_name
  source_security_group_ids = [module.bastion.security_group_id]

  labels = {
    lifecycle = "Ec2Spot"
  }

  tags = var.tags
}

resource "aws_iam_role" "managed_workers" {
  count = var.enable_managed_workers && var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-managed-worker-node"

  assume_role_policy = data.aws_iam_policy_document.managed_workers_role_assume_role_policy.json
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  count      = var.enable_managed_workers && var.create_cluster ? 1 : 0
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKSWorkerNodePolicy" : "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_workers[0].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count      = var.enable_managed_workers && var.create_cluster ? 1 : 0
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKS_CNI_Policy" : "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_workers[0].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count      = var.enable_managed_workers && var.create_cluster ? 1 : 0
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" : "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_workers[0].name
}

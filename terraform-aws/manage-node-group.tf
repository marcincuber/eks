module "eks-node-group-a" {
  source  = "umotif-public/eks-node-group/aws"
  version = "~> 1.0"

  enabled         = var.enable_managed_workers
  create_iam_role = false

  cluster_name  = var.create_cluster ? aws_eks_cluster.cluster[0].name : null
  node_role_arn = var.enable_managed_workers ? aws_iam_role.managed_workers[0].arn : 0
  subnet_ids    = [module.vpc.private_subnets[0]]

  desired_size = 1
  min_size     = 1
  max_size     = 1

  instance_types = ["t3.large"]

  ec2_ssh_key               = var.ssh_key_name
  source_security_group_ids = [module.bastion.security_group_id]

  kubernetes_labels = {
    lifecycle = "OnDemand"
    az        = "eu-west-1a"
  }

  tags = var.tags
}

module "eks-node-group-b" {
  source  = "umotif-public/eks-node-group/aws"
  version = "~> 1.0"

  enabled         = var.enable_managed_workers
  create_iam_role = false

  cluster_name  = var.create_cluster ? aws_eks_cluster.cluster[0].name : null
  node_role_arn = var.enable_managed_workers ? aws_iam_role.managed_workers[0].arn : 0
  subnet_ids    = [module.vpc.private_subnets[1]]

  desired_size = 1
  min_size     = 1
  max_size     = 1

  instance_types = ["t2.large"]

  ec2_ssh_key               = var.ssh_key_name
  source_security_group_ids = [module.bastion.security_group_id]

  kubernetes_labels = {
    lifecycle = "OnDemand"
    az        = "eu-west-1b"
  }

  tags = var.tags
}

module "eks-node-group-c" {
  source  = "umotif-public/eks-node-group/aws"
  version = "~> 1.0"

  enabled         = var.enable_managed_workers
  create_iam_role = false

  cluster_name  = var.create_cluster ? aws_eks_cluster.cluster[0].name : null
  node_role_arn = var.enable_managed_workers ? aws_iam_role.managed_workers[0].arn : 0
  subnet_ids    = [module.vpc.private_subnets[2]]

  desired_size = 1
  min_size     = 1
  max_size     = 1

  ec2_ssh_key               = var.ssh_key_name
  source_security_group_ids = [module.bastion.security_group_id]

  kubernetes_labels = {
    lifecycle = "OnDemand"
    az        = "eu-west-1c"
  }

  tags = var.tags
}

resource "aws_iam_role" "managed_workers" {
  count = var.enable_managed_workers && var.create_cluster ? 1 : 0

  name = "${local.name_prefix}-managed-worker-node"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  count      = var.enable_managed_workers && var.create_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_workers[0].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count      = var.enable_managed_workers && var.create_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_workers[0].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count      = var.enable_managed_workers && var.create_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_workers[0].name
}

#####
# EKS Worker Nodes security group
#####

resource "random_id" "nonmanaged_workers_sg_suffix" {
  byte_length = 4
}

resource "aws_security_group" "nonmanaged_workers_sg" {
  count = var.enable_spot_workers ? 1 : 0

  name        = "${local.name_prefix}-worker-node-sg-${random_id.nonmanaged_workers_sg_suffix.hex}"
  description = "Security Group used by non-managed worker nodes in the cluster."
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${local.name_prefix}" = "owned"
    },
    {
      "Name" = "${local.name_prefix}-worker-node-sg-${random_id.nonmanaged_workers_sg_suffix.hex}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "nonmanaged_workers_sg_ingress_self" {
  count = var.enable_spot_workers ? 1 : 0

  description              = "Allow node to communicate with each other."
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nonmanaged_workers_sg[0].id
  source_security_group_id = aws_security_group.nonmanaged_workers_sg[0].id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nonmanaged_workers_sg_ingress_controlplane" {
  count = var.enable_spot_workers && var.create_cluster ? 1 : 0

  description              = "Allow controlplane to communicate with worker nodes."
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nonmanaged_workers_sg[0].id
  source_security_group_id = aws_eks_cluster.cluster[0].vpc_config.0.cluster_security_group_id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nonmanaged_workers_sg_ingress_controlplane_with_workers" {
  count = var.enable_spot_workers && var.create_cluster ? 1 : 0

  description              = "Allow controlplane to communicate with worker nodes."
  from_port                = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.nonmanaged_workers_sg[0].id
  security_group_id        = aws_eks_cluster.cluster[0].vpc_config.0.cluster_security_group_id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nonmanaged_workers_sg_ingress_bastion" {
  count = var.enable_spot_workers ? 1 : 0

  description              = "Allow bastion host access to worker nodes."
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nonmanaged_workers_sg[0].id
  source_security_group_id = module.bastion.security_group_id
  to_port                  = 22
  type                     = "ingress"
}

resource "aws_security_group_rule" "vpc_endpoint_eks_nonmanaged_workers" {
  count = var.enable_spot_workers ? 1 : 0

  description              = "Allow worker non-managed nodes to communicate through vpc endpoints."
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = aws_security_group.nonmanaged_workers_sg[0].id
  to_port                  = 443
  type                     = "ingress"
}

#####
# EKS spot worker nodes cloudformation stack
#####

resource "aws_cloudformation_stack" "spot_worker" {
  count = var.enable_spot_workers && var.create_cluster ? length(module.vpc.private_subnets) : 0

  name         = "${local.name_prefix}-spot-worker-nodes-stack-${count.index}"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    KeyName       = var.ssh_key_name
    NodeImageId   = data.aws_ssm_parameter.eks_optimized_ami_id.value
    ClusterName   = aws_eks_cluster.cluster[0].id
    NodeGroupName = "${local.name_prefix}-spot-node-group-${count.index}"

    RestrictMetadata      = var.spot_worker_restrict_metadata_access
    ASGAutoAssignPublicIp = "no"
    ASGMetricsEnabled     = var.spot_worker_enable_asg_metrics
    NodeInstanceType      = var.spot_worker_instance_type

    Subnets                          = module.vpc.private_subnets[count.index] #join(",", module.vpc.private_subnets)
    VpcId                            = module.vpc.vpc_id
    NodeInstanceProfileArn           = aws_iam_instance_profile.worker_node.arn
    ClusterControlPlaneSecurityGroup = aws_eks_cluster.cluster[0].vpc_config.0.cluster_security_group_id
    ExistingNodeSecurityGroups       = "${aws_security_group.nonmanaged_workers_sg[0].id}"

    SpotAllocStrategy                   = "capacity-optimized"
    InstanceTypesOverride               = var.worker_instance_types
    OnDemandBaseCapacity                = var.ondemand_number_of_nodes
    OnDemandPercentageAboveBaseCapacity = var.ondemand_percentage_above_base

    NodeAutoScalingGroupDesiredCapacity = var.desired_number_worker_nodes
    NodeAutoScalingGroupMinSize         = var.min_number_worker_nodes
    NodeAutoScalingGroupMaxSize         = var.max_number_worker_nodes
      
    ContainerRuntime = var.container_runtime

    BootstrapArgumentsForOnDemand = "--kubelet-extra-args '--node-labels=lifecycle=OnDemand --system-reserved=\"cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi\" --kube-reserved=\"cpu=250m,memory=1Gi,ephemeral-storage=1Gi\" --eviction-hard=\"memory.available<0.2Gi,nodefs.available<10%\" --event-qps=0 --read-only-port=0'"
    BootstrapArgumentsForSpot     = "--kubelet-extra-args '--node-labels=lifecycle=Ec2Spot --register-with-taints=spotInstance=true:PreferNoSchedule --system-reserved=\"cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi\" --kube-reserved=\"cpu=250m,memory=1Gi,ephemeral-storage=1Gi\" --eviction-hard=\"memory.available<0.2Gi,nodefs.available<10%\" --event-qps=0 --read-only-port=0'"
  }

  template_body = var.aws_partition == "china" ? file("cfm/worker-node-spot-stack-cn.yaml") : file("cfm/worker-node-spot-stack.yaml")

  tags = var.tags

  timeouts {
    create = "60m"
    update = "2h"
    delete = "2h"
  }
}

#####
# EKS Worker Nodes Resources
#####

resource "aws_iam_role" "worker_node" {
  name = "${local.name_prefix}-worker-node"

  assume_role_policy = data.aws_iam_policy_document.worker_node_role_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_instance_profile" "worker_node" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.worker_node.name
  
  tags = var.tags
}

resource "random_id" "iam_policy_suffix" {
  byte_length = 4
}

resource "aws_iam_policy" "worker_node_custom_policy" {
  name   = "${local.name_prefix}-custom-policy-${random_id.iam_policy_suffix.hex}"
  policy = templatefile("policies/worker_node_custom_policy.json", {})
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKSWorkerNodePolicy" : "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" : "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSCNIPolicy" {
  policy_arn = var.aws_partition == "china" ? "arn:aws-cn:iam::aws:policy/AmazonEKS_CNI_Policy" : "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-custom-policy" {
  policy_arn = aws_iam_policy.worker_node_custom_policy.arn
  role       = aws_iam_role.worker_node.name
}

#####
# Outputs
#####

output "worker_node_role_arn" {
  value = aws_iam_role.worker_node.arn
}

output "worker_node_instance_profile_arn" {
  value = aws_iam_instance_profile.worker_node.arn
}

output "worker_node_custom_policy_arn" {
  value = aws_iam_policy.worker_node_custom_policy.arn
}

output "auto_scaling_group_name" {
  value = "${local.name_prefix}-spot-node-group"
}

output "eks_optimized_ami_id" {
  value     = data.aws_ssm_parameter.eks_optimized_ami_id.value
  sensitive = true
}

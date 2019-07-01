#####
# EKS worker nodes cloudformatino stack
#####

resource "aws_cloudformation_stack" "spot_worker" {
  name         = "${var.cluster_name}-${var.environment}-spot-worker-nodes-stack"
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    KeyName       = var.ssh_key_name
    NodeImageId   = var.ami_id
    ClusterName   = aws_eks_cluster.cluster.id
    NodeGroupName = "${var.cluster_name}-${var.environment}-spot-node-group"

    ASGAutoAssignPublicIp = "no"
    NodeInstanceType      = var.spot_worker_instance_type

    Subnets                          = join(",", module.vpc.private_subnets)
    VpcId                            = module.vpc.vpc_id
    NodeInstanceProfileArn           = aws_iam_instance_profile.worker_node.arn
    ClusterControlPlaneSecurityGroup = aws_security_group.cluster.id
    ExistingNodeSecurityGroups       = "${aws_security_group.node.id},${module.vpc.default_security_group_id}"

    InstanceTypesOverride               = "m5.4xlarge,m5d.4xlarge,m5a.4xlarge,m5ad.4xlarge"
    OnDemandBaseCapacity                = var.ondemand_number_of_nodes
    OnDemandPercentageAboveBaseCapacity = var.ondemand_percentage_above_base
    SpotInstancePools                   = var.spot_instance_pools

    NodeAutoScalingGroupDesiredCapacity = var.desired_number_worker_nodes
    NodeAutoScalingGroupMinSize         = var.min_number_worker_nodes
    NodeAutoScalingGroupMaxSize         = var.max_number_worker_nodes

    BootstrapArgumentsForOnDemand = "--use-max-pods 'true' --kubelet-extra-args '--node-labels=lifecycle=OnDemand --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --kube-reserved cpu=250m,memory=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<0.2Gi,nodefs.available<10% --event-qps 0'"
    BootstrapArgumentsForSpot     = "--use-max-pods 'true' --kubelet-extra-args '--node-labels=lifecycle=Ec2Spot --register-with-taints=spotInstance=true:PreferNoSchedule --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --kube-reserved cpu=250m,memory=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<0.2Gi,nodefs.available<10% --event-qps 0'"
  }

  template_body = file("cfm/worker-node-spot-stack.yaml")

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
  name = "${var.cluster_name}-${var.environment}-worker-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_instance_profile" "worker_node" {
  name = "${var.cluster_name}-${var.environment}-instance-profile"
  role = aws_iam_role.worker_node.name
}

resource "random_id" "role_suffix" {
  byte_length = 8
}

resource "aws_iam_policy" "worker_node_custom_policy" {
  name = "${var.cluster_name}-${var.environment}-custom-policy-${random_id.role_suffix.hex}"
  policy = templatefile("policies/worker_node_custom_policy.json", {})
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "node-custom-policy" {
  policy_arn = aws_iam_policy.worker_node_custom_policy.arn
  role = aws_iam_role.worker_node.name
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
# resource "aws_cloudformation_stack" "worker" {
#   name         = "${var.cluster_name}-${var.environment}-worker-nodes-stack"
#   capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]

#   parameters = {
#     KeyName       = "${var.ssh_key_name}"
#     NodeImageId   = "${var.ami_id}"
#     ClusterName   = "${aws_eks_cluster.cluster.id}"
#     NodeGroupName = "${var.cluster_name}-${var.environment}-node-group"

#     NodeInstanceType                 = "${var.worker_instance_type}"
#     BootstrapArguments               = "--kubelet-extra-args --node-labels=lifecycle=OnDemand"
#     ClusterControlPlaneSecurityGroup = "${aws_security_group.cluster.id}"
#     Subnets                          = "${join(",", module.vpc.private_subnets)}"
#     VpcId                            = "${module.vpc.vpc_id}"
#     NodeInstanceProfileName          = "${aws_iam_instance_profile.worker_node.name}"
#     NodeInstanceRoleName             = "${aws_iam_role.worker_node.name}"
#     NodeSecurityGroupName            = "${aws_security_group.node.id}"

#     NodeAutoScalingGroupDesiredCapacity = "1"
#     NodeAutoScalingGroupMinSize         = "1"
#     NodeAutoScalingGroupMaxSize         = "20"
#   }

#   template_body = "${file("cfm/worker-node-stack.yaml")}"

#   tags = "${var.tags}"
# }

variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region in which resources will get deployed. Defaults to Ireland."
}

variable "availability_zones" {
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  description = "Availability zones for the default Ireland region."
}

variable "bastion_instance_types" {
  type        = list(string)
  description = "Bastion instance types used for spot instances."
  default     = ["t3.nano", "t3.micro", "t3.small", "t2.nano", "t2.micro", "t2.small"]
}

variable "worker_instance_types" {
  type        = string
  description = "Worker instance types used for spot instances."
  default     = "m5.large,m5d.large,m5a.large,m5ad.large,m5n.large,m5dn.large"
}

variable "vpc_cidr" {
  description = "Amazon Virtual Private Cloud Classless Inter-Domain Routing range."
}

variable "private_subnets_cidrs" {
  type        = list(string)
  description = "Classless Inter-Domain Routing ranges for private subnets."
}

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "Classless Inter-Domain Routing ranges for public subnets."
}

variable "eks_enabled_log_types" {
  type    = list(string)
  default = []
}

variable "tags" {
  type        = map(string)
  description = "Default tags attached to all resources."
}

variable "eks_version" {}

variable "eks_version_latest_ami" {}

variable "create_cluster" {
  type    = bool
  default = true
}

variable "ssh_key_name" {
  default = "eks-test"
}

variable "hosted_zone_id" {
  description = "Hosted zone id used by bastion host."
  default     = ""
}

variable "worker_instance_type" {
  default = ""
}

variable "spot_worker_instance_type" {
  default = "m5.4xlarge"
}

variable "vpc_single_nat_gateway" {
  type = bool
}

variable "vpc_one_nat_gateway_per_az" {
  type = bool
}

variable "ondemand_number_of_nodes" {
  type = number
}

variable "ondemand_percentage_above_base" {
  type = number
}

variable "desired_number_worker_nodes" {
  type = number
}

variable "min_number_worker_nodes" {
  type = number
}

variable "max_number_worker_nodes" {
  type = number
}

variable "aws_role_arn" {
  type = string
}

variable "oidc_thumbprint_list" {
  type    = list(any)
  default = []
}

variable "enable_spot_workers" {
  type    = bool
  default = true
}

variable "enable_managed_workers" {
  type    = bool
  default = true
}

variable "spot_worker_enable_asg_metrics" {
  type        = string
  description = "Enable Auto Scaling Group Metrics on spot worker."
  default     = "yes"
}

variable "managed_node_group_instance_types" {
  type        = string
  description = "(Optional) String of instance types associated with the EKS Managed Node Group. Terraform will only perform drift detection if a configuration value is provided. Currently, the EKS API only accepts a single value."
  default     = "t3.medium"
}

variable "managed_node_group_release_version" {
  type        = string
  description = "AMI version of the EKS Node Group. Available versions in https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html"
  default     = ""
}

variable "spot_worker_restrict_metadata_access" {
  type        = string
  description = "Restrict access to ec2 instance profile credentials"
  default     = "no"
}

variable "aws_partition" {
  type    = string
  default = "public"

  description = "A Partition is a group of AWS Region and Service objects. You can use a partition to determine what services are available in a region, or what regions a service is available in."

  validation {
    condition     = contains(["public", "china"], var.aws_partition)
    error_message = "Argument \"aws_partition\" must be either \"public\" or \"china\"."
  }
}

variable "create_eks_addons" {
  type        = bool
  description = "Enable EKS managed addons creation."
  default     = true
}

variable "eks_addon_version_kube_proxy" {
  type        = string
  description = "Kube proxy managed EKS addon version."
  default     = "v1.27.1-eksbuild.1"
}

variable "eks_addon_version_core_dns" {
  type        = string
  description = "Core DNS managed EKS addon version."
  default     = "v1.10.1-eksbuild.1"
}

variable "eks_addon_version_ebs_csi_driver" {
  type        = string
  description = "AWS ebs csi driver managed EKS addon version."
  default     = "v1.19.0-eksbuild.1"
}

variable "eks_addon_version_kubecost" {
  type        = string
  description = "KubeCost EKS addon version."
  default     = "v1.99.0-eksbuild.1"
}

variable "container_runtime" {
  type        = string
  description = "Container runtime used by EKS worker nodes. Allowed values: `dockerd` and `containerd`."
  default     = "containerd"
}

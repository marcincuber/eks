variable "name_prefix" {
  type        = string
  description = "Name prefix used across resources created by this module."
}

#####
# VPC
#####
variable "vpc_cidr" {
  type        = string
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

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

#####
# EKS
#####
variable "eks_version" {
  type        = string
  description = "EKS controlplane version."
}

variable "eks_enabled_log_types" {
  description = "List of the desired control plane logging to enable."
  type        = list(string)
  default     = []
}

variable "instance_types" {
  type        = list(string)
  description = "List of instance types associated with the EKS Node Group."
  default     = ["m6i.large"]
}

variable "eks_service_ipv4_cidr" {
  type        = string
  description = "The CIDR block to assign Kubernetes service IP addresses from."
  default     = null
}

variable "eks_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled."
  default     = ["0.0.0.0/0"]
}

variable "eks_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for the cross-account elastic network interfaces that Amazon EKS creates to use to allow communication between your worker nodes and the Kubernetes control plane."
  default     = []
}

variable "eks_endpoint_private_access" {
  type        = bool
  description = "Whether the Amazon EKS private API server endpoint is enabled."
  default     = true
}

variable "eks_endpoint_public_access" {
  type        = bool
  description = "Whether the Amazon EKS public API server endpoint is enabled."
  default     = true
}

#####
# EKS Addons
#####
variable "eks_addon_version_kube_proxy" {
  type        = string
  description = "Kube proxy managed EKS addon version."
  default     = null
}

variable "eks_addon_version_core_dns" {
  type        = string
  description = "Core DNS managed EKS addon version."
  default     = null
}

variable "eks_addon_version_ebs_csi_driver" {
  type        = string
  description = "AWS ebs csi driver managed EKS addon version."
  default     = null
}

variable "eks_addon_version_kubecost" {
  type        = string
  description = "KubeCost EKS addon version."
  default     = null
}

variable "eks_addon_version_guardduty" {
  type        = string
  description = "Guardduty agent EKS addon version."
  default     = null
}

variable "eks_addon_version_adot" {
  type        = string
  description = "ADOT EKS addon version."
  default     = null
}

variable "eks_addon_version_cloudwatch" {
  type        = string
  description = "Cloudwatch EKS addon version."
  default     = null
}

variable "eks_addon_version_snapshot_controller" {
  type        = string
  description = "CSI Snapshot Controller EKS addon version."
  default     = null
}

variable "eks_addon_version_identity_agent" {
  type        = string
  description = "Pod Identity Agent EKS addon version."
  default     = null
}

#####
# EKS Default Managed Node Group 
#####
variable "ebs_delete_on_termination" {
  type        = bool
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "ebs_volume_size" {
  type        = number
  description = "The size of the volume in gigabytes."
  default     = 100
}

variable "ebs_volume_type" {
  type        = string
  description = "The volume type."
  default     = "gp3"
}

variable "ebs_encrypted" {
  type        = bool
  description = "Enables EBS encryption on the volume."
  default     = true
}

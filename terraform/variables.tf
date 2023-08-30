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

#####
# EKS
#####
variable "eks_version" {
  type = string
}

variable "eks_enabled_log_types" {
  description = "List of the desired control plane logging to enable."
  type        = list(string)
  default     = []
}

variable "instance_types" {
  type        = list(string)
  description = "List of instance types associated with the EKS Node Group."
  default     = ["m5.large"]
}

variable "eks_service_ipv4_cidr" {
  type        = string
  description = "The CIDR block to assign Kubernetes service IP addresses from. "
  default     = null
}

variable "eks_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled."
  default     = ["0.0.0.0/0"]
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

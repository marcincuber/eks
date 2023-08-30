name_prefix = "eks-eu-dev"

vpc_cidr              = "10.60.0.0/18"
private_subnets_cidrs = ["10.60.0.0/20", "10.60.16.0/20", "10.60.32.0/20"]
public_subnets_cidrs  = ["10.60.48.0/22", "10.60.52.0/22", "10.60.56.0/22"]

eks_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_service_ipv4_cidr = "10.160.0.0/16"

instance_types = ["m6i.2xlarge"]

eks_public_access_cidrs = [
  "0.0.0.0/0"
]

eks_version = "1.27"

eks_addon_version_kube_proxy     = "v1.27.4-eksbuild.2"
eks_addon_version_core_dns       = "v1.10.1-eksbuild.2"
eks_addon_version_ebs_csi_driver = "v1.21.0-eksbuild.1"
eks_addon_version_kubecost       = "v1.103.3-eksbuild.0"
eks_addon_version_guardduty      = "v1.2.0-eksbuild.2"
eks_addon_version_adot           = "v0.78.0-eksbuild.1"

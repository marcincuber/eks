locals {
  eks_dns_cluster_ip = cidrhost(var.eks_service_ipv4_cidr, 10) # set to X.X.X.10 for CoreDNS service
}

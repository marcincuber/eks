aws_role_arn = ""

hosted_zone_id = "ABC12312qdasdd"

vpc_cidr              = "10.60.0.0/18"
private_subnets_cidrs = ["10.60.0.0/20", "10.60.16.0/20", "10.60.32.0/20"]
public_subnets_cidrs  = ["10.60.48.0/22", "10.60.52.0/22", "10.60.56.0/22"]

eks_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

vpc_single_nat_gateway     = true
vpc_one_nat_gateway_per_az = false

ssh_key_name                         = "eks-test"
spot_worker_instance_type            = "m5.large"
worker_instance_types                = "m5.large,m5d.large,m5a.large,m5ad.large,m5n.large,m5dn.large"
spot_worker_enable_asg_metrics       = "yes"
spot_worker_restrict_metadata_access = "yes"

eks_version                        = "1.27" # upgrade controlplane first then update eks_version_latest_ami to the same version
eks_version_latest_ami             = "1.27"
managed_node_group_release_version = "1.21.2-20210722"

tags = {
  Terraform         = "true"
  Service           = "eks"
  Environment       = "test"
  RegionAbbre       = "eu"
  KubernetesCluster = "eks-test-eu"
}

ondemand_number_of_nodes       = 0
ondemand_percentage_above_base = 0

desired_number_worker_nodes = 1 # should be one less than max_number_worker_nodes
min_number_worker_nodes     = 0
max_number_worker_nodes     = 2 # This is max number per ASG so we have max 6 instances

enable_spot_workers    = true
enable_managed_workers = false

create_cluster = true

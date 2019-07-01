cluster_name   = "ceng-eks"
hosted_zone_id = ""

vpc_cidr              = "10.99.192.0/18"
private_subnets_cidrs = ["10.99.192.0/20", "10.99.208.0/20", "10.99.224.0/20"]
public_subnets_cidrs  = ["10.99.240.0/22", "10.99.244.0/22", "10.99.248.0/22"]

vpc_single_nat_gateway     = true
vpc_one_nat_gateway_per_az = false

environment               = "test"
ssh_key_name              = "ceng-test"
spot_worker_instance_type = "m5.4xlarge"

eks_version = "1.13"
ami_id      = "ami-09bbefc07310f7914"

tags = {
  Terraform    = "true"
  ServiceName  = "ceng-eks"
  ServiceOwner = "marcincuber@hotmail.com"
  Environment  = "test"
}

ondemand_number_of_nodes       = 0
ondemand_percentage_above_base = 0
spot_instance_pools            = 4

desired_number_worker_nodes = 4
min_number_worker_nodes     = 1
max_number_worker_nodes     = 5

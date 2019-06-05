cluster_name = "ceng-eks"
hosted_zone_id = ""

vpc_cidr = ""
private_subnets_cidrs = [""]
public_subnets_cidrs = [""]

vpc_single_nat_gateway = true
vpc_one_nat_gateway_per_az = false

environment = "test"
ssh_key_name = "ceng-test"
spot_worker_instance_type = "m5.4xlarge"

tags = {
  Terraform    = "true"
  ServiceName  = "ceng-eks"
  ServiceOwner = "marcincuber@hotmail.com"
  Environment  = "test"
}

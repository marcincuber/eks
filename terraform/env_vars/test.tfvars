cluster_name = "ceng-eks"

tags = {
  Terraform    = "true"
  ServiceName  = "ceng-eks"
  ServiceOwner = "marcincuber@hotmail.com"
  Environment  = "test"
}

environment = "test"
ssh_key_name = "ceng-test"
worker_instance_type = "c5.large"

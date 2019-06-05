#!/bin/bash -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
ASSOCIATION_ID=$(aws ec2 --region "${REGION}" describe-addresses --filters "Name=allocation-id,Values=${ELASTIC_IP}" --query "Addresses[*].AssociationId" --output text)

[[ -z $${ASSOCIATION_ID} ]] \
  && echo "IP is not associated." \
  || aws ec2 --region "${REGION}" disassociate-address --association-id $${ASSOCIATION_ID}

aws ec2 --region "${REGION}" associate-address --instance-id "$INSTANCE_ID" --allocation-id "${ELASTIC_IP}"

sudo yum update -y

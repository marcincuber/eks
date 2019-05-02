#!/bin/bash
###
#   example ./build_backend.sh -n ceng-eks -e test -r eu-west-1 -k arn:aws:kms:eu-west-1:account-id:key/id-of-aws-s3-key
###

set -ie

Help() {
    echo "usage: ${__dir}/build_backend.sh [options...] "
    echo "options:"
    echo " -n  --name          Specify project name. Required."
    echo " -e  --environment   Required."
    echo " -r  --region        Optional. Defaults to Ireland eu-west-1."
    echo " -k  --kms           Specify KMS key arn. Required."
    echo "     --help          Prints this help message"
}

Exists() {
  command -v "${1}" >/dev/null 2>&1
}

# AWS CLI installed?
if ! Exists aws ; then
  printf "\n******************************************************************************************************************************\n\
This script requires the AWS CLI. See the details here: http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html\n\
******************************************************************************************************************************\n\n"
  exit 1
fi

# Set dir variables
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_NAME=
ENVIRONMENT=
REGION=
KMS_ARN=

if [[ $# -eq 0 ]]; then
    >&2 echo "Please specify arguments when running function."
    Help
    exit 2
fi

# Assign options to variables
while [[ "${1}" != "" ]]; do
  case "${1}" in
    -n | --name)
      shift
      PROJECT_NAME="${1}"
      ;;
    -e | --environment)
      shift
      ENVIRONMENT="${1}"
      ;;
    -r | --region)
      shift
      REGION="${1}"
      ;;
    -k | --kms)
      shift
      KMS_ARN="${1}"
      ;;
    -h | --help)
      Help
      exit 0
      ;;
    *) >&2 echo "error: invalid option: ${1}"
      Help
      exit 3
  esac
  shift
done

[[ -z "${PROJECT_NAME}" ]] && ( echo "Project name not provided" ; exit 4 );
[[ -z "${ENVIRONMENT}" ]] && ( echo "Environment not provided" ; exit 4 );
[[ -z "${KMS_ARN}" ]] && ( echo "KMS key not provided" ; exit 4 );
[[ -z "${REGION}" ]] || REGION=eu-west-1 ;

name_with_env=${PROJECT_NAME}-${ENVIRONMENT}

# Create S3 bucket
if aws s3 ls "s3://${name_with_env}-tf-state" 2>&1 | grep -q 'An error occurred'
then
  aws s3api create-bucket --bucket "${name_with_env}-tf-state" --region "${REGION}" --create-bucket-configuration LocationConstraint=${REGION}
  aws s3api put-bucket-versioning --bucket "${name_with_env}-tf-state" --versioning-configuration '{"Status": "Enabled"}'
  aws s3api get-bucket-versioning --bucket "${name_with_env}-tf-state"
else
  echo "Bucket already exists in the current AWS account. Exiting..."
  exit 5;
fi

# Create dynamoDB
if aws dynamodb describe-table --table-name "${name_with_env}-tf-state-lock" 2>&1 | grep -q 'An error occurred'
then
  aws --region "${REGION}" dynamodb create-table --table-name "${name_with_env}-tf-state-lock" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
else
  echo "DynamoDB table already exists in the current AWS account. Exiting..."
  exit 6;
fi

# Generate backend config for terraform
if [[ -e ../backend_configs/${ENVIRONMENT}_backend ]];
then
  echo "File exists. Modify existing backend configuration for environment: ${ENVIRONMENT}.";
  exit 1;
else
  echo "File doesn't exist. Creating new backend configuration...";

  sed "s|@STATE_BUCKET_NAME@|${name_with_env}-tf-state|g;
     s|@STATE_LOCK_DDB@|${name_with_env}-tf-state-lock|g;
     s|@REGION@|${REGION}|g;
     s|@KMS_KEY_ARN@|${KMS_ARN}|g" \
    ../backend_configs/backend_template > ../backend_configs/"${ENVIRONMENT}"_backend
fi

echo "-----------------------"
echo "New backend config file: backends/${ENVIRONMENT}_backend use it to initilise terraform backend. See README.md."

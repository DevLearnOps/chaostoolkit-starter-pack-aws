#!/bin/sh -e

docker pull --platform linux/amd64 nginx:latest
docker build --platform linux/amd64 -t devlearnops/chaosprobe:latest ../tools/chaosprobe

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export AWS_DEFAULT_REGION="us-east-1"
export AWS_PROFILE="devlearnops"
aws ecr create-repository --repository-name "security/nginx" || true
aws ecr create-repository --repository-name "devlearnops/chaosprobe" || true

docker tag nginx:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/security/nginx:latest
docker tag devlearnops/chaosprobe:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/devlearnops/chaosprobe:latest

aws ecr get-login-password --region $AWS_DEFAULT_REGION \
    | docker login --username AWS \
    --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/security/nginx:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/devlearnops/chaosprobe:latest

export AWS_PREFIX_LIST_ID_SSM_PARAM="/shared/vpc/s3-managed-prefix-list-id"
export AWS_MANAGED_PREFIX_LIST_ID_S3=$(aws ec2 describe-managed-prefix-lists --filters Name=owner-id,Values=AWS --filters Name=prefix-list-name,Values=com.amazonaws.us-east-1.s3 | jq -r '.PrefixLists[0].PrefixListId')

if $(aws ssm get-parameter --name $AWS_PREFIX_LIST_ID_SSM_PARAM >/dev/null 2>&1); then
    echo "Parameter $AWS_PREFIX_LIST_ID_SSM_PARAM already exists."
else
    echo "Creating parameter $AWS_PREFIX_LIST_ID_SSM_PARAM"
    aws ssm put-parameter --name "$AWS_PREFIX_LIST_ID_SSM_PARAM" --type String \
        --value "$AWS_MANAGED_PREFIX_LIST_ID_S3"
fi



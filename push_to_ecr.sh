#!/bin/sh -e

APP_VERSION=latest
APP_NAME=chaos-starter-aws

echo "Creating ECR repository ${APP_NAME}"
AWS_PAGER="" aws ecr create-repository \
    --repository-name "$APP_NAME" \
    --output text 2>/dev/null || true

echo "Building container image"
docker build -t $APP_NAME:$APP_VERSION --platform linux/amd64 .

export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export ECR_REPO_NAME=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$APP_NAME

echo "Upload $APP_NAME container image to ECR"
docker tag $APP_NAME:$APP_VERSION $ECR_REPO_NAME:$APP_VERSION

aws ecr get-login-password --region $AWS_DEFAULT_REGION \
    | docker login --username AWS \
    --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

docker push $ECR_REPO_NAME:$APP_VERSION

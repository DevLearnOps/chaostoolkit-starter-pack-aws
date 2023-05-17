# chaostoolkit-starter-pack-aws
A starter pack full of ChaosToolkit experiments for AWS infrastructure

# Installation

Create templates bucket

```shell
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export TEMPLATES_BUCKET="${AWS_ACCOUNT_ID}-cf-templates"
export AWS_PROFILE=devlearnops
export AWS_DEFAULT_REGION=us-east-1
aws s3api create-bucket --bucket $TEMPLATES_BUCKET
```

Upload templates to S3 bucket

```shell
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export TEMPLATES_BUCKET="${AWS_ACCOUNT_ID}-cf-templates"
export AWS_PROFILE=devlearnops
export AWS_DEFAULT_REGION=us-east-1
aws s3 cp --recursive \
    infra-templates/cloudformation \
    s3://${TEMPLATES_BUCKET}
```

## Lessons Learned

### Failover db cluster RDS

failover is more realistic when done with reboot_db_instance with `force_failover=True`


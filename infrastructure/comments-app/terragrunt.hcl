###############################################################################################
## Terragrunt configuration for `comments-app`
##
## This file provides minimal configuration to deploy the `comments-app` sample application
## to support experiments provided with chaos-starter-pack-aws library.
##
###############################################################################################

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "${get_env("AWS_ACCOUNT_ID")}-live-comments-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "live-comments-terraform-state-lock-table"
  }
}

inputs = {

  ## General app information
  environment         = "live"
  program             = "chaos"
  application_name    = "comments"
  application_version = "v1"

  ## General networking configuration
  vpc_cidr      = "10.0.0.0/16"
  number_of_azs = 2

  ## Application autoscaling configuration
  autoscaling_max_capacity = 4
  autoscaling_min_capacity = 2

  ## Additional custom tags for provisioned resources
  tags = tomap({
    ChaosEngineeringTeam = true
  })

  ## Enables experiment journals collection into a persistent S3 bucket
  ## By default, this terraform script will provision a volatile S3 bucket to store experiment
  ## logs and journals. The provisioned bucket has no write protection and will be destroyed
  ## alongside the infrastructure.
  ##
  ## If you wish to store experiment journals persistently you need to manually create a new
  ## bucket and specify it in the `journals_bucket` Terraform variable
  #
  #journals_bucket = "${get_env("AWS_ACCOUNT_ID")}-live-comments-persistent-ctk-journals"

  ## Enables remote connection to bastion server
  ## If you want to enable remote connection into the infrastructure, uncomment the line below
  ## and insert your bastion ssh-key-pair name.
  #
  #bastion_key_pair_name = "<your-bastion-ssh-key>"

  ## Enables chaos experiments results notifications
  ## If you wish to send notifications of successful/failed experiment executions you can
  ## manually create an SNS topic for the `start-chaos.py` to send notifications to
  #
  #sns_notification_topic_name = "chaos-results-notification-topic"

  ## Enables sample blog application deployment
  ## If you want to deploy a sample fontend blog application, uncomment the line below
  #
  #deploy_sample_blog_application = true

  ## Retain application load balancers access logs in an S3 bucket
  #
  alb_access_logs_to_bucket_enabled = true
}

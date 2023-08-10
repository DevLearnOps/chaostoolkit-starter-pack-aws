remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "309172550216-live-chaos-full-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "live-chaos-full-terraform-state-lock-table"
  }
}

inputs = {
  environment = "live"
  program = "chaos"
  application_name = "comments"
  application_version = "v1"
  autoscaling_max_capacity = 4
  autoscaling_min_capacity = 2
  tags = tomap({
    ChaosEngineeringTeam = true
  })

  sns_notification_topic_name = "chaos-results-notification-topic"
  journals_bucket = "309172550216-live-chaos-persistent-ctk-journals"

  bastion_key_pair_name = "manuel"

  #deploy_blog_application = true
}

data "aws_elb_service_account" "current" {}

resource "aws_s3_bucket" "access_logs" {
  bucket        = "${local.account_id}-${local.name}-access-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "access_logs_bucket_policy" {
  bucket = aws_s3_bucket.access_logs.id
  policy = data.aws_iam_policy_document.allow_write_access_for_albs.json
}

data "aws_iam_policy_document" "allow_write_access_for_albs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.access_logs.arn}/AWSLogs/*",
    ]
  }
}

resource "aws_s3_bucket_metric" "access_logs_metrics" {
  bucket = aws_s3_bucket.access_logs.id
  name   = "EntireBucket"
}

resource "aws_sns_topic" "infosec_updates" {
  name         = "${local.name}-infosec-updates"
  display_name = "Urgent Infrastructure Notifications for InfoSec Engineering Team"
}

module "sec_high_threshold_bucket_get_requests" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "4.3.0"

  alarm_name          = "Sec-High-BucketGetRequests/${var.environment}/${var.application_name}"
  alarm_description   = "Security Alarm For High Bucket Get Requests"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 100

  metric_query = [
    {
      id          = "q1"
      period      = 60
      return_data = true
      label       = "SUM GetRequests"
      expression  = "SELECT SUM(GetRequests) FROM \"AWS/S3\""
    },
  ]

  alarm_actions = [aws_sns_topic.infosec_updates.arn]
}

module "sec_high_threshold_bucket_delete_requests" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "4.3.0"

  alarm_name          = "Sec-High-BucketDeleteRequests/${var.environment}/${var.application_name}"
  alarm_description   = "Security Alarm For High Bucket Delete Requests"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 20

  metric_query = [
    {
      id          = "q1"
      period      = 60
      return_data = true
      label       = "SUM GetRequests"
      expression  = "SELECT SUM(DeleteRequests) FROM \"AWS/S3\""
    },
  ]

  alarm_actions = [aws_sns_topic.infosec_updates.arn]
}

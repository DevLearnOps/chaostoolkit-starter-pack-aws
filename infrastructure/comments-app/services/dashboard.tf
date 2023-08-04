resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "${local.name}-app-dashboard"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [{ "expression" : "SELECT SUM(RequestCountPerTarget) FROM SCHEMA(\"AWS/ApplicationELB\", TargetGroup) GROUP BY TargetGroup", "label" : "RequestCountPerTarget", "id" : "q1", "period" : 1 }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Average",
          "period" : 1,
          "title" : "RequestCountPerTarget by TargetGroup"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 18,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${module.web_service.name}", "ClusterName", "${module.app_cluster.name}", { "id" : "m1", "stat" : "Average", "region" : "${local.region}" }],
            ["...", { "id" : "m2", "region" : "${local.region}" }],
            ["...", { "id" : "m3", "stat" : "Maximum", "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "Comments Web - CPU Utilization"
        }
      },
      {
        "type" : "metric",
        "x" : 8,
        "y" : 18,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${module.web_service.name}", "ClusterName", "${module.app_cluster.name}", { "id" : "m1", "stat" : "Average", "region" : "${local.region}" }],
            ["...", { "id" : "m2", "region" : "${local.region}" }],
            ["...", { "id" : "m3", "stat" : "Maximum", "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "Comments Web - Memory Utilization"
        }
      },
      {
        "type" : "metric",
        "x" : 8,
        "y" : 9,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${module.internal_alb.target_group_arn_suffixes[0]}", "LoadBalancer", "${module.internal_alb.lb_arn_suffix}", { "region" : "${local.region}" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", ".", ".", { "region" : "${local.region}" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", ".", ".", { "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Sum",
          "period" : 10,
          "title" : "API TargetRequestCount"
        }
      },
      {
        "type" : "metric",
        "x" : 16,
        "y" : 9,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${module.internal_alb.target_group_arn_suffixes[1]}", "LoadBalancer", "${module.internal_alb.lb_arn_suffix}"],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", ".", "."]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Sum",
          "period" : 10,
          "title" : "Spamcheck TargetRequestCount"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 9,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${module.public_alb.target_group_arn_suffixes[0]}", "LoadBalancer", "${module.public_alb.lb_arn_suffix}", { "region" : "${local.region}" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", ".", ".", { "region" : "${local.region}" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", ".", ".", { "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Sum",
          "period" : 10,
          "title" : "Web TargetRequestCount"
        }
      },
      {
        "type" : "metric",
        "x" : 16,
        "y" : 18,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["ECS/ContainerInsights", "DesiredTaskCount", "ServiceName", "${module.web_service.name}", "ClusterName", "${module.app_cluster.name}", { "region" : "${local.region}" }],
            [".", "RunningTaskCount", ".", ".", ".", ".", { "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Maximum",
          "period" : 10,
          "title" : "Comments Web - Desired vs Running TaskCount"
        }
      },
      {
        "type" : "text",
        "x" : 0,
        "y" : 6,
        "width" : 24,
        "height" : 3,
        "properties" : {
          "markdown" : "# Request Statistics\n\nStats regarding the requests count by service"
        }
      },
      {
        "type" : "text",
        "x" : 0,
        "y" : 15,
        "width" : 24,
        "height" : 3,
        "properties" : {
          "markdown" : "# ECS Services Insights\n\nCPU + Memory Utilization and Desired vs Running container count"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 24,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${module.api_service.name}", "ClusterName", "${module.app_cluster.name}", { "id" : "m1", "stat" : "Average" }],
            ["...", { "id" : "m2" }],
            ["...", { "id" : "m3", "stat" : "Maximum" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "Comments API - CPU Utilization"
        }
      },
      {
        "type" : "metric",
        "x" : 8,
        "y" : 24,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${module.api_service.name}", "ClusterName", "${module.app_cluster.name}", { "id" : "m1", "stat" : "Average", "region" : "${local.region}" }],
            ["...", { "id" : "m2", "region" : "${local.region}" }],
            ["...", { "id" : "m3", "stat" : "Maximum", "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "Comments API - Memory Utilization"
        }
      },
      {
        "type" : "metric",
        "x" : 16,
        "y" : 24,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["ECS/ContainerInsights", "DesiredTaskCount", "ServiceName", "${module.api_service.name}", "ClusterName", "${module.app_cluster.name}"],
            [".", "RunningTaskCount", ".", ".", ".", "."]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Maximum",
          "period" : 10,
          "title" : "Comments API - Desired vs Running TaskCount"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 30,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${module.spamcheck_service.name}", "ClusterName", "${module.app_cluster_ec2.cluster_name}", { "id" : "m1", "stat" : "Average", "region" : "${local.region}" }],
            ["...", { "id" : "m2", "region" : "${local.region}" }],
            ["...", { "id" : "m3", "stat" : "Maximum", "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "Comments Spamcheck - CPU Utilization"
        }
      },
      {
        "type" : "metric",
        "x" : 8,
        "y" : 30,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${module.spamcheck_service.name}", "ClusterName", "${module.app_cluster_ec2.cluster_name}", { "id" : "m1", "stat" : "Average", "region" : "${local.region}" }],
            ["...", { "id" : "m2", "region" : "${local.region}" }],
            ["...", { "id" : "m3", "stat" : "Maximum", "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "Comments Spamcheck - Memory Utilization"
        }
      },
      {
        "type" : "metric",
        "x" : 16,
        "y" : 30,
        "width" : 8,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["ECS/ContainerInsights", "DesiredTaskCount", "ServiceName", "${module.spamcheck_service.name}", "ClusterName", "${module.app_cluster_ec2.cluster_name}"],
            [".", "RunningTaskCount", ".", ".", ".", "."]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Maximum",
          "period" : 10,
          "title" : "Comments Spamcheck - Desired vs Running TaskCount"
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 36,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "# EC2 Container Instances\n\nCPU + Memory Utilization for container instances providing capacity to ECS services"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 39,
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${module.app_cluster_ec2.autoscaling["ondemand"].autoscaling_group_name}", { "stat" : "Average", "region" : "${local.region}" }],
            ["...", { "stat" : "Maximum", "region" : "${local.region}" }],
            ["...", { "region" : "${local.region}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${local.region}",
          "stat" : "Minimum",
          "period" : 10,
          "title" : "EC2 Ondemand - CPU"
        }
      },
    ]
  })
}

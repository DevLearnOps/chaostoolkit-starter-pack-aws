output "autoscaling_security_group_id" {
  value = aws_security_group.default.id
}

output "cluster_name" {
  value = module.cluster.name
}

output "cluster_arn" {
  value = module.cluster.arn
}

output "autoscaling_capacity_providers" {
  value = module.cluster.autoscaling_capacity_providers
}

output "autoscaling" {
  value = module.autoscaling
}

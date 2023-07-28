output "compute_environment_job_definition" {
  value = module.compute_environment.batch_job_definition_name
}

output "compute_environment_queue_name" {
  value = module.compute_environment.batch_job_queue
}

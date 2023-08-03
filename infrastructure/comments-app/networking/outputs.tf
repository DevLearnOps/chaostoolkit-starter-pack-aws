output "compute_environment_job_definition" {
  value = module.compute_environment.batch_job_definition_name
}

output "compute_environment_queue_name" {
  value = module.compute_environment.batch_job_queue
}

output "bastion_public_ip" {
  value = module.ec2_nat_bastion.public_ip
}


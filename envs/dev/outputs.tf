output "vpc_id" { value = module.networking.vpc_id }
output "public_subnet_ids" { value = module.networking.public_subnet_ids }
output "private_subnet_ids" { value = module.networking.private_subnet_ids }

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}
output "s3_buckets" {
  value = {
    raw       = module.s3_raw.bucket_id
    processed = module.s3_processed.bucket_id
    artifacts = module.s3_artifacts.bucket_id
  }
}

output "ec2_public_ip" {
  description = "Stable EIP — use directly in your Ansible inventory."
  value       = module.ec2.public_ip
}
output "ec2_private_ip" { value = module.ec2.private_ip }
output "ec2_instance_id" { value = module.ec2.instance_id }
output "ec2_ssh_key_secret_name" {
  description = "SM secret name for the SSH private key. Retrieve with aws secretsmanager get-secret-value."
  value       = module.ec2.ssh_key_secret_name
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}
output "rds_security_group_id" { value = module.rds.rds_security_group_id }
output "rds_secret_arn" { value = module.rds.db_secret_arn }
output "rds_secret_name" { value = module.rds.db_secret_name }
output "rds_read_secret_policy_arn" { value = module.rds.db_read_secret_policy_arn }
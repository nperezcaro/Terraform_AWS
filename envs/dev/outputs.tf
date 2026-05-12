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

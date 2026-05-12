output "db_endpoint" {
  description = "host:port — use in your app connection string."
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "db_address" { value = aws_db_instance.this.address }
output "db_port" { value = aws_db_instance.this.port }
output "db_name" { value = aws_db_instance.this.db_name }

output "rds_security_group_id" {
  description = "Pass to allowed_sg_ids on any SG that needs to reach port 5432."
  value       = aws_security_group.rds.id
}

output "db_secret_arn" {
  description = "ARN of the SM secret containing the full connection JSON."
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "SM secret name — use in aws_secretsmanager_secret data sources."
  value       = aws_secretsmanager_secret.db.name
}

output "db_read_secret_policy_arn" {
  description = "Attach to any IAM role that needs to read the DB credentials."
  value       = aws_iam_policy.read_db_secret.arn
}

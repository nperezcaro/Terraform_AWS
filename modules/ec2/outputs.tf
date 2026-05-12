output "instance_id" { value = aws_instance.this.id }
output "private_ip" { value = aws_instance.this.private_ip }

output "public_ip" {
  description = "Stable EIP — use directly in Ansible inventory."
  value       = aws_eip.ec2.public_ip
}

output "security_group_id" {
  description = "Pass to rds.allowed_sg_ids so this instance can reach PostgreSQL on 5432."
  value       = aws_security_group.ec2.id
}

output "iam_role_name" {
  description = "Instance role name — used in envs/dev/main.tf to attach the RDS SM read policy."
  value       = aws_iam_role.ec2.name
}

output "ssh_key_secret_name" {
  description = "SM secret name containing the ED25519 private key."
  value       = aws_secretsmanager_secret.ssh_key.name
}

output "ssh_key_secret_arn" {
  value = aws_secretsmanager_secret.ssh_key.arn
}

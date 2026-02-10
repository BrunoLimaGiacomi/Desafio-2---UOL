output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "Public ALB DNS name (HTTP)"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP of Bastion host"
}

output "rds_endpoint" {
  value       = aws_db_instance.db.address
  description = "RDS endpoint (private)"
}

output "s3_backup_bucket" {
  value       = aws_s3_bucket.backup.bucket
  description = "S3 bucket for backups"
}

output "kms_key_arn" {
  value = aws_kms_key.backup_key.arn
}

output "secrets_manager_db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}

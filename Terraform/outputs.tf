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

output "cloudtrail_bucket" {
  value       = aws_s3_bucket.cloudtrail_bucket.bucket
  description = "S3 bucket where CloudTrail writes logs"
}

output "project_name" {
  value       = var.project_name
  description = "Project/name prefix used to tag and name resources"
}

output "web_asg_name" {
  value       = aws_autoscaling_group.web_asg.name
  description = "Autoscaling Group name for the web tier"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private route table id (used by private subnets)"
}

output "s3_vpce_id" {
  value       = aws_vpc_endpoint.s3_endpoint.id
  description = "VPC Endpoint (Gateway) id for S3"
}

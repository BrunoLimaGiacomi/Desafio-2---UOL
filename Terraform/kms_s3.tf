# Chave KMS para backups no S3 (CMK) com rotação habilitada
resource "aws_kms_key" "backup_key" {
  description         = "CMK for S3 backups (${var.project_name})"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "AllowRootAndEC2Role"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowUseByInstancesAndS3"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-ec2-role"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "backup_key_alias" {
  name          = "alias/${var.project_name}-backup-key"
  target_key_id = aws_kms_key.backup_key.key_id
}


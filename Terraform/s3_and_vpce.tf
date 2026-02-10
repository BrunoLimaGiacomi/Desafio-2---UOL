# Bucket de backup. Bloqueia acesso público, SSE-KMS usando a CMK
resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-backup-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.backup_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  force_destroy = false

  tags = {
    Name = "${var.project_name}-backup"
  }
}

resource "aws_s3_bucket_public_access_block" "backup_block" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Endpoint VPC do tipo Gateway para S3
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id] # garantir que sub-redes privadas alcancem o S3 sem Internet
  tags              = { Name = "${var.project_name}-s3-vpce" }
}

# Política do bucket que só permite PutObject a partir do nosso VPCE
resource "aws_s3_bucket_policy" "backup_policy" {
  bucket = aws_s3_bucket.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyPutNotFromVPCE"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.backup.arn}/*"
        Condition = {
          StringNotEquals = {
            "aws:SourceVpce" = aws_vpc_endpoint.s3_endpoint.id
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.backup.arn,
          "${aws_s3_bucket.backup.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

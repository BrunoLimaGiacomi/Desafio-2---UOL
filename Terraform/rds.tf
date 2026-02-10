# senha aleatória
resource "random_password" "db_password" {
  length  = 16
  special = true
}

locals {
  db_name_sanitized = lower(replace(var.project_name, "/[^0-9A-Za-z]/", ""))
}

# Armazenar credenciais do banco no Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name_prefix = "${var.project_name}-db-secret-"
  description = "RDS credentials for ${var.project_name}"
  tags        = { project = "${var.project_name}" }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Grupo de sub-rede do RDS (use sub-redes privadas de banco)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-sng"
  subnet_ids = aws_subnet.private_db[*].id
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "db" {
  identifier             = "${var.project_name}-db"
  engine                 = var.db_engine
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = substr("db${local.db_name_sanitized}", 0, 64)
  username               = var.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
  tags                   = { Name = "${var.project_name}-db" }
}

# TODO: Em producao, usar multi_az = true, backup_retention_period > 0 e rds.force_ssl = 1.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-db-subnets" }
}

# O instalador web do Moodle nao configura SSL no cliente PostgreSQL. No
# PostgreSQL 15 do RDS, rds.force_ssl vem ligado por padrao e a conexao seria
# recusada. A desativacao e aceitavel aqui porque o RDS fica em subnet privada
# e so aceita trafego do sg-app. Em producao, mantenha SSL e configure sslmode.
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-pg15"
  family = "postgres15"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "immediate"
  }

  tags = { Name = "${var.project_name}-pg15" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group]
  parameter_group_name   = aws_db_parameter_group.main.name

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = { Name = "${var.project_name}-db" }
}
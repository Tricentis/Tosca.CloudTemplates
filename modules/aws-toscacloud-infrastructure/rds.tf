resource "aws_db_subnet_group" "rds_sng" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet_clients.id, aws_subnet.subnet_services.id]

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-sng"
  }
}

resource "aws_db_instance" "rds_db" {
  identifier              = "${var.environment_name}-db"
  allocated_storage       = var.rds_allocated_storage
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window
  db_subnet_group_name    = aws_db_subnet_group.rds_sng.id
  engine                  = "sqlserver-se"
  engine_version          = "15.00"
  instance_class          = var.rds_instance_class
  license_model           = "license-included"
  multi_az                = false
  username                = var.rds_administrator_username
  password                = var.rds_administrator_password
  port                    = var.rds_port
  publicly_accessible     = false
  storage_encrypted       = true
  character_set_name      = "SQL_Latin1_General_CP1_CI_AS"

  vpc_security_group_ids  = [aws_security_group.sg_services.id]

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true

  final_snapshot_identifier = "${var.environment_name}-db"
  skip_final_snapshot       = true

  performance_insights_enabled = false

  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name}-db"
  }
}

resource "random_string" "random" {
  length  = 16
  special = true
}

resource "aws_db_instance" "this" {
  name                       = replace(title(var.name), "-", "")
  allocated_storage          = var.allocated_storage
  storage_type               = var.storage_type
  engine                     = var.engine
  engine_version             = var.engine_version
  auto_minor_version_upgrade = false
  instance_class             = var.instance_class
  username                   = "dbadmin"
  password                   = random_string.random.result
  multi_az                   = false
  availability_zone          = var.availability_zone
  publicly_accessible        = false
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.final_snapshot_identifier
  identifier                 = var.name
  vpc_security_group_ids     = var.security_group_ids
  db_subnet_group_name       = aws_db_subnet_group.airflow.name

  tags = var.tags
}

resource "aws_db_subnet_group" "airflow" {
  name       = var.name
  subnet_ids = var.subnet_ids

  tags = var.tags
}

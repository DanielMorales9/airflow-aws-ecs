module "rds" {
  count  = var.airflow_executor != "Sequential" ? 1 : 0
  source = "./rds"

  name                      = local.name
  final_snapshot_identifier = "${local.name}-${local.timestamp_sanitized}"
  allocated_storage         = var.rds_allocated_storage
  availability_zone         = var.rds_availability_zone
  deletion_protection       = var.rds_deletion_protection
  engine                    = "postgres"
  instance_class            = var.rds_instance_class
  skip_final_snapshot       = var.rds_skip_final_snapshot
  storage_type              = "gp2"
  engine_version            = var.rds_version
  subnet_ids                = local.subnet_ids
  security_group_ids        = [aws_security_group.airflow.id]

  tags = local.tags
}
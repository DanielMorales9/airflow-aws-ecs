module "rds" {
  count  = var.airflow_executor == "Sequential" ? 0 : 1
  source = "./rds"

  name                      = local.name
  final_snapshot_identifier = "${var.resource_prefix}-airflow-${var.resource_suffix}-${local.timestamp_sanitized}"
  allocated_storage         = var.rds_allocated_storage
  availability_zone         = var.rds_availability_zone
  deletion_protection       = var.rds_deletion_protection
  engine                    = "postgres"
  instance_class            = var.rds_instance_class
  skip_final_snapshot       = var.rds_skip_final_snapshot
  storage_type              = "gp2"
  engine_version            = var.rds_version
  subnet_ids                = local.rds_ecs_subnet_ids
  security_group_ids        = [aws_security_group.airflow.id]

  tags = local.tags
}
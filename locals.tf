locals {
  auth_map = {
    "rbac" = "airflow.contrib.auth.backends.password_auth"
  }

  name = "${var.resource_prefix}-airflow-${var.resource_suffix}"

  tags = merge(var.tags, {
    Name      = local.name
    CreatedBy = "Terraform"
    Module    = "terraform-aws-ecs-airflow"
  })

  timestamp           = timestamp()
  timestamp_sanitized = replace(local.timestamp, "/[- TZ:]/", "")
  year                = formatdate("YYYY", local.timestamp)
  month               = formatdate("M", local.timestamp)
  day                 = formatdate("D", local.timestamp)

  postgres_uri = var.airflow_executor == "Sequential" ? "" : "postgresql+psycopg2://${var.rds_username}:${var.rds_password}@${aws_db_instance.airflow[0].address}:${aws_db_instance.airflow[0].port}/${aws_db_instance.airflow[0].name}"
  db_uri       = var.airflow_executor == "Local" ? local.postgres_uri : "sqlite:////opt/airflow/airflow.db"

  airflow_py_requirements_path     = var.airflow_py_requirements_path != "" ? var.airflow_py_requirements_path : "${path.module}/templates/startup/requirements.txt"
  airflow_webserver_container_name = "${var.resource_prefix}-airflow-webserver-${var.resource_suffix}"
  airflow_scheduler_container_name = "${var.resource_prefix}-airflow-scheduler-${var.resource_suffix}"
  airflow_sidecar_container_name   = "${var.resource_prefix}-airflow-sidecar-${var.resource_suffix}"
  airflow_init_container_name      = "${var.resource_prefix}-airflow-init-${var.resource_suffix}"
  airflow_volume_name              = "airflow"
  // Keep the 2 env vars second, we want to override them (this module manges these vars)
  airflow_variables = merge(var.airflow_variables, {
    AIRFLOW__WEBSERVER__SECRET_KEY : var.airflow_secret_key
    AIRFLOW__CORE__SQL_ALCHEMY_CONN : local.db_uri,
    AIRFLOW__CORE__EXECUTOR : "${var.airflow_executor}Executor",
    AIRFLOW__WEBSERVER__RBAC : var.airflow_authentication == "" ? false : true,
    AIRFLOW__WEBSERVER__AUTH_BACKEND : lookup(local.auth_map, var.airflow_authentication, "")
    AIRFLOW__WEBSERVER__BASE_URL : var.use_https ? "https://${local.dns_record}" : "http://localhost:8080" # localhost is default value
  })


  rds_ecs_subnet_ids = length(var.private_subnet_ids) == 0 ? var.public_subnet_ids : var.private_subnet_ids

  dns_record      = var.dns_name != "" ? var.dns_name : (var.route53_zone_name != "" ? "${var.resource_prefix}-airflow-${var.resource_suffix}.${data.aws_route53_zone.zone[0].name}" : "")
  certificate_arn = var.use_https ? (var.certificate_arn != "" ? var.certificate_arn : aws_acm_certificate.cert[0].arn) : ""

  inbound_ports = toset(var.use_https ? ["80", "443"] : ["80"])

  airflow_scheduler_entrypoint = "startup/entrypoint_scheduler.sh"
  airflow_webserver_entrypoint = "startup/entrypoint_webserver.sh"
  airflow_init_entrypoint      = "startup/entrypoint_init.sh"

  environment_variables = [for k, v in local.airflow_variables : jsonencode({ name : k, value : tostring(v) })]
}
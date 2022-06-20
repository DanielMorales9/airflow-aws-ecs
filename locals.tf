locals {
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

  sqlite_uri  = "sqlite:////opt/airflow/airflow.db"
  basename    = var.airflow_executor != "Sequential" ? "${module.rds[0].username}:${module.rds[0].password}@${module.rds[0].address}:${module.rds[0].port}/${module.rds[0].name}" : ""
  db_uri      = var.airflow_executor != "Sequential" ? "postgresql+psycopg2://${local.basename}" : local.sqlite_uri
  backend_uri = var.airflow_executor != "Sequential" ? "db+postgresql://${local.basename}" : ""

  base_url = var.use_https ? "https://${local.dns_record}" : "http://localhost:8080"

  airflow_webserver_container_name = "${var.resource_prefix}-airflow-webserver-${var.resource_suffix}"
  airflow_scheduler_container_name = "${var.resource_prefix}-airflow-scheduler-${var.resource_suffix}"
  airflow_worker_container_name    = "${var.resource_prefix}-airflow-worker-${var.resource_suffix}"
  airflow_sidecar_container_name   = "${var.resource_prefix}-airflow-sidecar-${var.resource_suffix}"
  airflow_init_container_name      = "${var.resource_prefix}-airflow-init-${var.resource_suffix}"
  airflow_volume_name              = "airflow"

  core_executor = "${var.airflow_executor}Executor"

  celery_variables = var.airflow_executor == "Celery" ? {
    AIRFLOW__CELERY__RESULT_BACKEND : local.backend_uri
    AIRFLOW__CELERY__BROKER_URL : replace(aws_sqs_queue.sqs[0].url, "https", "sqs")
  } : {}

  // Keep the 2 env vars second, we want to override them (this module manges these vars)
  airflow_variables = merge(var.airflow_variables, {
    AIRFLOW__WEBSERVER__SECRET_KEY : random_string.random.result
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN : local.db_uri,
    AIRFLOW__CORE__EXECUTOR : local.core_executor,
    AIRFLOW__WEBSERVER__RBAC : true,
    AIRFLOW__WEBSERVER__AUTH_BACKENDS : "airflow.contrib.auth.backends.password_auth"
    AIRFLOW__WEBSERVER__BASE_URL : local.base_url
    AIRFLOW__LOGGING__REMOTE_LOGGING : true
    AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER : "s3://${var.logging_bucket}/${local.name}"
    AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID : "aws_default"
    AIRFLOW__LOGGING__ENCRYPT_S3_LOGS : false
  }, local.celery_variables)

  if_private_subnets = length(var.private_subnet_ids) == 0
  subnet_ids         = local.if_private_subnets ? var.public_subnet_ids : var.private_subnet_ids

  if_route53_name = var.route53_zone_name == null ? 0 : 1
  route53         = local.if_route53_name > 0 ? "${local.name}.${data.aws_route53_zone.zone[0].name}" : ""
  dns_record      = var.dns_name == null ? local.route53 : ""
  certificate_arn = var.use_https ? coalesce(var.certificate_arn, aws_acm_certificate.cert[0].arn) : ""


  inbound_ports = toset(var.use_https ? ["80", "443"] : ["80"])

  airflow_entrypoint      = "startup/entrypoint.sh"
  airflow_init_entrypoint = "startup/entrypoint_init.sh"
  if_celery_executor      = var.airflow_executor == "Celery" ? 1 : 0

  environment_variables = [for k, v in local.airflow_variables : { name : k, value : tostring(v) }]

  security_groups = [aws_security_group.airflow.id]
}

resource "random_string" "random" {
  length  = 16
  special = true
}
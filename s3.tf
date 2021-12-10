resource "aws_s3_bucket_object" "airflow_seed_dag" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_bucket_prefix}/dags/airflow_seed_dag.py"
  content = templatefile("${path.module}/templates/dags/airflow_seed_dag.py", {
    BUCKET_NAME  = var.s3_bucket_name,
    KEY          = var.s3_bucket_prefix,
    AIRFLOW_HOME = var.airflow_container_home
    YEAR         = local.year
    MONTH        = local.month
    DAY          = local.day
  })
}

resource "aws_s3_bucket_object" "airflow_example_dag" {
  count   = var.airflow_example_dag ? 1 : 0
  bucket  = var.s3_bucket_name
  key     = "${var.s3_bucket_prefix}/dags/example_dag.py"
  content = templatefile("${path.module}/templates/dags/example_dag.py", {})
}

resource "aws_s3_bucket_object" "airflow_scheduler_entrypoint" {
  bucket  = var.s3_bucket_name
  key     = "${var.s3_bucket_prefix}/${local.airflow_scheduler_entrypoint}"
  content = templatefile("${path.module}/templates/${local.airflow_scheduler_entrypoint}", { AIRFLOW_HOME = var.airflow_container_home })
}

resource "aws_s3_bucket_object" "airflow_webserver_entrypoint" {
  bucket  = var.s3_bucket_name
  key     = "${var.s3_bucket_prefix}/${local.airflow_webserver_entrypoint}"
  content = templatefile("${path.module}/templates/${local.airflow_webserver_entrypoint}", { AIRFLOW_HOME = var.airflow_container_home })
}

resource "aws_s3_bucket_object" "airflow_init_entrypoint" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_bucket_prefix}/${local.airflow_init_entrypoint}"
  content = templatefile("${path.module}/templates/${local.airflow_init_entrypoint}", {
    RBAC_AUTH       = var.airflow_authentication == "rbac" ? "true" : "false",
    RBAC_USERNAME   = var.rbac_admin_username,
    RBAC_EMAIL      = var.rbac_admin_email,
    RBAC_FIRSTNAME  = var.rbac_admin_firstname,
    RBAC_LASTNAME   = var.rbac_admin_lastname,
    RBAC_PASSWORD   = var.rbac_admin_password,
    AIRFLOW_VERSION = var.airflow_image_tag
  })
}

resource "aws_s3_bucket_object" "airflow_requirements" {
  count   = var.airflow_py_requirements_path == "" ? 0 : 1
  bucket  = var.s3_bucket_name
  key     = "${var.s3_bucket_prefix}/startup/requirements.txt"
  content = templatefile(local.airflow_py_requirements_path, {})
}
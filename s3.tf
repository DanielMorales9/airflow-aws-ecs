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

resource "aws_s3_bucket_object" "airflow_entrypoint" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_bucket_prefix}/${local.airflow_entrypoint}"
  content = templatefile("${path.module}/templates/${local.airflow_entrypoint}", {
    AIRFLOW_HOME = var.airflow_container_home,
  })
}

resource "aws_s3_bucket_object" "airflow_init_entrypoint" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_bucket_prefix}/${local.airflow_init_entrypoint}"
  content = templatefile("${path.module}/templates/${local.airflow_init_entrypoint}", {
    RBAC_AUTH       = "true",
    RBAC_USERNAME   = var.rbac_admin_username,
    RBAC_EMAIL      = var.rbac_admin_email,
    RBAC_FIRSTNAME  = var.rbac_admin_firstname,
    RBAC_LASTNAME   = var.rbac_admin_lastname,
    RBAC_PASSWORD   = var.rbac_admin_password,
    AIRFLOW_VERSION = var.airflow_image_tag
  })
}

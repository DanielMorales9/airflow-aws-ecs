variable "region" {
  type        = string
  description = "The region to deploy your solution to"
  default     = "eu-west-1"
}

variable "resource_prefix" {
  type        = string
  description = "A prefix for the create resources, example your company name (be aware of the resource name length)"
}

variable "resource_suffix" {
  type        = string
  description = "A suffix for the created resources, example the environment for airflow to run in (be aware of the resource name length)"
}

variable "tags" {
  description = "Extra tags that you would like to add to all created resources"
  type        = map(string)
  default     = {}
}

// Airflow variables
variable "airflow_image_name" {
  type        = string
  description = "The name of the airflow image"
  default     = "apache/airflow"
}

variable "airflow_image_tag" {
  type        = string
  description = "The tag of the airflow image"
  default     = "2.0.1"
}

variable "airflow_executor" {
  type        = string
  description = "The executor mode that airflow will use. Only allowed values are [\"Local\", \"Sequential\"]. \"Local\": Run DAGs in parallel (will created a RDS); \"Sequential\": You can not run DAGs in parallel (will NOT created a RDS);"
  default     = "Local"

  validation {
    condition     = contains(["Local", "Sequential", "Celery"], var.airflow_executor)
    error_message = "The only values that are allowed for \"airflow_executor\" are [\"Local\", \"Sequential\", \"Celery\"]."
  }
}

variable "airflow_variables" {
  type        = map(string)
  description = "The variables passed to airflow as an environment variable (see airflow docs for more info https://airflow.apache.org/docs/). You can not specify \"AIRFLOW__CORE__SQL_ALCHEMY_CONN\" and \"AIRFLOW__CORE__EXECUTOR\" (managed by this module)"
  default     = {}
}

variable "airflow_container_home" {
  type        = string
  description = "Working dir for airflow (only change if you are using a different image)"
  default     = "/opt/airflow"
}

variable "airflow_log_retention" {
  type        = string
  description = "The number of days you want to keep the log of airflow container"
  default     = "7"
}


// RBAC
variable "rbac_admin_username" {
  type        = string
  description = "RBAC Username (only when airflow_authentication = 'rbac')"
  default     = "admin"
}

variable "rbac_admin_password" {
  type        = string
  description = "RBAC Password (only when airflow_authentication = 'rbac')"
  default     = "admin"
}

variable "rbac_admin_email" {
  type        = string
  description = "RBAC Email (only when airflow_authentication = 'rbac')"
  default     = "admin@admin.com"
}

variable "rbac_admin_firstname" {
  type        = string
  description = "RBAC Firstname (only when airflow_authentication = 'rbac')"
  default     = "admin"
}

variable "rbac_admin_lastname" {
  type        = string
  description = "RBAC Lastname (only when airflow_authentication = 'rbac')"
  default     = "airflow"
}

// ECS variables
variable "worker_cpu" {
  type        = number
  description = "The allocated cpu for your airflow instance"
  default     = 1024
}

variable "worker_memory" {
  type        = number
  description = "The allocated memory for your airflow instance"
  default     = 2048
}

// ECS variables
variable "scheduler_cpu" {
  type        = number
  description = "The allocated cpu for your airflow instance"
  default     = 1024
}

variable "scheduler_memory" {
  type        = number
  description = "The allocated memory for your airflow instance"
  default     = 2048
}

variable "num_workers" {
  type        = number
  description = "The number of workers in Celery setup"
  default     = 1
}

// Networking variables
variable "ip_allow_list" {
  type        = list(string)
  description = "A list of ip ranges that are allowed to access the airflow webserver, default: full access"
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {
  type        = string
  description = "The id of the vpc where you will run ECS/RDS"

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "The vpc_id value must be a valid VPC id, starting with \"vpc-\"."
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "A list of subnet ids of where the ALB will reside, if the \"private_subnet_ids\" variable is not provided ECS and RDS will also reside in these subnets"

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "The size of the list \"public_subnet_ids\" must be at least 2."
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of subnet ids of where the ECS and RDS reside, this will only work if you have a NAT Gateway in your VPC"
  default     = []

  validation {
    condition     = length(var.private_subnet_ids) >= 2 || length(var.private_subnet_ids) == 0
    error_message = "The size of the list \"private_subnet_ids\" must be at least 2 or empty."
  }
}

// ACM + Route53
variable "use_https" {
  type        = bool
  description = "Expose traffic using HTTPS or not"
  default     = false
}

variable "dns_name" {
  type        = string
  description = "The DNS name that will be used to expose Airflow. Optional if not serving over HTTPS. Will be autogenerated if not provided"
  default     = null
}

variable "certificate_arn" {
  type        = string
  description = "The ARN of the certificate that will be used"
  default     = ""
}

variable "route53_zone_name" {
  type        = string
  description = "The name of a Route53 zone that will be used for the certificate validation."
  default     = null
}


// Database variables
variable "rds_allocated_storage" {
  type        = number
  description = "The allocated storage for the rds db in gibibytes"
  default     = 20
}

variable "rds_instance_class" {
  type        = string
  description = "The class of instance you want to give to your rds db"
  default     = "db.t2.micro"
}

variable "rds_availability_zone" {
  type        = string
  description = "Availability zone for the rds instance"
  default     = "eu-west-1a"
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Whether or not to skip the final snapshot before deleting (mainly for tests)"
  default     = false
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Deletion protection for the rds instance"
  default     = false
}

variable "rds_version" {
  type        = string
  description = "The DB version to use for the RDS instance"
  default     = "12.7"
}

// S3 Bucket
variable "s3_bucket_name" {
  type        = string
  description = "The S3 bucket name where the DAGs and startup scripts will be stored. WARNING: this module will put files into the path \"dags/\" and \"startup/\" of the bucket"
}

// S3 bucket_prefix
variable "s3_bucket_prefix" {
  type        = string
  default     = ""
  description = "The S3 bucket key prefix where the DAGs and startup scripts will be stored "
}

variable "logging_bucket" {
  type        = string
  description = "The logging bucket"
}


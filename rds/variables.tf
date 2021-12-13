variable "allocated_storage" {
  type        = number
  description = "The allocated storage for the rds db in gibibytes"
}

variable "storage_type" {
  type        = string
  description = <<EOT
  One of `"standard"` (magnetic), `"gp2"` (general purpose SSD), or `"io1"` (provisioned IOPS SSD)
  EOT
}

variable "engine" {
  type        = string
  description = <<EOT
  The database engine to use. For supported values, see the Engine parameter in [API action CreateDBInstance](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html)
  EOT
}

variable "instance_class" {
  type        = string
  description = "The class of instance you want to give to your rds db"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for the rds instance"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether or not to skip the final snapshot before deleting (mainly for tests)"
}

variable "deletion_protection" {
  type        = bool
  description = "Deletion protection for the rds instance"
}

variable "engine_version" {
  type        = string
  description = "The DB version to use for the RDS instance"
}

variable "name" {
  description = "The RDS' name."
}

variable "final_snapshot_identifier" {
  description = "The RDS' final snapshot identifier."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The RDS' subnet Ids"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security Group Ids"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}
resource "aws_sqs_queue" "sqs" {
  count = local.if_celery_executor
  name  = "${var.resource_prefix}-sqs-${var.resource_suffix}"
  tags  = local.tags
}
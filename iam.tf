data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.airflow.arn,
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:s3:::*"
    ]

    actions = ["s3:ListBucket", "s3:ListAllMyBuckets"]
  }

  statement {
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
      "arn:aws:s3:::${var.logging_bucket}",
      "arn:aws:s3:::${var.logging_bucket}/*"
    ]
    actions = ["s3:*"]
  }

  statement {
    effect = "Allow"

    resources = [
      "*"
    ]

    actions = ["sqs:*"]
  }

}

data "aws_iam_policy_document" "task_execution_permissions" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }


  statement {
    effect = "Allow"

    resources = [
      "*"
    ]

    actions = ["ecr:*"]
  }
}

# role for ecs to create the instance
resource "aws_iam_role" "execution" {
  name               = "${var.resource_prefix}-airflow-task-execution-role-${var.resource_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json

  tags = local.tags
}

# role for the airflow instance itself
resource "aws_iam_role" "task" {
  name               = "${var.resource_prefix}-airflow-task-role-${var.resource_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json

  tags = local.tags
}

resource "aws_iam_role_policy" "task_execution" {
  name   = "${var.resource_prefix}-airflow-task-execution-${var.resource_suffix}"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.task_execution_permissions.json
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.resource_prefix}-airflow-log-permissions-${var.resource_suffix}"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

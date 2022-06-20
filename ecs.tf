locals {
  mount_points = [
    {
      sourceVolume  = local.airflow_volume_name,
      containerPath = var.airflow_container_home
    }
  ]

  logConfiguration = {
    logDriver = "awslogs",
    options = {
      "awslogs-group" : aws_cloudwatch_log_group.airflow.name,
      "awslogs-region" : var.region,
      "awslogs-stream-prefix" : "airflow"
    }
  }

  network_mode = "awsvpc"

  s3_source = "s3://${var.s3_bucket_name}/${var.s3_bucket_prefix}"
}

resource "aws_cloudwatch_log_group" "airflow" {
  name              = local.name
  retention_in_days = var.airflow_log_retention

  tags = local.tags
}

resource "aws_ecs_cluster" "airflow" {
  name               = local.name
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "webserver" {
  family                   = "airflow-webserver-${var.resource_suffix}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = local.network_mode
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn

  volume {
    name = local.airflow_volume_name

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id
      root_directory = "/"
    }

  }

  container_definitions = jsonencode(
    [
      {
        image = "${var.airflow_image_name}:${var.airflow_image_tag}",
        name  = local.airflow_webserver_container_name,
        entryPoint = [
          "${var.airflow_container_home}/${local.airflow_entrypoint}",
          "webserver"
        ],
        environment      = local.environment_variables,
        logConfiguration = local.logConfiguration,
        healthCheck = {
          command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
          startPeriod = 120
        },
        essential   = true,
        mountPoints = local.mount_points,
        portMappings = [
          {
            containerPort = 8080
          }
        ]
      }
    ]
  )

  tags = local.tags
}

resource "aws_ecs_task_definition" "scheduler" {
  family                   = "airflow-scheduler-${var.resource_suffix}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.scheduler_cpu
  memory                   = var.scheduler_memory
  network_mode             = local.network_mode
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn

  volume {
    name = local.airflow_volume_name

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id
      root_directory = "/"
    }

  }

  container_definitions = jsonencode([
    {
      image = "mikesir87/aws-cli",
      name  = local.airflow_sidecar_container_name,
      entryPoint = [
        "/bin/bash", "-c"
      ],
      command = [
        "aws s3 cp ${local.s3_source} ${var.airflow_container_home} --recursive && chmod +x ${var.airflow_container_home}/${local.airflow_entrypoint} && chmod -R 777 ${var.airflow_container_home}"
      ]
      logConfiguration = local.logConfiguration,
      essential        = false,
      mountPoints      = local.mount_points
    },
    {
      image = "${var.airflow_image_name}:${var.airflow_image_tag}",
      name  = local.airflow_init_container_name,
      dependsOn = [
        {
          containerName = local.airflow_sidecar_container_name,
          condition     = "SUCCESS"
        }
      ],
      entryPoint = [
        "/bin/bash",
        "-c",
        "${var.airflow_container_home}/${local.airflow_init_entrypoint}"
      ],
      environment      = local.environment_variables,
      logConfiguration = local.logConfiguration,
      essential        = false,
      mountPoints      = local.mount_points,
      dependsOn = [
        {
          containerName = local.airflow_sidecar_container_name,
          condition     = "SUCCESS"
        }
      ],
    },
    {
      image = "${var.airflow_image_name}:${var.airflow_image_tag}",
      name  = local.airflow_scheduler_container_name,
      entrypoint = [
        "${var.airflow_container_home}/${local.airflow_entrypoint}",
        "scheduler"
      ],
      environment      = local.environment_variables,
      logConfiguration = local.logConfiguration,
      essential        = true,
      mountPoints      = local.mount_points,
      portMappings = [
        {
          containerPort = 8793
        }
      ],
      dependsOn = [
        {
          containerName = local.airflow_sidecar_container_name,
          condition     = "SUCCESS"
        },
        {
          containerName = local.airflow_init_container_name,
          condition     = "SUCCESS"
        }
      ],
      healthCheck = {
        command = [
          "CMD-SHELL",
          "airflow jobs check --job-type SchedulerJob --hostname \"$(hostname)\" || exit 1"
        ],
        startPeriod = 120
      },
    }
  ])

  tags = local.tags
}

resource "aws_ecs_task_definition" "worker" {
  count                    = local.if_celery_executor
  family                   = "airflow-worker-${var.resource_suffix}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  network_mode             = local.network_mode
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn

  volume {
    name = local.airflow_volume_name

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id
      root_directory = "/"
    }

  }

  container_definitions = jsonencode(
    [
      {
        image = "${var.airflow_image_name}:${var.airflow_image_tag}",
        name  = local.airflow_worker_container_name,
        entryPoint = [
          "${var.airflow_container_home}/${local.airflow_entrypoint}",
          "worker"
        ],
        environment      = local.environment_variables
        logConfiguration = local.logConfiguration,
        essential        = true,
        mountPoints      = local.mount_points
      }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "webserver" {
  depends_on = [aws_lb.airflow, module.rds]

  name            = "airflow-webserver-${var.resource_suffix}"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.webserver.id
  desired_count   = 1

  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = local.security_groups
    assign_public_ip = local.if_private_subnets
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  load_balancer {
    container_name   = local.airflow_webserver_container_name
    container_port   = 8080
    target_group_arn = aws_lb_target_group.airflow.arn
  }
}

resource "aws_ecs_service" "scheduler" {
  depends_on = [aws_lb.airflow, module.rds]

  name            = "airflow-scheduler-${var.resource_suffix}"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.scheduler.id
  desired_count   = 1

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = local.security_groups
    assign_public_ip = local.if_private_subnets
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}

resource "aws_ecs_service" "worker" {
  count      = local.if_celery_executor
  depends_on = [aws_lb.airflow, module.rds]

  name            = "airflow-worker-${var.resource_suffix}"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.worker[0].id
  desired_count   = var.num_workers

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = local.security_groups
    assign_public_ip = local.if_private_subnets
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}

// SG only meant for the alb to connect to the outside world
resource "aws_security_group" "alb" {
  vpc_id      = var.vpc_id
  name        = "${var.resource_prefix}-alb-${var.resource_suffix}"
  description = "Security group for the alb attached to the airflow ecs task"

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "alb_outside_http" {
  for_each          = local.inbound_ports
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = each.value
  to_port           = each.value
  cidr_blocks       = var.ip_allow_list
}


// Give this SG to all the instances that want to connect to
// the airflow ecs task. For example rds and the alb
resource "aws_security_group" "airflow" {
  vpc_id      = var.vpc_id
  name        = local.name
  description = "Security group to connect to the airflow instance"

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

}

resource "aws_security_group_rule" "airflow_connection" {
  security_group_id        = aws_security_group.airflow.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.airflow.id
}

// ALB
resource "aws_lb" "airflow" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id, aws_security_group.airflow.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = local.tags
}

resource "aws_lb_listener" "airflow" {
  load_balancer_arn = aws_lb.airflow.arn
  port              = var.use_https ? "443" : "80"
  protocol          = var.use_https ? "HTTPS" : "HTTP"
  certificate_arn   = var.use_https ? local.certificate_arn : ""

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow.arn
  }
}

resource "aws_lb_listener" "airflow_http_redirect" {
  count             = var.use_https ? 1 : 0
  load_balancer_arn = aws_lb.airflow.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "airflow" {
  name        = local.name
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 8080
  target_type = "ip"

  health_check {
    port                = 8080
    protocol            = "HTTP"
    interval            = 30
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

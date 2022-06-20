resource "aws_efs_file_system" "efs" {
  tags = local.tags
}

resource "aws_efs_access_point" "access" {
  file_system_id = aws_efs_file_system.efs.id
  tags           = local.tags
}

resource "aws_efs_mount_target" "mount" {
  count           = length(local.subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = local.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name   = "${local.name}-efs-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [aws_security_group.airflow.id]
  }
}
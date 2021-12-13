locals {
  password = aws_db_instance.this.password
  username = aws_db_instance.this.username
  port     = aws_db_instance.this.port
  name     = aws_db_instance.this.name
  address  = aws_db_instance.this.address
}
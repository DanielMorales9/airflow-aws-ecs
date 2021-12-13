output "username" {
  value = local.username
}

output "password" {
  value = local.password
}

output "address" {
  value = local.address
}

output "port" {
  value = local.port
}

output "name" {
  value = local.name
}

output "uri" {
  value = "postgresql+psycopg2://${local.username}:${local.password}@${local.address}:${local.port}/${local.name}"
}
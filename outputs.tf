output "hostname" {
  description = "Name of the kubernetes service"
  value       = kubernetes_service_v1.postgresql.metadata[0].name
}

output "port" {
  description = "Port for the kubernetes service"
  value       = kubernetes_service_v1.postgresql.spec[0].port[0].port
}

output "password_secret" {
  description = "Secret that is created with the database password"
  value       = local.create_password ? kubernetes_secret_v1.postgresql[0].metadata[0].name : var.password_secret
}

output "password_key" {
  description = "Key for the database password in the secret"
  value       = var.password_key
}

output "password_key_root" {
  description = "Key for the database root password in the secret"
  value       = var.password_key_root
}

output "name" {
  description = "Database name"
  value       = var.name
  depends_on = [
    kubernetes_stateful_set_v1.postgresql
  ]
}

output "admin_username" {
  description = "Admin username for the database"
  value       = var.admin_username
  depends_on = [
    kubernetes_stateful_set_v1.postgresql
  ]
}

output "username" {
  description = "Username that can login to the database"
  value       = var.username
  depends_on = [
    kubernetes_stateful_set_v1.postgresql
  ]
}

output "type" {
  description = "Type of database deployed"
  value       = "postgresql"
}

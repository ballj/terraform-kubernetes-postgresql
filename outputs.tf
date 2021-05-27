output "hostname" {
  description = "Name of the kubernetes service"
  value = kubernetes_service.postgresql.metadata[0].name
}

output "port" {
  description = "Port for the kubernetes service"
  value       = kubernetes_service.postgresql.spec[0].port[0].port
}

output "password_secret" {
  description = "Secret that is created with the database password"
  value       = length(var.password_secret) == 0 ? kubernetes_secret.postgresql[0].metadata[0].name : var.password_secret
}

output "password_key" {
  description = "Key for the database password in the secret"
  value       = var.password_key
}

output "name" {
  description = "Database name"
  value       = var.name
  depends_on = [
    kubernetes_stateful_set.postgresql
  ]
}

output "username" {
  description = "Username that can login to the databse"
  value       = var.username
  depends_on = [
    kubernetes_stateful_set.postgresql
  ]
}

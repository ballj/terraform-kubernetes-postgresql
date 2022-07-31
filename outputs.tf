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
  value       = length(var.password_secret) == 0 ? kubernetes_secret_v1.postgresql[0].metadata[0].name : var.password_secret
}

output "password_key" {
  description = "Key for the database password in the secret"
  value       = var.password_key
}

output "name" {
  description = "Database name"
  value       = var.name
  depends_on  = [
    kubernetes_stateful_set_v1.postgresql
  ]
}

output "username" {
  description = "Username that can login to the databse"
  value       = var.username
  depends_on  = [
    kubernetes_stateful_set_v1.postgresql
  ]
}

output "database_url" {
  depends_on = [random_password.password.0]
  value      = "postgres://${var.username}:${random_password.password.0.result}@${kubernetes_service_v1.postgresql.metadata[0].name}.${var.namespace}.svc.cluster.local:5432/${var.name}"
}
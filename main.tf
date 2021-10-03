locals {
  selector_labels = {
    "app.kubernetes.io/name"     = "postgresql"
    "app.kubernetes.io/instance" = "master"
    "app.kubernetes.io/part-of"  = lookup(var.labels, "app.kubernetes.io/part-of", var.object_prefix)
  }
  common_labels = merge(var.labels, local.selector_labels, {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/component"  = "postgresql"
  })
}

resource "kubernetes_stateful_set" "postgresql" {
  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }
  metadata {
    namespace = var.namespace
    name      = var.object_prefix
    labels    = local.common_labels
  }
  wait_for_rollout = var.wait_for_rollout
  spec {
    pod_management_policy  = var.pod_management_policy
    replicas               = 1
    revision_history_limit = var.revision_history
    service_name           = kubernetes_service.postgresql.metadata[0].name
    selector {
      match_labels = local.selector_labels
    }
    update_strategy {
      type = var.update_strategy
      dynamic "rolling_update" {
        for_each = var.update_strategy == "RollingUpdate" ? [1] : []
        content {
          partition = var.update_partition
        }
      }
    }
    template {
      metadata {
        labels = local.selector_labels
      }
      spec {
        dynamic "security_context" {
          for_each = var.security_context_enabled ? [1] : []
          content {
            run_as_non_root = true
            run_as_user     = var.security_context_uid
            run_as_group    = var.security_context_gid
            fs_group        = var.security_context_gid
          }
        }
        container {
          image = format("%s:%s", var.image_name, var.image_tag)
          name  = regex("[[:alnum:]]+$", var.image_name)
          port {
            name           = "sql"
            protocol       = "TCP"
            container_port = kubernetes_service.postgresql.spec[0].port[0].target_port
          }
          env {
            name  = "BITNAMI_DEBUG"
            value = false
          }
          env {
            name  = "POSTGRESQL_PORT_NUMBER"
            value = kubernetes_service.postgresql.spec[0].port[0].target_port
          }
          env {
            name  = "POSTGRESQL_DATABASE"
            value = var.name
          }
          env {
            name  = "POSTGRESQL_USERNAME"
            value = var.username
          }
          env {
            name = "POSTGRESQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = length(var.password_secret) == 0 ? kubernetes_secret.postgresql[0].metadata[0].name : var.password_secret
                key  = var.password_key
              }
            }
          }
          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
          dynamic "env" {
            for_each = [for env_var in var.env_secret : {
              name   = env_var.name
              secret = env_var.secret
              key    = env_var.key
            }]
            content {
              name = env.value["name"]
              value_from {
                secret_key_ref {
                  name = env.value["secret"]
                  key  = env.value["key"]
                }
              }
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/bitnami/postgresql"
          }
          dynamic "readiness_probe" {
            for_each = var.readiness_probe_enabled ? [1] : []
            content {
              initial_delay_seconds = var.readiness_probe_initial_delay
              period_seconds        = var.readiness_probe_period
              timeout_seconds       = var.readiness_probe_timeout
              success_threshold     = var.readiness_probe_success
              failure_threshold     = var.readiness_probe_failure
              exec {
                command = ["sh", "-c", "exec pg_isready -U $${POSTGRESQL_USERNAME} -d dbname=$${POSTGRESQL_DATABASE} -h 127.0.0.1 -p $${POSTGRESQL_PORT_NUMBER}"]
              }
            }
          }
          dynamic "liveness_probe" {
            for_each = var.liveness_probe_enabled ? [1] : []
            content {
              initial_delay_seconds = var.liveness_probe_initial_delay
              period_seconds        = var.liveness_probe_period
              timeout_seconds       = var.liveness_probe_timeout
              success_threshold     = var.liveness_probe_success
              failure_threshold     = var.liveness_probe_failure
              exec {
                command = ["sh", "-c", "exec pg_isready -U $${POSTGRESQL_USERNAME} -d dbname=$${POSTGRESQL_DATABASE} -h 127.0.0.1 -p $${POSTGRESQL_PORT_NUMBER}"]
              }
            }
          }
          dynamic "startup_probe" {
            for_each = var.startup_probe_enabled ? [1] : []
            content {
              initial_delay_seconds = var.startup_probe_initial_delay
              period_seconds        = var.startup_probe_period
              timeout_seconds       = var.startup_probe_timeout
              success_threshold     = var.startup_probe_success
              failure_threshold     = var.startup_probe_failure
              exec {
                command = ["sh", "-c", "exec pg_isready -U $${POSTGRESQL_USERNAME} -d dbname=$${POSTGRESQL_DATABASE} -h 127.0.0.1 -p $${POSTGRESQL_PORT_NUMBER}"]
              }
            }
          }
        }
        volume {
          name = "data"
          dynamic "empty_dir" {
            for_each = length(var.pvc_name) > 0 ? [] : [1]
            content {
              medium     = var.empty_dir_medium
              size_limit = var.empty_dir_size
            }
          }
          dynamic "persistent_volume_claim" {
            for_each = length(var.pvc_name) > 0 ? [1] : []
            content {
              claim_name = var.pvc_name
              read_only  = false
            }
          }
        }
        volume {
          name = "conf"
          empty_dir {
            medium     = "Memory"
            size_limit = "5Mi"
          }
        }
        volume {
          name = "logs"
          empty_dir {
            medium     = "Memory"
            size_limit = "5Mi"
          }
        }
        volume {
          name = "tmp"
          empty_dir {
            medium     = "Memory"
            size_limit = "5Mi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgresql" {
  metadata {
    namespace   = var.namespace
    name        = var.object_prefix
    labels      = local.common_labels
    annotations = var.service_annotations
  }
  spec {
    selector                = local.selector_labels
    session_affinity        = var.service_session_affinity
    type                    = var.service_type
    external_traffic_policy = contains(["LoadBalancer", "NodePort"], var.service_type) ? var.service_traffic_policy : null
    port {
      name        = "sql"
      protocol    = "TCP"
      target_port = 5432
      port        = var.service_port
    }
  }
}

resource "kubernetes_secret" "postgresql" {
  count = length(var.password_secret) == 0 ? 1 : 0
  metadata {
    namespace = var.namespace
    name      = var.object_prefix
    labels    = local.common_labels
  }
  data = {
    (var.password_key) = random_password.password[0].result
  }
}

resource "random_password" "password" {
  count   = length(var.password_secret) == 0 ? 1 : 0
  length  = 16
  special = false
}

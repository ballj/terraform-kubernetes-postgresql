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
  password_file = anytrue([
    contains(keys(var.env), "POSTGRES_PASSWORD_FILE"),
    contains(keys(var.env), "POSTGRES_USERDB_PASSWORD_FILE"),
  ]) ? true : false
  create_password = anytrue([local.password_file, length(var.password_secret) > 0]) ? false : true
  env_secret = local.password_file ? var.env_secret : flatten([[
    {
      name   = "POSTGRES_PASSWORD",
      secret = length(var.password_secret) == 0 ? kubernetes_secret_v1.postgresql[0].metadata[0].name : var.password_secret,
      key    = var.password_key_root
    },
    {
      name   = "POSTGRES_USERDB_PASSWORD",
      secret = length(var.password_secret) == 0 ? kubernetes_secret_v1.postgresql[0].metadata[0].name : var.password_secret,
      key    = var.password_key
    }
  ], var.env_secret])
}

resource "kubernetes_stateful_set_v1" "postgresql" {
  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }
  metadata {
    namespace   = var.namespace
    name        = var.object_prefix
    labels      = local.common_labels
    annotations = var.annotations
  }
  wait_for_rollout = var.wait_for_rollout
  spec {
    pod_management_policy  = var.pod_management_policy
    replicas               = var.replicas
    revision_history_limit = var.revision_history
    service_name           = kubernetes_service_v1.postgresql.metadata[0].name
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
        labels      = local.selector_labels
        annotations = var.template_annotations
      }
      spec {
        service_account_name = length(var.service_account_name) > 0 ? var.service_account_name : null
        dynamic "security_context" {
          for_each = var.security_context_enabled ? [1] : []
          content {
            run_as_non_root = true
            run_as_user     = var.security_context_uid
            run_as_group    = var.security_context_gid
            fs_group        = var.security_context_gid
          }
        }
        init_container {
          name    = "init-chmod-data"
          image   = format("%s:%s", var.init_image_name, var.init_image_tag)
          command = ["sh", "-c", "chown -R ${var.security_context_uid}:${var.security_context_gid} /var/lib/postgresql"]
          security_context {
            run_as_user = 0
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql"
          }
        }
        container {
          image = format("%s:%s", var.image_name, var.image_tag)
          name  = regex("[[:alnum:]]+$", var.image_name)
          resources {
            limits = {
              cpu    = var.resources_limits_cpu
              memory = var.resources_limits_memory
            }
            requests = {
              cpu    = var.resources_requests_cpu
              memory = var.resources_requests_memory
            }
          }
          port {
            name           = "sql"
            protocol       = "TCP"
            container_port = kubernetes_service_v1.postgresql.spec[0].port[0].target_port
          }
          env {
            name  = "POSTGRES_DB"
            value = var.name
          }
          env {
            name  = "POSTGRES_USER"
            value = var.admin_username
          }
          env {
            name  = "POSTGRES_USERDB_USERNAME"
            value = var.username
          }
          dynamic "env" {
            for_each = var.env
            content {
              name  = env.key
              value = env.value
            }
          }
          dynamic "env" {
            for_each = [for env_var in local.env_secret : {
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
            mount_path = "/var/lib/postgresql"
          }
          volume_mount {
            name       = "init"
            mount_path = "/docker-entrypoint-initdb.d"
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
                command = ["sh", "-c", "exec pg_isready -U $${POSTGRES_USER} -d dbname=$${POSTGRES_DB} -h 127.0.0.1 -p 5432"]
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
                command = ["sh", "-c", "exec pg_isready -U $${POSTGRES_USER} -d dbname=$${POSTGRES_DB} -h 127.0.0.1 -p 5432"]
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
                command = ["sh", "-c", "exec pg_isready -U $${POSTGRES_USER} -d dbname=$${POSTGRES_DB} -h 127.0.0.1 -p 5432"]
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
          name = "init"
          config_map {
            name         = kubernetes_config_map_v1.postgresql_init.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "postgresql" {
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

resource "kubernetes_secret_v1" "postgresql" {
  count = local.create_password ? 1 : 0
  metadata {
    namespace = var.namespace
    name      = var.object_prefix
    labels    = local.common_labels
  }
  data = {
    (var.password_key_root) = random_password.root_password[0].result
    (var.password_key)      = random_password.password[0].result
  }
}

resource "random_password" "root_password" {
  count   = local.create_password ? 1 : 0
  length  = var.password_autocreate_length
  special = var.password_autocreate_special
}

resource "random_password" "password" {
  count   = local.create_password ? 1 : 0
  length  = var.password_autocreate_length
  special = var.password_autocreate_special
}

resource "kubernetes_config_map_v1" "postgresql_init" {
  metadata {
    namespace = var.namespace
    name      = "${var.object_prefix}-init"
    labels    = local.common_labels
  }
  data = {
    "init.sh" = <<-EOT
      #!/bin/bash
      set -e

      if [ -n "$${POSTGRES_USERDB_USERNAME_FILE}" ] && [ -z "$${POSTGRES_USERDB_USERNAME}" ]; then
        POSTGRES_USERDB_USERNAME=$(< "$${POSTGRES_USERDB_USERNAME_FILE}")
      fi
      if [ -n "$${POSTGRES_USERDB_PASSWORD_FILE}" ] && [ -z "$${POSTGRES_USERDB_PASSWORD}" ]; then
        POSTGRES_USERDB_PASSWORD=$(< "$${POSTGRES_USERDB_PASSWORD_FILE}")
      fi

      psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
      DO \$\$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$POSTGRES_USERDB_USERNAME') THEN
          CREATE USER "$POSTGRES_USERDB_USERNAME" WITH PASSWORD '$POSTGRES_USERDB_PASSWORD';
        END IF;
      END
      \$\$;
      GRANT ALL PRIVILEGES ON DATABASE "$POSTGRES_DB" TO "$POSTGRES_USERDB_USERNAME";
      GRANT ALL PRIVILEGES ON SCHEMA public TO "$POSTGRES_USERDB_USERNAME";
      EOSQL
    EOT
  }
}

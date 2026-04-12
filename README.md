# Terraform Kubernetes PostgreSQL

This terraform module deploys a PostgreSQL statefulset into a kubernetes
cluster using the official PostgreSQL image.

## Usage

```
module "postgresql" {
  source        = "ballj/postgresql/kubernetes"
  version       = "~> 1.2"
  namespace     = "production"
  object_prefix = "myapp-db"
  name          = "myapp_db"
  labels        = {
    "app.kubernetes.io/part-of" = "myapp"
  }
}
```

## Variables

### StatefulSets Variables

| Variable                          | Required | Default                     | Description                                        |
| --------------------------------- | -------- | --------------------------- | -------------------------------------------------- |
| `namespace`                       | Yes      | N/A                         | Kubernetes namespace to deploy into                |
| `object_prefix`                   | Yes      | N/A                         | Unique name to prefix all objects with             |
| `name`                            | Yes      | N/A                         | Database to create on startup                      |
| `username`                        | No       | `dbuser`                    | Database user to add                               |
| `password_secret`                 | No       | `""`                        | Database secret containing passwords - See below   |
| `password_key`                    | No       | `password`                  | Database key containing user password              |
| `labels`                          | No       | N/A                         | Common labels to add to all objects - See example  |
| `image_name`                      | No       | `postgres`                  | Image to deploy as part of deployment              |
| `image_tag`                       | No       | `18.3`                      | Image tag to deploy                                |
| `init_image_name`                 | No       | `busybox`                   | Image to use for the init container                |
| `init_image_tag`                  | No       | `stable`                    | Image tag to use for the init container            |
| `service_account_name`            | No       | `""`                        | Service account to attach to the pod               |
| `timeout_create`                  | No       | `3m`                        | Timeout for creating the deployment                |
| `timeout_update`                  | No       | `2m`                        | Timeout for updating the deployment                |
| `timeout_delete`                  | No       | `10m`                       | Timeout for deleting the deployment                |
| `annotations`                     | No       | `{}`                        | Annotations to add to the statefulset              |
| `template_annotations`            | No       | `{}`                        | Annotations to add to the template (recreate pods) |
| `resources_requests_cpu`          | No       | `null`                      | The minimum amount of compute resources required   |
| `resources_requests_memory`       | No       | `null`                      | The minimum amount of compute resources required   |
| `resources_limits_cpu`            | No       | `null`                      | The maximum amount of compute resources allowed    |
| `resources_limits_memory`         | No       | `null`                      | The maximum amount of compute resources allowed    |
| `wait_for_rollout`                | No       | `true`                      | Wait for the StatefulSet to finish rolling out     |
| `pod_management_policy`           | No       | `OrderedReady`              | Controls how pods are created during scaling       |
| `update_strategy`                 | No       | `RollingUpdate`             | Strategy to use, `OnDelete` or `RollingUpdate`     |
| `update_partition`                | No       | `"0"`                       | Ordinal at which the set should be partitioned     |
| `revision_history`                | No       | `4`                         | Number of ReplicaSets to retain                    |
| `pvc_name`                        | No       | `""`                        | Name of the PVC to mount for persistent storage    |
| `empty_dir_medium`                | No       | `""`                        | Medium of empty_dir if no PVC is specified         |
| `empty_dir_size`                  | No       | `0`                         | Size of empty_dir created if no pvc is specified   |
| `security_context_enabled`        | No       | `true`                      | Prevents deployment from running as root           |
| `security_context_uid`            | No       | `999`                       | UID of the `postgres` user in the image            |
| `security_context_gid`            | No       | `999`                       | GID of the `postgres` user in the image            |
| `env`                             | No       | `{}`                        | Environment variables to add                       |
| `env_secret`                      | No       | `[]`                        | Environmentvariables to add from secrets           |
| `password_autocreate_length`      | No       | `16`                        | Length of the automatically generated password     |
| `password_autocreate_special`     | No       | `false`                     | Use special characters in the generated password   |
| `readiness_probe_enabled`         | No       | `true`                      | Enable the readyness probe                         |
| `readiness_probe_initial_delay`   | No       | `30`                        | Initial delay of the probe in seconds              |
| `readiness_probe_period`          | No       | `10`                        | Period of the probe in seconds                     |
| `readiness_probe_timeout`         | No       | `1`                         | Timeout of the probe in seconds                    |
| `readiness_probe_success`         | No       | `1`                         | Minimum consecutive successes for the probe        |
| `readiness_probe_failure`         | No       | `3`                         | Minimum consecutive failures for the probe         |
| `liveness_probe_enabled`          | No       | `true`                      | Enable the readyness probe                         |
| `liveness_probe_initial_delay`    | No       | `30`                        | Initial delay of the probe in seconds              |
| `liveness_probe_period`           | No       | `10`                        | Period of the probe in seconds                     |
| `liveness_probe_timeout`          | No       | `1`                         | Timeout of the probe in seconds                    |
| `liveness_probe_success`          | No       | `1`                         | Minimum consecutive successes for the probe        |
| `liveness_probe_failure`          | No       | `3`                         | Minimum consecutive failures for the probe         |
| `startup_probe_enabled`           | No       | `true`                      | Enable the readyness probe                         |
| `startup_probe_initial_delay`     | No       | `30`                        | Initial delay of the probe in seconds              |
| `startup_probe_period`            | No       | `10`                        | Period of the probe in seconds                     |
| `startup_probe_timeout`           | No       | `1`                         | Timeout of the probe in seconds                    |
| `startup_probe_success`           | No       | `1`                         | Minimum consecutive successes for the probe        |
| `startup_probe_failure`           | No       | `3`                         | Minimum consecutive failures for the probe         |

### Service Variables

| Variable                          | Required | Default                     | Description                                        |
| --------------------------------- | -------- | --------------------------- | -------------------------------------------------- |
| `service_type`                    | No       | `ClusterIP`                 | Service type to deploy                             |
| `service_port`                    | No       | `5432`                      | External port for service                          |
| `service_annotations`             | No       | `{}`                        | Annotations to add to service                      |
| `service_session_affinity`        | No       | `None`                      | Session persistence setting                        |
| `service_traffic_policy`          | No       | `Local`                     | External traffic policy - `Local` or `External`    |
| `labels`                          | No       | N/A                         | Common labels to add to all objects - See example  |

## Outputs

| Output            | Description                                          |
| ----------------- | ---------------------------------------------------- |
| `hostname`        | Name of the Kubernetes service                       |
| `port`            | Port of the Kubernetes service                       |
| `password_secret` | Name of the secret containing the database password  |
| `password_key`    | Key for the database password in the secret          |
| `name`            | Database name                                        |
| `username`        | Username that can login to the database              |

## Persistence

Persistence is achieved by mounting PVCs into the container. This is achieved by
providing a PVC name in the `pvc_name` variable.

## Passwords

The module supports 3 password mechanisms:
1. Pass a file using an injector such as vault-injector via
   `POSTGRES_PASSWORD_FILE` environment variable
2. Pass the secret name to the variable `password_secret`
3. Let the module auto generate a secret and output the name

## Environment Variables

Environment variables can be set by providing a map to the `env` variable:

```
module "postgresql" {
  source        = "ballj/postgresql/kubernetes"
  version       = "~> 1.0"
  namespace     = "production"
  object_prefix = "myapp-db"
  env = {
    ENV_A = "ENVVAR"
    ENV_B = "1"
  }
}
```

### Secrets

Secrets can be added by using the `env_secret` variable:

```
module "postgresql" {
  source        = "ballj/postgresql/kubernetes"
  version       = "~> 1.0"
  namespace     = "production"
  object_prefix = "myapp-db"
  env_secret = [
    {
      name   = "ENV_VAR"
      secret = "app-secret"
      key    = "username"
    }
  ]
}
```

## Migration

### V2

This release upgrades PostgreSQL from version 13 to 18. Due to the large version
difference, an in-place upgrade is not supported. A full data export and import
must be performed before upgrading the module.

The kubernetes resources have been moved to the `_v1` version. Terraform will
automatically delete the old ones first but fail to create the new ones in the
same run. Run Terraform a second time to create the new resources.

Environment variables will need to be updated, follow the official docker container
for more info.

`INITSCRIPT` environment variables will not work anymore.

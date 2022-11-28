# Terraform Kubernetes PostgreSQL

This terraform module deploys a PostgreSQL statefulset into a kubernetes cluster.

## Useage

```
module "postgresql" {
  source        = "ballj/postgresql/kubernetes"
  version       = "~> 1.2"
  namespace     = "production"
  object_prefix = "myapp-db"
  database_name = "myapp_db"
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
| `database_name`                   | Yes      | N/A                         | Database to create on startup                      |
| `username`                        | No       | `dbuser`                    | Database user to add                               |
| `password_secret`                 | No       | `""`                        | Database secret containing passwords - See below   |
| `password_key`                    | No       | `password`                  | Database key containing user password              |
| `labels`                          | No       | N/A                         | Common labels to add to all objects - See example  |
| `image_name`                      | No       | `bitnami/postgresql`        | Image to deploy as part of deployment              |
| `image_tag`                       | No       | `13.3.0-debian-10-r12`      | Image tag to deploy                                |
| `service_account_name`            | No       | `""`                        | Service account to attach to the pod               |
| `timeout_create`                  | No       | `3m`                        | Timeout for creating the deployment                |
| `timeout_update`                  | No       | `3m`                        | Timeout for updating the deployment                |
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
| `update_partition`                | No       | `[]`                        | Ordinal at which the set should be partitioned     |
| `min_ready_seconds`               | No       | `1`                         | Minimum time to consider pods ready                |
| `max_ready_seconds`               | No       | `600`                       | Maximum time for pod to be ready before failure    |
| `revision_history`                | No       | `4`                         | Number of ReplicaSets to retain                    |
| `pvc_name`                        | No       | `""`                        | Name of the PVC to mount for persistent storage    |
| `empty_dir_medium`                | No       | `""`                        | Medium of empty_dir if no PVC is specified         |
| `empty_dir_size`                  | No       | `""`                        | Size of empty_dir created if no pvc is specified   |
| `security_context_enabled`        | No       | `true`                      | Prevents deployment from running as root           |
| `security_context_uid`            | No       | `1001`                      | User to run deployment as                          |
| `security_context_uid`            | No       | `1001`                      | Group to run deployment as                         |
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

## Persistence

Persistance is achieved by mounting PVCs into the container. This is achieve by
providing a PVC name in the `pvc_name` variable.

## Passwords

The module supports 3 password mechanisms:
1. Pass a file using an injector such as vault-injector and using env variable
2. Pass the secret name to the variable `password_secret`
3. Let the module auto generate a secret and output the name

## Environment Variables

Environment variables can be set by providing a map to the `env` variable:

```
module "redis" {
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
module "redis" {
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


## Issues

The image must be run with `security_context_gid` set to 0 otherwise it does
not create the database correctly. This looks to be in progress in
[issue 242](https://github.com/bitnami/bitnami-docker-postgresql/issues/242).

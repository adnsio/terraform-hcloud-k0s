# resource "kubernetes_csi_driver_v1" "csi_hetzner_cloud" {
#   metadata {
#     name = "csi.hetzner.cloud"
#   }

#   spec {
#     attach_required        = true
#     pod_info_on_mount      = true
#     volume_lifecycle_modes = ["Persistent"]
#   }
# }

# resource "kubernetes_storage_class_v1" "hcloud_volumes" {
#   metadata {
#     name = "hcloud-volumes"

#     annotations = {
#       "storageclass.kubernetes.io/is-default-class" = "true"
#     }
#   }

#   allow_volume_expansion = true
#   volume_binding_mode    = "WaitForFirstConsumer"
#   storage_provisioner    = "csi.hetzner.cloud"
# }

# resource "kubernetes_service_account_v1" "hcloud_csi" {
#   metadata {
#     name      = "hcloud-csi"
#     namespace = "kube-system"
#   }
# }

# resource "kubernetes_cluster_role_v1" "hcloud_csi" {
#   metadata {
#     name = "hcloud-csi"
#   }

#   rule {
#     verbs      = ["get", "list", "watch", "update", "patch"]
#     api_groups = [""]
#     resources  = ["persistentvolumes"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch"]
#     api_groups = [""]
#     resources  = ["nodes"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch"]
#     api_groups = ["csi.storage.k8s.io"]
#     resources  = ["csinodeinfos"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch"]
#     api_groups = ["storage.k8s.io"]
#     resources  = ["csinodes"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch", "update", "patch"]
#     api_groups = ["storage.k8s.io"]
#     resources  = ["volumeattachments"]
#   }

#   rule {
#     verbs      = ["patch"]
#     api_groups = ["storage.k8s.io"]
#     resources  = ["volumeattachments/status"]
#   }

#   rule {
#     verbs      = ["get", "list"]
#     api_groups = [""]
#     resources  = ["secrets"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch", "create", "delete", "patch"]
#     api_groups = [""]
#     resources  = ["persistentvolumes"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch", "update", "patch"]
#     api_groups = [""]
#     resources  = ["persistentvolumeclaims", "persistentvolumeclaims/status"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch"]
#     api_groups = ["storage.k8s.io"]
#     resources  = ["storageclasses"]
#   }

#   rule {
#     verbs      = ["list", "watch", "create", "update", "patch"]
#     api_groups = [""]
#     resources  = ["events"]
#   }

#   rule {
#     verbs      = ["get", "list"]
#     api_groups = ["snapshot.storage.k8s.io"]
#     resources  = ["volumesnapshots"]
#   }

#   rule {
#     verbs      = ["get", "list"]
#     api_groups = ["snapshot.storage.k8s.io"]
#     resources  = ["volumesnapshotcontents"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch"]
#     api_groups = [""]
#     resources  = ["pods"]
#   }

#   rule {
#     verbs      = ["get", "list", "watch", "create", "update", "patch"]
#     api_groups = [""]
#     resources  = ["events"]
#   }
# }

# resource "kubernetes_cluster_role_binding_v1" "hcloud_csi" {
#   metadata {
#     name = "hcloud-csi"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "hcloud-csi"
#     namespace = "kube-system"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "hcloud-csi"
#   }
# }

# resource "kubernetes_stateful_set_v1" "hcloud_csi_controller" {
#   metadata {
#     name      = "hcloud-csi-controller"
#     namespace = "kube-system"
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "hcloud-csi-controller"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "hcloud-csi-controller"
#         }
#       }

#       spec {
#         volume {
#           name = "socket-dir"
#           empty_dir {}
#         }

#         container {
#           name  = "csi-attacher"
#           image = "k8s.gcr.io/sig-storage/csi-attacher:v3.2.1"

#           volume_mount {
#             name       = "socket-dir"
#             mount_path = "/run/csi"
#           }

#           security_context {
#             capabilities {
#               add = ["SYS_ADMIN"]
#             }

#             privileged                 = true
#             allow_privilege_escalation = true
#           }
#         }

#         container {
#           name  = "csi-resizer"
#           image = "k8s.gcr.io/sig-storage/csi-resizer:v1.2.0"

#           volume_mount {
#             name       = "socket-dir"
#             mount_path = "/run/csi"
#           }

#           security_context {
#             capabilities {
#               add = ["SYS_ADMIN"]
#             }

#             privileged                 = true
#             allow_privilege_escalation = true
#           }
#         }

#         container {
#           name  = "csi-provisioner"
#           image = "k8s.gcr.io/sig-storage/csi-provisioner:v2.2.2"
#           args  = ["--feature-gates=Topology=true", "--default-fstype=ext4"]

#           volume_mount {
#             name       = "socket-dir"
#             mount_path = "/run/csi"
#           }

#           security_context {
#             capabilities {
#               add = ["SYS_ADMIN"]
#             }

#             privileged                 = true
#             allow_privilege_escalation = true
#           }
#         }

#         container {
#           name  = "hcloud-csi-driver"
#           image = "hetznercloud/hcloud-csi-driver:1.6.0"

#           port {
#             name           = "metrics"
#             container_port = 9189
#           }

#           port {
#             name           = "healthz"
#             container_port = 9808
#             protocol       = "TCP"
#           }

#           env {
#             name  = "CSI_ENDPOINT"
#             value = "unix:///run/csi/socket"
#           }

#           env {
#             name  = "METRICS_ENDPOINT"
#             value = "0.0.0.0:9189"
#           }

#           env {
#             name  = "ENABLE_METRICS"
#             value = "true"
#           }

#           env {
#             name = "KUBE_NODE_NAME"

#             value_from {
#               field_ref {
#                 api_version = "v1"
#                 field_path  = "spec.nodeName"
#               }
#             }
#           }

#           env {
#             name = "HCLOUD_TOKEN"

#             value_from {
#               secret_key_ref {
#                 name = "hcloud"
#                 key  = "token"
#               }
#             }
#           }

#           volume_mount {
#             name       = "socket-dir"
#             mount_path = "/run/csi"
#           }

#           liveness_probe {
#             http_get {
#               path = "/healthz"
#               port = "healthz"
#             }

#             initial_delay_seconds = 10
#             timeout_seconds       = 3
#             period_seconds        = 2
#             failure_threshold     = 5
#           }

#           image_pull_policy = "Always"

#           security_context {
#             capabilities {
#               add = ["SYS_ADMIN"]
#             }

#             privileged                 = true
#             allow_privilege_escalation = true
#           }
#         }

#         container {
#           name  = "liveness-probe"
#           image = "k8s.gcr.io/sig-storage/livenessprobe:v2.3.0"

#           volume_mount {
#             name       = "socket-dir"
#             mount_path = "/run/csi"
#           }

#           image_pull_policy = "Always"
#         }
#       }
#     }

#     service_name = "hcloud-csi-controller"
#   }
# }

# resource "kubernetes_daemon_set_v1" "hcloud_csi_node" {
#   metadata {
#     name      = "hcloud-csi-node"
#     namespace = "kube-system"

#     labels = {
#       app = "hcloud-csi"
#     }
#   }

#   spec {
#     selector {
#       match_labels = {
#         app = "hcloud-csi"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "hcloud-csi"
#         }
#       }

#       spec {
#         volume {
#           name = "kubelet-dir"

#           host_path {
#             path = "/var/lib/k0s/kubelet"
#             type = "Directory"
#           }
#         }

#         volume {
#           name = "plugin-dir"

#           host_path {
#             path = "/var/lib/k0s/kubelet/plugins/csi.hetzner.cloud/"
#             type = "DirectoryOrCreate"
#           }
#         }

#         volume {
#           name = "registration-dir"

#           host_path {
#             path = "/var/lib/k0s/kubelet/plugins_registry/"
#             type = "Directory"
#           }
#         }

#         volume {
#           name = "device-dir"

#           host_path {
#             path = "/dev"
#             type = "Directory"
#           }
#         }

#         container {
#           name  = "csi-node-driver-registrar"
#           image = "k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.2.0"
#           args  = ["--kubelet-registration-path=/var/lib/k0s/kubelet/plugins/csi.hetzner.cloud/socket"]

#           env {
#             name = "KUBE_NODE_NAME"

#             value_from {
#               field_ref {
#                 api_version = "v1"
#                 field_path  = "spec.nodeName"
#               }
#             }
#           }

#           volume_mount {
#             name       = "plugin-dir"
#             mount_path = "/run/csi"
#           }

#           volume_mount {
#             name       = "registration-dir"
#             mount_path = "/registration"
#           }

#           security_context {
#             privileged = true
#           }
#         }

#         container {
#           name  = "hcloud-csi-driver"
#           image = "hetznercloud/hcloud-csi-driver:1.6.0"

#           port {
#             name           = "metrics"
#             container_port = 9189
#           }

#           port {
#             name           = "healthz"
#             container_port = 9808
#             protocol       = "TCP"
#           }

#           env {
#             name  = "CSI_ENDPOINT"
#             value = "unix:///run/csi/socket"
#           }

#           env {
#             name  = "METRICS_ENDPOINT"
#             value = "0.0.0.0:9189"
#           }

#           env {
#             name  = "ENABLE_METRICS"
#             value = "true"
#           }

#           env {
#             name = "HCLOUD_TOKEN"

#             value_from {
#               secret_key_ref {
#                 name = "hcloud"
#                 key  = "token"
#               }
#             }
#           }

#           env {
#             name = "KUBE_NODE_NAME"

#             value_from {
#               field_ref {
#                 api_version = "v1"
#                 field_path  = "spec.nodeName"
#               }
#             }
#           }

#           volume_mount {
#             name              = "kubelet-dir"
#             mount_path        = "/var/lib/k0s/kubelet"
#             mount_propagation = "Bidirectional"
#           }

#           volume_mount {
#             name       = "plugin-dir"
#             mount_path = "/run/csi"
#           }

#           volume_mount {
#             name       = "device-dir"
#             mount_path = "/dev"
#           }

#           liveness_probe {
#             http_get {
#               path = "/healthz"
#               port = "healthz"
#             }

#             initial_delay_seconds = 10
#             timeout_seconds       = 3
#             period_seconds        = 2
#             failure_threshold     = 5
#           }

#           image_pull_policy = "Always"

#           security_context {
#             privileged = true
#           }
#         }

#         container {
#           name  = "liveness-probe"
#           image = "k8s.gcr.io/sig-storage/livenessprobe:v2.3.0"

#           volume_mount {
#             name       = "plugin-dir"
#             mount_path = "/run/csi"
#           }

#           image_pull_policy = "Always"
#         }

#         affinity {
#           node_affinity {
#             required_during_scheduling_ignored_during_execution {
#               node_selector_term {
#                 match_expressions {
#                   key      = "instance.hetzner.cloud/is-root-server"
#                   operator = "NotIn"
#                   values   = ["true"]
#                 }
#               }
#             }
#           }
#         }

#         toleration {
#           operator = "Exists"
#           effect   = "NoExecute"
#         }

#         toleration {
#           operator = "Exists"
#           effect   = "NoSchedule"
#         }

#         toleration {
#           key      = "CriticalAddonsOnly"
#           operator = "Exists"
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service_v1" "hcloud_csi_controller_metrics" {
#   metadata {
#     name      = "hcloud-csi-controller-metrics"
#     namespace = "kube-system"

#     labels = {
#       app = "hcloud-csi"
#     }
#   }

#   spec {
#     port {
#       name        = "metrics"
#       port        = 9189
#       target_port = "metrics"
#     }

#     selector = {
#       app = "hcloud-csi-controller"
#     }
#   }
# }

# resource "kubernetes_service_v1" "hcloud_csi_node_metrics" {
#   metadata {
#     name      = "hcloud-csi-node-metrics"
#     namespace = "kube-system"

#     labels = {
#       app = "hcloud-csi"
#     }
#   }

#   spec {
#     port {
#       name        = "metrics"
#       port        = 9189
#       target_port = "metrics"
#     }

#     selector = {
#       app = "hcloud-csi"
#     }
#   }
# }

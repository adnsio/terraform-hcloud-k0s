# resource "kubernetes_service_account_v1" "cloud_controller_manager" {
#   metadata {
#     name      = "cloud-controller-manager"
#     namespace = "kube-system"
#   }
# }

# resource "kubernetes_cluster_role_binding_v1" "system_cloud_controller_manager" {
#   metadata {
#     name = "system:cloud-controller-manager"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "cloud-controller-manager"
#     namespace = "kube-system"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
# }

# resource "kubernetes_deployment_v1" "hcloud_cloud_controller_manager" {
#   metadata {
#     name      = "hcloud-cloud-controller-manager"
#     namespace = "kube-system"
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "hcloud-cloud-controller-manager"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "hcloud-cloud-controller-manager"
#         }
#       }

#       spec {
#         container {
#           name    = "hcloud-cloud-controller-manager"
#           image   = "hetznercloud/hcloud-cloud-controller-manager:v1.12.1"
#           command = ["/bin/hcloud-cloud-controller-manager", "--cloud-provider=hcloud", "--leader-elect=false", "--allow-untagged-cloud"]

#           env {
#             name = "NODE_NAME"

#             value_from {
#               field_ref {
#                 field_path = "spec.nodeName"
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

#           env {
#             name = "HCLOUD_NETWORK"

#             value_from {
#               secret_key_ref {
#                 name = "hcloud"
#                 key  = "network"
#               }
#             }
#           }

#           resources {
#             requests = {
#               cpu = "100m"

#               memory = "50Mi"
#             }
#           }
#         }

#         dns_policy           = "Default"
#         service_account_name = "cloud-controller-manager"

#         toleration {
#           key    = "node.cloudprovider.kubernetes.io/uninitialized"
#           value  = "true"
#           effect = "NoSchedule"
#         }

#         toleration {
#           key      = "CriticalAddonsOnly"
#           operator = "Exists"
#         }

#         toleration {
#           key    = "node-role.kubernetes.io/master"
#           effect = "NoSchedule"
#         }

#         toleration {
#           key    = "node-role.kubernetes.io/control-plane"
#           effect = "NoSchedule"
#         }

#         toleration {
#           key    = "node.kubernetes.io/not-ready"
#           effect = "NoSchedule"
#         }
#       }
#     }

#     revision_history_limit = 2
#   }
# }

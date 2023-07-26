locals {
  kubeconfig = yamldecode(k0s_cluster.cluster.kubeconfig)
}

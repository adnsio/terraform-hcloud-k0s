provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
  client_certificate     = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users[0].user.client-key-data)
  # host                   = null_resource.kubeconfig.triggers.host
  # cluster_ca_certificate = null_resource.kubeconfig.triggers.cluster_ca_certificate
  # client_certificate     = null_resource.kubeconfig.triggers.client_certificate
  # client_key             = null_resource.kubeconfig.triggers.client_key
}

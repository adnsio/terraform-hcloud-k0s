output "ipv4" {
  value = hcloud_load_balancer.load_balancer.ipv4
}

output "ipv6" {
  value = hcloud_load_balancer.load_balancer.ipv6
}

output "kubeconfig" {
  value     = k0s_cluster.cluster.kubeconfig
  sensitive = true
}

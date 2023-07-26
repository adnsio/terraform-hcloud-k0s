data "hcloud_location" "location" {
  name = var.location
}

resource "hcloud_network" "network" {
  name     = var.name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = data.hcloud_location.location.network_zone
  ip_range     = var.network_ip_range
}

resource "hcloud_load_balancer" "load_balancer" {
  name               = var.name
  load_balancer_type = var.load_balancer_type
  location           = var.location
}

resource "hcloud_load_balancer_network" "network" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  network_id       = hcloud_network.network.id
}

resource "hcloud_load_balancer_service" "kube_api" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "controller_join_api" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 9443
  destination_port = 9443
}

resource "hcloud_load_balancer_service" "konnectivity" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 8132
  destination_port = 8132
}

resource "hcloud_placement_group" "placement_group" {
  name = var.name
  type = "spread"
}

resource "hcloud_server" "controller" {
  count = var.controllers

  name               = "${var.name}-controller${count.index + 1}"
  image              = var.image
  server_type        = var.controller_type
  location           = var.location
  ssh_keys           = var.ssh_keys_ids
  placement_group_id = hcloud_placement_group.placement_group.id
}

resource "hcloud_server_network" "controller" {
  count = var.controllers

  server_id  = hcloud_server.controller[count.index].id
  network_id = hcloud_network.network.id
}

resource "hcloud_load_balancer_target" "controller" {
  count = var.controllers

  load_balancer_id = hcloud_load_balancer.load_balancer.id
  type             = "server"
  server_id        = hcloud_server.controller[count.index].id
  use_private_ip   = true

  depends_on = [
    hcloud_server_network.controller
  ]
}

resource "hcloud_server" "worker" {
  count = var.workers

  name               = "${var.name}-worker${count.index + 1}"
  image              = var.image
  server_type        = var.worker_type
  location           = var.location
  ssh_keys           = var.ssh_keys_ids
  placement_group_id = hcloud_placement_group.placement_group.id
  # user_data          = file("${path.module}/user-data.yaml")
}

resource "hcloud_server_network" "worker" {
  count = var.workers

  server_id  = hcloud_server.worker[count.index].id
  network_id = hcloud_network.network.id
}

resource "hcloud_server" "controller_worker" {
  count = var.controller_workers

  name               = "${var.name}-controller-worker${count.index + 1}"
  image              = var.image
  server_type        = var.controller_worker_type
  location           = var.location
  ssh_keys           = var.ssh_keys_ids
  placement_group_id = hcloud_placement_group.placement_group.id
  # user_data          = file("${path.module}/user-data.yaml")
}

resource "hcloud_server_network" "controller_worker" {
  count = var.controller_workers

  server_id  = hcloud_server.controller_worker[count.index].id
  network_id = hcloud_network.network.id
}

resource "hcloud_load_balancer_target" "controller_worker" {
  count = var.controller_workers

  load_balancer_id = hcloud_load_balancer.load_balancer.id
  type             = "server"
  server_id        = hcloud_server.controller_worker[count.index].id
  use_private_ip   = true

  depends_on = [
    hcloud_server_network.controller_worker
  ]
}

resource "k0s_cluster" "cluster" {
  name    = var.name
  version = var.k0s_version

  config = jsonencode({
    spec = {
      api = {
        externalAddress = hcloud_load_balancer.load_balancer.ipv4
        sans = [
          hcloud_load_balancer.load_balancer.ipv4
        ]
      }
      telemetry = {
        enabled = false
      }
    }
  })

  hosts = concat(
    [
      for i, server in hcloud_server.controller : {
        role            = "controller"
        private_address = hcloud_server_network.controller[i].ip

        install_flags = [
          "--disable-components ${join(",", var.disabled_components)}",
        ]

        ssh = {
          address  = server.ipv4_address
          port     = 22
          user     = "root"
          key_path = var.key_path
        }
      }
    ],
    [
      for i, server in hcloud_server.worker : {
        role            = "worker"
        private_address = hcloud_server_network.worker[i].ip

        install_flags = [
          "--enable-cloud-provider",
          "--kubelet-extra-args=\"--cloud-provider=external\""
        ]

        ssh = {
          address  = server.ipv4_address
          port     = 22
          user     = "root"
          key_path = var.key_path
        }
      }
    ],
    [
      for i, server in hcloud_server.controller_worker : {
        role            = "controller+worker"
        private_address = hcloud_server_network.controller_worker[i].ip
        no_taints       = true

        install_flags = [
          "--disable-components ${join(",", var.disabled_components)}",
          "--enable-cloud-provider",
          "--kubelet-extra-args=\"--cloud-provider=external\""
        ]

        ssh = {
          address  = server.ipv4_address
          port     = 22
          user     = "root"
          key_path = var.key_path
        }
      }
    ]
  )
}

# resource "null_resource" "kubeconfig" {
#   # depends_on = [k0s_cluster.cluster]
#   triggers = {
#     host                   = local.kubeconfig.clusters[0].cluster.server
#     cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
#     client_certificate     = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
#     client_key             = base64decode(local.kubeconfig.users[0].user.client-key-data)
#   }
# }

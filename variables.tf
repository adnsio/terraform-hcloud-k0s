variable "name" {
  type = string
}

variable "controllers" {
  type    = number
  default = 1
}

variable "controller_type" {
  type    = string
  default = "cx11"
}

variable "workers" {
  type    = number
  default = 1
}

variable "worker_type" {
  type    = string
  default = "cx11"
}

variable "controller_workers" {
  type    = number
  default = 0
}

variable "controller_worker_type" {
  type    = string
  default = "cx11"
}

variable "load_balancer_type" {
  type    = string
  default = "lb11"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "k0s_version" {
  type    = string
  default = "v1.27.4+k0s.0"
}

variable "ssh_keys_ids" {
  type = list(string)
}

variable "network_ip_range" {
  type    = string
  default = "10.0.0.0/24"
}

variable "image" {
  type    = string
  default = "debian-12"
}

variable "disabled_components" {
  type    = list(string)
  default = []
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "key_path" {
  type = string
}

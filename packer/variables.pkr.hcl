variable "pve_endpoint" {
  type = string
  default = "https://192.168.0.90:8006/api2/json"
}

variable "pve_username" {
  type    = string
  default = "root@pam"
}

variable "pve_password" {
  type = string
}

variable "pve_node" {
  type    = string
  default = "pve"
}

variable "pve_datastore" {
  type    = string
  default = "local-zfs"
}


variable "talos_image" {
  type = object({
    arch        = string
    platform    = string
    secureboot  = bool
    factory_url = string
    version     = string
  })
  default = {
    arch        = "amd64"
    platform    = "nocloud"
    secureboot  = false
    factory_url = "https://factory.talos.dev"
    version     = "v1.10.2"
  }
}

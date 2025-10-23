variable "pve_endpoint" {
  type = string
}

variable "pve_username" {
  type = string
}

variable "pve_password" {
  type = string
}


variable "controlplane_vm_nodes" {
  type = list(string)
}

variable "controlplane_vm_spec" {
  type = object({
    cores = number
    memory = number
    disk = object({
      size = number
      datastore_id = string
    })
    ip_config = {
      ipv4 = {
        subnet = string
        gateway = string
      }
      ipv6 = {
        subnet = string
        gateway = string
      }
    }
  })
}


variable "worker_vm_nodes" {
  type = list(string)
}

variable "worker_vm_spec" {
  type = object({
    cores = number
    memory = number
    disk = object({
      size = number
      datastore_id = string
    })
  })
}

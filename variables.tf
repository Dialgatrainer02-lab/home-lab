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
    cores  = number
    memory = number
    disk = object({
      size         = number
      datastore_id = string
    })
    ip_config = object({
      ipv4 = object({
        subnet  = string
        gateway = string
      })
      ipv6 = object({
        subnet  = string
        gateway = string
      })
    })
  })
}


variable "worker_vm_nodes" {
  type = list(string)
}

variable "worker_vm_spec" {
  type = object({
    node_name = optional(string)
    cores     = number
    memory    = number
    disk = object({
      size         = number
      datastore_id = string
    })
  })
}

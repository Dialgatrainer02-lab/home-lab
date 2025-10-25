variable "proxmox_vm_metadata" {
    type = object({
      name = string
      description = string
      tags = list(string)
      vm_id = optional(number)
      node_name = optional(string)
      on_boot = optional(bool, true)
      agent = optional(bool, false)
    })
    description = "metadata about the vm needed for its creation"
}

variable "proxmox_vm_user_account" {
  type = object({
    username = optional(string)
    password = optional(string)
  })
  default = {
    username = "test"
  }
}

variable "proxmox_vm_cpu" {
    type = object({
      cores = number
      type = optional(string, "host")
      flags = optional(list(string), [])
    })
    description = "vm cpu info"
}

variable "proxmox_vm_disks" {
    type = list(object({
      aio = optional(string, "io_uring")
      backup = optional(bool, false)
      cache = optional(string, "none")
      datastore_id = string
      file_format = string
      import_from = optional(string, null)
      interface = string
      iothread = optional(bool, false)
      size = optional(number, 32)
    }))
    description = "disk infomation"
}

variable "proxmox_vm_network" {
    type = object({
      dns = object({
        domain = string
        servers = list(string)
      })
      ip_config = object({
        ipv4 = object({
          address = string
          gateway = string
        })
        ipv6 = object({
          address = string
          gateway = string
        })
      })
      network_devices = optional(list(object({
        bridge = optional(string, "vmbr0")
        disconnected = optional(bool, false)
        firewall = optional(bool, false)
      })))
    })
}

variable "proxmox_vm_boot_image" {
  type = object({
    url = string
    file_name = optional(string)
    datastore_id = optional(string)
    decompression_algorithm = optional(string)
    content_type = optional(string, "import")
  })
  
}

variable "proxmox_vm_memory" {
    type = object({
      dedicated = number
      floating = optional(number, 0)
      shared = optional(number, 0)
    })
}

data "proxmox_virtual_environment_nodes" "available_nodes" {}

data "proxmox_virtual_environment_datastores" "avalible_datastores" {
  for_each = toset(data.proxmox_virtual_environment_nodes.available_nodes.names)
  node_name = each.key
}
locals {
  node_datastores = {for node in toset(data.proxmox_virtual_environment_nodes.available_nodes.names): node => data.proxmox_virtual_environment_datastores.avalible_datastores[node].datastores }
  local_datastore = {
    for node_name, datastores in local.node_datastores :
    node_name => (
      [for ds in datastores : ds.id if ds.id == "local-zfs"][0]
    )
  }
}

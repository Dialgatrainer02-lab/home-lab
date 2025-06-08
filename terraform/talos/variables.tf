variable "talos_version" {
  type    = string
  default = "v1.10.2"
}

variable "talos_platform" {
  type    = string
  default = "nocloud"
}

variable "talos_arch" {
  type    = string
  default = "amd64"
}

variable "talos_schematic_id" {
  type = string
}

variable "talos_secureboot" {
  type    = bool
  default = true
}

variable "talos_cluster_endpoint_ip" {
  type = string
  nullable = true
  default = ""
}


variable "talos_cluster_name" {
  type    = string
  default = "homelab"
}

variable "talos_vm_template" {
  type = object({
    vm_id       = string
    source_node = string
  })
}


variable "talos_cluster_nodes" {
  type = map(object({
    name = string
    type = string
    spec = optional(object({
      cpu = optional(object({
        cores = optional(number, 2)
        type  = optional(string, "host")
        }), {
        cores = 2
        type  = "host"
      })
      memory = optional(number, 2048)
      disks = optional(list(object({
        size      = optional(number, 20)
        datastore = optional(string, "local-zfs")
        interface = optional(string, "virtio1")
        iothreads = optional(bool, true)
      })), [])
      efi_config = optional(object({
        datastore       = optional(string, "local-zfs")
        pre_enroll_keys = optional(bool, false)
        }), {
        datastore       = "local-zfs"
        pre_enroll_keys = false
      })
    }))
    network = object({
      ipv4 = optional(object({
        cidr = optional(string)
        host = optional(number)
        gw   = optional(string)
      }), {})
      ipv6 = optional(object({
        cidr = optional(string)
        host = optional(number)
        gw   = optional(string)
      }), {})
      name_servers = optional(list(string), ["1.1.1.1", "8.8.8.8"])
    })
  }))

  default = {
    "control0" = {
      name = "controlplane0"
      type = "controlplane"
      spec = {
        cpu = {
          cores = 2
          type  = "host"
        }
        memory = 2048
        # disks = []
        efi_config = {
          datastore       = "local-zfs"
          pre_enroll_keys = false
        }
      }
      network = {
        ipv4 = {
          cidr = "192.168.0.0/24"
          host = 97
          gw   = "192.168.0.1"
        }
      }
    },
    worker0 = {
      name = "worker0"
      type = "worker"
      spec = {
        disks = [{
          datastore = "local-zfs"
          interface = "virtio1"
          iothreads = true
          size      = 20
        }]
      }
      network = {
        ipv4 = {
          cidr = "192.168.0.0/24"
          host = 98
          gw   = "192.168.0.1"
        }
      }
    }
  }
}

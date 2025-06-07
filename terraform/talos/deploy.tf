# data "proxmox_virtual_environment_nodes" "nodes" {}
# data "proxmox_virtual_environment_datastores" "datastores" {
    # for_each = {for k,v in data.proxmox_virtual_environment_nodes.nodes: k => v.online == true}
#   node_name = node.value.name
# }

locals {
#   local_datastore = (coalesce(try(contains(data.proxmox_virtual_environment_datastores.datastores.datastores[*].id, "local-zfs"), null), try(contains(data.proxmox_virtual_environment_datastores.datastores.datastores[*].id, "local-lvm")), null))
    local_datastore = "local-zfs"
}

resource "proxmox_virtual_environment_vm" "talos_cluster" {
  for_each = var.talos_cluster_nodes

  name      = each.value.name
  tags      = [each.value.type, "talos"]
  node_name = "pve1" # round robin nodes eventually
  migrate   = true

  stop_on_destroy = true

  clone {
    node_name = var.talos_vm_template.source_node
    vm_id     = var.talos_vm_template.vm_id
  }

  scsi_hardware = "virtio-scsi-single"
  tablet_device = false

  dynamic "disk" {
    for_each = each.value.spec.disks

    content {
      datastore_id = disk.value.datastore
      iothread     = disk.value.iothreads
      interface    = disk.value.interface
      size         = disk.value.size
    }
  }

  dynamic "initialization" {
    for_each = var.talos_platform == "nocloud" ? [1] : [] # dont use cloud init if talos doesnt support it

    content {
      datastore_id = local.local_datastore
      ip_config {
        ipv4 {
          address = try(format("%s/%s", cidrhost(each.value.network.ipv4.cidr, each.value.network.ipv4.host), split("/", each.value.network.ipv4.cidr)[1]), null)
          gateway = try(each.value.network.ipv4.gw, null)
        }
        ipv6 {
          address = try(format("%s/%s", cidrhost(each.value.network.ipv6.cidr, each.value.network.ipv6.host), split("/", each.value.network.ipv6.cidr)[1]), null)
          gateway = try(each.value.network.ipv6.gw, null)
        }
      }
      dns {
        servers = each.value.network.name_servers
      }
    }
  }

  cpu {
    cores = each.value.spec.cpu.cores
    type  = each.value.spec.cpu.type
  }

  memory {
    dedicated = each.value.spec.memory
    floating  = 0
  }

  machine = "q35"
  bios    = "ovmf"

  operating_system {
    type = "l26"
  }

  timeout_clone = 3600

  efi_disk {
    datastore_id      = each.value.spec.efi_config.datastore
    pre_enrolled_keys = each.value.spec.efi_config.pre_enroll_keys
    type              = "4m"
  }

  tpm_state {
    datastore_id = local.local_datastore
  }
}


resource "talos_machine_configuration_apply" "cluster_config" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_cluster]
  for_each                    = var.talos_cluster_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = (each.value.type == "controlplane" ? data.talos_machine_configuration.controlplane.machine_configuration : data.talos_machine_configuration.worker.machine_configuration)
  node                        = coalesce(try(cidrhost(each.value.network.ipv6.cidr, each.value.network.ipv6.host), null), try(cidrhost(each.value.network.ipv4.cidr, each.value.network.ipv4.host), null))
}

locals {
  single_controlplane = one([for k, v in var.talos_cluster_nodes : k if v.type == "controlplane"])
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.cluster_config]
  node                 = coalesce(try(proxmox_virtual_environment_vm.talos_cluster[local.single_controlplane].ipv6_addresses[7][0], null), try(proxmox_virtual_environment_vm.talos_cluster[local.single_controlplane].ipv4_addresses[7][0], null))
  client_configuration = talos_machine_secrets.this.client_configuration
}

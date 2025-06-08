data "proxmox_virtual_environment_nodes" "nodes" {}


locals {
    nodes = data.proxmox_virtual_environment_nodes.nodes.names
    node_datastore_map = {
        for node in local.nodes :
            node => {
                node_name = node
                datastore = (contains(data.proxmox_virtual_environment_datastores.datastores[node].datastores[*].id, "local-zfs") ? "local-zfs" :
                        contains(data.proxmox_virtual_environment_datastores.datastores[node].datastores[*].id, "local-lvm") ? "local-lvm" :
                        null
                )
            }
        }
    
    cluster_nodes =  {
    for talos_node_name, node_data in var.talos_cluster_nodes : talos_node_name => {
      name   = node_data.name
      type   = node_data.type
      network = node_data.network

      spec = merge(
        try(node_data.spec, {}),
        {
          node_name = local.node_datastore_map[local.nodes[index(keys(var.talos_cluster_nodes), talos_node_name) % length(local.nodes)]].node_name
          datastore = local.node_datastore_map[local.nodes[index(keys(var.talos_cluster_nodes), talos_node_name) % length(local.nodes)]].datastore
        }
      )
    }
  }
}


data "proxmox_virtual_environment_datastores" "datastores" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value
}


resource "proxmox_virtual_environment_vm" "talos_cluster" {
  for_each = local.cluster_nodes

  name      = each.value.name
  tags      = [each.value.type, "talos"]
  node_name = each.value.spec.node_name
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
      datastore_id = each.value.spec.datastore
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
    datastore_id      = each.value.spec.datastore
    pre_enrolled_keys = each.value.spec.efi_config.pre_enroll_keys
    type              = "4m"
  }

  tpm_state {
    datastore_id = each.value.spec.datastore
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
  single_controlplane_ip = coalesce(try(proxmox_virtual_environment_vm.talos_cluster[local.single_controlplane].ipv6_addresses[7][1], null), try(proxmox_virtual_environment_vm.talos_cluster[local.single_controlplane].ipv4_addresses[7][0], null))
  worker_nodes = [for k, v in var.talos_cluster_nodes : k if v.type == "worker"]
  worker_node_ips = concat([for n in local.worker_nodes: proxmox_virtual_environment_vm.talos_cluster[n].ipv4_addresses[7][0] ],[for n in local.controlplane_nodes: proxmox_virtual_environment_vm.talos_cluster[n].ipv6_addresses[7][1] if !(strcontains(proxmox_virtual_environment_vm.talos_cluster[n].ipv6_addresses[7][0], "fe80")) ])
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.cluster_config]
  node                 = local.single_controlplane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_health" "this" {
  skip_kubernetes_checks = true
  depends_on = [ proxmox_virtual_environment_vm.talos_cluster ]
  endpoints = concat(local.controlpane_ips, [var.talos_cluster_endpoint_ip])
  control_plane_nodes = local.controlpane_ips
  client_configuration = talos_machine_secrets.this.client_configuration
  worker_nodes = local.worker_node_ips
}
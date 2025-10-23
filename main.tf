
locals {
  username = "cluster_admin"
  controlplane_vm_nodes = node_ip_map
  
}

locals {
  nodes = var.controlplane_vm_nodes

  ip_config = var.controlplane_vm_spec.ip_config

  # Define the starting offset (e.g., start assigning from .24)
  ip_start_offset = 34

  # Derive IPv4 and IPv6 base parts
  ipv4_base = cidrhost(local.ip_config.ipv4.subnet, 0)
  ipv6_base = cidrhost(local.ip_config.ipv6.subnet, 0)

  node_ip_map = {
   for idx, node in local.nodes : node => {
      ip_config = {
        ipv4 = {
          address = format(
            "%s/%s",
            cidrhost(local.ip_config.ipv4.subnet, local.ip_start_offset + idx),
            split("/", local.ip_config.ipv4.subnet)[1]
          )
          gateway = local.ip_config.ipv4.gateway
        }
        ipv6 = {
          address = format(
            "%s/%s",
            cidrhost(local.ip_config.ipv6.subnet, local.ip_start_offset + idx),
            split("/", local.ip_config.ipv6.subnet)[1]
          )
          gateway = local.ip_config.ipv6.gateway
        }
      }
    }
  }
}

# scope is to have controlplane and workers deployed and inventory ready for ansible to configure for cluster
module "controlplane" {
  source = "./modules/proxmox-vm"
  for_each = local.controlplane_vm_nodes

  proxmox_vm_cpu = {
    cores = var.controlplane_vm_spec.cores
  }
  proxmox_vm_metadata = {
    name        = each.key
    description = "controlplane managed by terraform"
    tags        = ["cluster", "terraform", "controlplane"]
    agent       = true
  }

  proxmox_vm_user_account = {
    username = local.username
  }
  proxmox_vm_disks = [{
    datastore_id = var.controlplane_vm_spec.disk.datastore_id
    file_format  = "raw"
    interface    = "virtio0"
    size = var.controlplane_vm_spec.disk.size
  }]

  proxmox_vm_memory = {
    dedicated = var.controlplane_vm_spec.memory
  }
  proxmox_vm_network = {
    dns = {
      domain  = ".Home"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    ip_config = each.value.ip_config
  }
  proxmox_vm_boot_image = {
    url = "https://repo.almalinux.org/almalinux/10/cloud/x86_64_v2/images/AlmaLinux-10-GenericCloud-latest.x86_64_v2.qcow2"
  }

}

resource "local_sensitive_file" "test_private_key" {
  for_each = local.controlplane_vm_nodes
  content  = module.test[each.key].prroxmox_vm_keys.private_key_openssh
  filename = "./test_key_${each.key}"
}

resource "local_sensitive_file" "test_public_key" {
  for_each = local.controlplane_vm_nodes
  content  = module.test.prroxmox_vm_keys.public_key_openssh
  filename = "./test_key_${each.key}.pub"
}

# resource "local_file" "inventory" {
  # content = jsonencode(local.inventory)
  # filename = "./inventory.json"
# }
# 
# 
# output "inventory" {
  # value = local.inventory
# }
# locals {
  # inventory = {
    # master = {
      # hosts = {
        # (local.vm_name) = {
          # ansible_host = module.test.ip_config.ipv4[0]
          # ansible_ssh_private_key_file = local_sensitive_file.test_private_key.filename
          # ansible_user = local.username
        # }
      # }
    # }
    # all = {
      # vars = {
        # ansible_port = 22
      # }
    # }
  # }
# }

# eventually the cluster module

module "cluster" {
  source = "git::https://github.com/Dialgatrainer02-lab/k8s-cluster.git"
  controlplane_vm_nodes=var.controlplane_vm_nodes
  controlplane_vm_spec=var.controlplane_vm_spec
  worker_vm_nodes=var.worker_vm_nodes
  worker_vm_spec=var.worker_vm_spec
}


locals {
  inventory = {
    controlplane = {
      hosts = {
        for controlplane in var.controlplane_vm_nodes: controlplane => {
          ansible_host = module.cluster.controlplanes[controlplane].ip_config.ipv4[0]
          ansible_ssh_private_key_file = local_sensitive_file.controlplane_private_key[controlplane].filename
          ansible_user = module.cluster.username
          ipv6_address = [for addr in module.cluster.controlplanes[controlplane].ip_config.ipv6 :
            addr if !can(regex("^(::|fc|fd|fe8|fe9|fea|feb|ff)", addr))][0]
        }
      }
    }
    worker = {
      hosts = {
        for worker in var.worker_vm_nodes: worker => {
          ansible_host = module.cluster.workers[worker].ip_config.ipv4[0]
          ansible_ssh_private_key_file = local_sensitive_file.worker_private_key[worker].filename
          ansible_user = module.cluster.username
          ipv6_address = [for addr in module.cluster.workers[worker].ip_config.ipv6 :
    addr if !can(regex("^(::|fc|fd|fe8|fe9|fea|feb|ff)", addr))][0]
        }
      }
    }
    all = {
      vars = {
        ansible_port = 22
      }
    }
  }
}




resource "local_file" "inventory" {
  content = jsonencode(local.inventory)
  filename = "./inventory.json"
}

resource "local_sensitive_file" "worker_private_key" {
  for_each = toset(var.worker_vm_nodes)
  content  = module.cluster.workers[each.key].proxmox_vm_keys.private_key_openssh
  filename = "./keys/${each.key}"
}
# 
resource "local_sensitive_file" "worker_public_key" {
  for_each = toset(var.worker_vm_nodes)
  content  = module.cluster.workers[each.key].proxmox_vm_keys.public_key_openssh
  filename = "./keys/${each.key}.pub"
}

resource "local_sensitive_file" "controlplane_private_key" {
  for_each = toset(var.controlplane_vm_nodes)
  content  = module.cluster.controlplanes[each.key].proxmox_vm_keys.private_key_openssh
  filename = "./keys/${each.key}"
}

resource "local_sensitive_file" "controlplane_public_key" {
  for_each = toset(var.controlplane_vm_nodes)
  content  = module.cluster.controlplanes[each.key].proxmox_vm_keys.public_key_openssh
  filename = "./keys/${each.key}.pub"
}
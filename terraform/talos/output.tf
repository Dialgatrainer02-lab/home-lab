output "node_ip_addresses" {
  value = {
    for k,v in proxmox_virtual_environment_vm.talos_cluster: k=> {
      ipv4_address = try(proxmox_virtual_environment_vm.talos_cluster[k].ipv4_addresses[7][0], null)
      ipv6_address = try(proxmox_virtual_environment_vm.talos_cluster[local.single_controlplane].ipv6_addresses[7][0], null)
      controlplane = (var.talos_cluster_nodes[k].type == "controlplane"? true: false)
    } 
  }
}

output "talos_config" {
  value = ""
}


output "kube_config" {
  value = ""
}
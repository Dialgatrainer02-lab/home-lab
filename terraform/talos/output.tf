output "node_ip_addresses" {
  depends_on = [ data.talos_cluster_health.this ]
  value = {
    for k,v in proxmox_virtual_environment_vm.talos_cluster: k => {
      ipv4_address = try(proxmox_virtual_environment_vm.talos_cluster[k].ipv4_addresses[7][0], null)
      ipv6_address = try(proxmox_virtual_environment_vm.talos_cluster[local.single_controlplane].ipv6_addresses[7][1], null)
      controlplane = (var.talos_cluster_nodes[k].type == "controlplane"? true: false)
    } 
  }
}

output "talos_config" {
  depends_on = [ data.talos_cluster_health.this ]
  value = data.talos_client_configuration.this.talos_config
}


output "kube_config" {
  depends_on = [ data.talos_cluster_health.this ]
  value = talos_cluster_kubeconfig.this.kubeconfig_raw
}

output "k8_client_config" {
  depends_on = [ data.talos_cluster_health.this ]
  value = talos_cluster_kubeconfig.this.kubernetes_client_configuration
}
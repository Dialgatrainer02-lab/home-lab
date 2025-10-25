output "proxmox_vm_keys" {
    value = tls_private_key.proxmox_vm_key
}

output "proxmox_vm" {
    value = proxmox_virtual_environment_vm.proxmox_vm
}


output "ip_config" {
  value = {
    ipv4 = [
    for ip in flatten(proxmox_virtual_environment_vm.proxmox_vm.ipv4_addresses) : ip
    if !cidrcontains("127.0.0.0/8", try(cidrhost(ip, 0), ip))
  ]
  ipv6 = [
    for ip in flatten(proxmox_virtual_environment_vm.proxmox_vm.ipv6_addresses) : ip
    if !cidrcontains("::1/128", try(cidrhost(ip, 0), ip))
  ]
  }
}


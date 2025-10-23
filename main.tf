module "test" {
    source = "./modules/proxmox-vm"

    proxmox_vm_cpu = {
        cores = 2
    }
    proxmox_vm_metadata = {
      name = "test"
      description = "test"
      tags = []
      agent = true
    }
    proxmox_vm_disks = [{
        datastore_id = "local-zfs"
        file_format = "raw"
        interface = "virtio0"
    }]
    proxmox_vm_memory = {
      dedicated = 2048
    }
    proxmox_vm_network = {
      dns = {
        domain = ".Home"
        servers = ["1.1.1.1"]
      }
      ip_config = {
        ipv4 = {
            address = "dhcp"
            gateway = "whatever"
        }
        ipv6 = {
            address = "dhcp"
            gateway = "whatever"
        }
      }
    }
    proxmox_vm_boot_image = {
      url = "https://repo.almalinux.org/almalinux/10/cloud/x86_64_v2/images/AlmaLinux-10-GenericCloud-latest.x86_64_v2.qcow2"
    }
  
}

output "name" {
  value = module.test.name
}
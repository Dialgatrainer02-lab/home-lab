resource "proxmox_virtual_environment_vm" "proxmox_vm" {
  # metadata
  name        = var.proxmox_vm_metadata.name
  description = var.proxmox_vm_metadata.description
  tags        = var.proxmox_vm_metadata.tags

  node_name = local.node_name
  vm_id     = var.proxmox_vm_metadata.vm_id


  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = var.proxmox_vm_metadata.agent
  }
  stop_on_destroy = local.stop_on_destroy

  # startup {
    # order      = "3"
    # up_delay   = "60"
    # down_delay = "60"
  # }

# cpu
  cpu {
    cores = var.proxmox_vm_cpu.cores
    type  = var.proxmox_vm_cpu.type
    flags = var.proxmox_vm_cpu.flags
  }

# memory
  memory {
    dedicated = var.proxmox_vm_memory.dedicated
    floating  = var.proxmox_vm_memory.floating
    shared = var.proxmox_vm_memory.shared
  }



# networking and other cloud init stuff
  initialization {
    datastore_id = local.local_datastore[local.node_name]

    dns {
      domain = var.proxmox_vm_network.dns.domain
      servers = var.proxmox_vm_network.dns.servers
    }

    ip_config {
      
      ipv4 {
        address = var.proxmox_vm_network.ip_config.ipv4.address
        gateway = local.proxmox_vm_network.ip_config.ipv4.gateway
      }
      ipv6 {
        address = var.proxmox_vm_network.ip_config.ipv6.address
        gateway = local.proxmox_vm_network.ip_config.ipv6.gateway
      }
    }

    user_account {
      username = var.proxmox_vm_user_account.username
      password = var.proxmox_vm_user_account.password
      keys     = [trimspace(tls_private_key.proxmox_vm_key.public_key_openssh)]
    }
  }

# disks

  disk {
   import_from = proxmox_virtual_environment_download_file.proxmox_vm_boot_image.id
   datastore_id = local.local_datastore[local.node_name]
   interface = "scsi0"
   size = 20
 }

  dynamic "disk" {
    for_each = toset(var.proxmox_vm_disks)
    content {
      aio = disk.value["aio"]
      backup = disk.value["backup"]
      cache = disk.value["cache"]
      datastore_id = disk.value["datastore_id"]
      file_format = disk.value["file_format"]
      import_from = disk.value["import_from"]
      interface = disk.value["interface"]
      iothread = disk.value["iothread"]
      size = disk.value["size"]
    }
  }

  dynamic "network_device" {
    for_each = local.network_devices

    content {
      bridge = network_device.value["bridge"]
      disconnected = network_device.value["disconnected"]
      firewall = network_device.value["firewall"]
    }
    
  }

# machine settings
  efi_disk {
    datastore_id = local.local_datastore[local.node_name]
    type = "4m"
  }

  operating_system {
    type = "l26"
  }
  tpm_state {
    datastore_id = local.local_datastore[local.node_name]
    version = "v2.0"
  }
  machine = "q35"
  bios = "ovmf"

}

locals {
  proxmox_vm_network = {
    ip_config = {
      ipv4 = {
        gateway = var.proxmox_vm_network.ip_config.ipv4.address == "dhcp"? null: var.proxmox_vm_network.ip_config.ipv4.gateway
      }
      ipv6 = {
        gateway = var.proxmox_vm_network.ip_config.ipv6.address == "dhcp"? null: var.proxmox_vm_network.ip_config.ipv6.gateway
      }
    }
    }
    stop_on_destroy = !var.proxmox_vm_metadata.agent

    node_name = var.proxmox_vm_metadata.node_name == null ? data.proxmox_virtual_environment_nodes.available_nodes.names[0]: var.proxmox_vm_metadata.node_name

    network_devices = var.proxmox_vm_network.network_devices == null? [{
      bridge = "vmbr0"
      disconnected = false
      firewall = false

    }]: var.proxmox_vm_network.network_devices
}

resource "proxmox_virtual_environment_download_file" "proxmox_vm_boot_image" {
  content_type = var.proxmox_vm_boot_image.content_type
  datastore_id = local.boot_image_datastore_id
  node_name    = local.node_name
  overwrite = false
  overwrite_unmanaged = true
  decompression_algorithm = var.proxmox_vm_boot_image.decompression_algorithm
  url          = var.proxmox_vm_boot_image.url
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = var.proxmox_vm_boot_image.file_name
}

locals {
  boot_image_datastore_id = var.proxmox_vm_boot_image.datastore_id != null? var.proxmox_vm_boot_image.datastore_id: "local"
}

resource "tls_private_key" "proxmox_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
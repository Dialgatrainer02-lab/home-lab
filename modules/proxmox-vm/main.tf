resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
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
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
    }
  }

# disks

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
    for_each = var.proxmox_vm_network.network_device == null? toset([{
      bridge = "vmbr0"
    }]) : toset(var.proxmox_vm_network.network_device)

    content {
      bridge = network_device["bridge"]
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
}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "jammy-server-cloudimg-amd64.qcow2"
}

resource "random_password" "ubuntu_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "proxmox_virtual_environment_vm" "proxmox_vm" {
  name = var.machine.name
  description = var.machine.description
  tags = var.machine.tags
  machine = "q35"


  stop_on_destroy = true
  scsi_hardware = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }

  tpm_state {
    version = "v2.0"
    datastore_id = local.local_datastore
  }
}

locals {
  local_datastore = (contains(data.proxmox_virtual_environment_datastores.datastores[node].datastores[*].id, "local-zfs") ? "local-zfs": null)
}
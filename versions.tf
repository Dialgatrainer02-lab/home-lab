terraform {
  required_version = "~> 1.10.6"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.88.0"
    }
    oci = {
      source = "oracle/oci"
      version = "7.27.0"
    }
  }
}

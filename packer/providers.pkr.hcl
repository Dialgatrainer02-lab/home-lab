packer {
  required_plugins {
    proxmox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/proxmox"
    }
    lxc = {
      version = ">= 1"
      source  = "github.com/hashicorp/lxc"
    }
  }
}
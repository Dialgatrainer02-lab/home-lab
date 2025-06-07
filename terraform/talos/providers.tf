terraform {
  required_version = "~> 1.9.1"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0-alpha.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}
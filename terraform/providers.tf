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
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint
  insecure = true
  username = var.pve_username
  password = var.pve_password
}

provider "kubectl" {
  cluster_ca_certificate = base64decode(module.talos_cluster.k8_client_config.ca_certificate)
  client_certificate = base64decode(module.talos_cluster.k8_client_config.client_certificate)
  client_key = base64decode(module.talos_cluster.k8_client_config.client_key)
  host = module.talos_cluster.k8_client_config.host
  load_config_file       = false
}
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = var.talos_schematic_id
  architecture  = var.talos_arch
  platform      = var.talos_platform
}

data "http" "argocd_ha_manifest" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml"
}

locals {
  argocd_namespace = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "argocd"
    }
  }
  argocd_ha_manifest = data.http.argocd_ha_manifest.response_body
  argocd_manifest    = join("\n---\n", [yamlencode(local.argocd_namespace), local.argocd_ha_manifest])
}

locals {
  tun_device_plugin_manifest = file("${path.module}/manifests/tun-device-plugin.yml")
  installer_image            = (var.talos_secureboot ? data.talos_image_factory_urls.this.urls.installer_secureboot : data.talos_image_factory_urls.this.urls.installer)
  installer_config_patch = {
    machine = {
      install = {
        image = local.installer_image
      }
    }
  }
  argocd_config_patch = {
    cluster = {
      inlineManifests = [
        {
          name     = "argocd"
          contents = <<-EOT
            ${local.argocd_manifest} # already yml encoded due to join
          EOT
        }
      ]
    }
  }
  etcd_config_patch = {
    cluster = {
      etcd = {
        extraArgs = {
          listen-metrics-urls = "http://0.0.0.0:9623"
        }
      }
    }
  }
  tun_device_config_patch = {
    cluster = {
      inlineManifests = [
        {
          name     = "tun_device_plugin"
          contents = <<-EOT
            ${local.tun_device_plugin_manifest}
          EOT
        }
      ]
    }
  }
  metrics_server_controlplane_config_patch = {
    cluster = {
      extraManifests = [
        "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml",
        "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml"
      ]
      apiServer = {
        extraArgs = {
          enable-aggregator-routing = true
        }
      }
    }
  }
  metrics_server_config_patch = {
    machine = {
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
        }
      }
    }
  }
  containerd_config_patch = {
    machine = {
      files = [
        {
          content = <<-EOT
            [metrics]
              address = "0.0.0.0:11234"
          EOT
          path    = "/etc/cri/conf.d/20-customization.part"
          op      = "create"
        }
      ]
    }
  }
  encryption_config_patch = {
    machine = {
      system_disk_encryption = {
        ephemeral = {
          provider = "luks2"
          keys = [
            {
              tpm  = {}
              slot = 0
            }
          ]
        }
        state = {
          provider = "luks2"
          keys = [
            {
              tpm  = {}
              slot = 0
            }
          ]
        }
      }
    }
  }
  common_patches = compact([
    yamlencode(local.installer_config_patch),
    (var.talos_secureboot ? yamlencode(local.encryption_config_patch) : null),
    yamlencode(local.metrics_server_config_patch),
    yamlencode(local.containerd_config_patch),
  ])
  controlplane_config_patch = concat([
    yamlencode(local.metrics_server_controlplane_config_patch),
    yamlencode(local.argocd_config_patch),
    yamlencode(local.tun_device_config_patch)
  ], local.common_patches)
  worker_config_patch = local.common_patches
}


locals {
  controlplane_nodes = [for k, v in var.talos_cluster_nodes : k if v.type == "controlplane"]

  controlpane_ips = concat([for n in local.controlplane_nodes: proxmox_virtual_environment_vm.talos_cluster[n].ipv4_addresses[7][0] ],[for n in local.controlplane_nodes: proxmox_virtual_environment_vm.talos_cluster[n].ipv6_addresses[7][0] if !(strcontains(proxmox_virtual_environment_vm.talos_cluster[n].ipv6_addresses[7][0], "fe80")) ])
  cluster_endpoint = "https://${coalesce(var.talos_cluster_endpoint_ip, local.controlpane_ips... )}:6443"
}



data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  config_patches   = local.controlplane_config_patch[*]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  config_patches   = local.worker_config_patch[*]
}

data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name = var.talos_cluster_name
  endpoints = concat(local.controlpane_ips, [var.talos_cluster_endpoint_ip])
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.single_controlplane_ip
}
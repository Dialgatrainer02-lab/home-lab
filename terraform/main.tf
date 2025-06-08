locals {
  manifest         = jsondecode(file("${path.module}/../manifest.json"))
  talos_builds     = [for b in local.manifest.builds : b if b.name == "talos"]
  almalinux_builds = [for b in local.manifest.builds : b if b.name == "almalinux"]
  build_times      = [for b in local.talos_builds : b.build_time]
  latest_build_ts  = max(local.build_times...)


  latest_talos_build = one([
    for b in local.talos_builds : b
    if b.build_time == local.latest_build_ts
  ])

  latest_almalinux_build = one([
    for b in local.almalinux_builds : b
    if b.build_time == local.latest_build_ts
  ])

  talos_image_data = jsondecode(local.latest_talos_build.custom_data.talos_image)
}

module "talos_cluster" {
  source = "${path.root}/talos"

  talos_version          = local.talos_image_data.version
  talos_platform         = local.talos_image_data.platform
  talos_arch             = local.talos_image_data.arch
  talos_schematic_id     = local.latest_talos_build.custom_data.talos_schematic_id
  talos_secureboot       = local.talos_image_data.secureboot
  
  talos_vm_template = {
    vm_id       = local.latest_talos_build.artifact_id
    # source_node = local.latest_talos_build.custom_data.pve_node
    source_node = "pve1"
  }
  talos_cluster_nodes = {
    "control0" = {
      name = "controlplane0"
      type = "controlplane"
      spec = {
        cpu = {
          cores = 2
          type  = "host"
        }
        memory = 2048
        # disks = []
        efi_config = {
          datastore       = "local-zfs"
          pre_enroll_keys = false
        }
      }
      network = {
        ipv4 = {
          cidr = "192.168.0.0/24"
          host = 97
          gw   = "192.168.0.1"
        }
      }
    },
    worker0 = {
      name = "worker0"
      type = "worker"
      spec = {
        disks = [{
          datastore = "local-zfs"
          interface = "virtio1"
          iothreads = true
          size      = 20
        }]
      }
      network = {
        ipv4 = {
          cidr = "192.168.0.0/24"
          host = 98
          gw   = "192.168.0.1"
        }
      }
    }
    worker1 = {
      name = "worker1"
      type = "worker"
      spec = {
        disks = [{
          datastore = "local-zfs"
          interface = "virtio1"
          iothreads = true
          size      = 20
        }]
      }
      network = {
        ipv4 = {
          cidr = "192.168.0.0/24"
          host = 99
          gw   = "192.168.0.1"
        }
      }
    }
    worker2 = {
      name = "worker2"
      type = "worker"
      spec = {
        disks = [{
          datastore = "local-zfs"
          interface = "virtio1"
          iothreads = true
          size      = 20
        }]
      }
      network = {
        ipv4 = {
          cidr = "192.168.0.0/24"
          host = 100
          gw   = "192.168.0.1"
        }
      }
    }
  }
}

resource "kubectl_manifest" "argocd_application" {
  depends_on = [ module.talos_cluster ]
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps-repo
  namespace: argocd  # This is the namespace where Argo CD is installed
spec:
  project: default

  source:
    repoURL: https://github.com/Dialgatrainer02-lab/apps
    targetRevision: HEAD
    path: .  # Change this if your manifests are in a subfolder

  destination:
    server: https://kubernetes.default.svc  # In-cluster
    namespace: default  # Change if deploying elsewhere

  syncPolicy:
    automated:
      prune: true       # Automatically delete resources removed from git
      selfHeal: true    # Automatically apply changes if cluster drifts from desired state
    syncOptions:
      - CreateNamespace=true  # Optional: auto-create target namespace if it doesn't exist

    YAML
}
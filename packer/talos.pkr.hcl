locals {
  schematic    = {
    customization = {
      extraKernelArgs = [
        "talos.halt_if_installed=0",
        "enforcing=0"
      ]
      systemExtensions = {
        officialExtensions = [
          "siderolabs/i915",
          "siderolabs/intel-ucode",
          "siderolabs/qemu-guest-agent"
        ]
      }
    }
  }
  schematic_id = jsondecode(data.http.schematic_id.body)["id"]
  image_id     = "${local.schematic_id}_${var.talos_image.version}"
}

data "http" "schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = yamlencode(local.schematic)
}


data "http" "secureboot_signing_key" {
  url          = "${var.talos_image.factory_url}/secureboot/signing-cert.pem"
  method       = "GET"
}

source "proxmox-iso" "talos" {
  boot_wait       = "20s"
  bios            = "ovmf"
  qemu_agent      = true
  vm_name         = "talos-linux"
  vm_id           = 901
  machine         = "q35"
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  os              = "l26"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "10G"
    storage_pool = var.pve_datastore
    type         = "virtio"
    io_thread = true
    format       = "raw"
  }
  efi_config {
    efi_storage_pool  = "local-zfs"
    efi_type          = "4m"
    pre_enrolled_keys = false
    efi_format        = "raw"
  }
  tpm_config {
    tpm_storage_pool = var.pve_datastore
  }
  insecure_skip_tls_verify = true
  boot_iso {
    iso_checksum = "none"
    iso_download_pve = false
    iso_urls = [
      "${path.root}downloaded_iso_path/c4856cea5ca15a17b696afa0c817bbdc8bc0adb3.iso",
    "https://london.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"]
    // iso_download_pve = true
    iso_storage_pool = "local"
    type             = "sata"
    unmount          = true
  }
  cloud_init              = true
  cloud_init_disk_type    = "sata"
  cloud_init_storage_pool = var.pve_datastore
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node                 = "${var.pve_node}"
  password             = "${var.pve_password}"
  username             = "${var.pve_username}"
  proxmox_url          = "${var.pve_endpoint}"
  ssh_username         = "root"
  ssh_password         = "packer"
  ssh_timeout          = "15m"
  template_description = "talos linux, generated on ${timestamp()}. Made by Packer"
  tags                 = "talos;template"
  boot_command = [
    "<enter><wait50s>",
    "passwd<enter><wait1s>packer<enter><wait1s>packer<enter>",
  ]
}

build {
  name   = "talos"
  sources = ["source.proxmox-iso.talos"]

  

  provisioner "shell" {
    inline = [
      "URL=${var.talos_image.factory_url}/image/${local.schematic_id}/${var.talos_image.version}/${var.talos_image.platform}-${var.talos_image.arch}${var.talos_image.secureboot ? "-secureboot" : ""}.raw.xz",
      "echo 'Downloading build image from Talos Factory: ' + $URL",
      "curl -kL \"$URL\" -o /tmp/talos.raw.xz > /dev/null",
      "echo 'Writing build image to disk'",
      "xz -d -c /tmp/talos.raw.xz | dd of=$( [ -b /dev/vda ] && echo /dev/vda || ([ -b /dev/sda ] && echo /dev/sda) ) > /dev/null && sync",
      "echo 'Done'",
    ]
  }

  dynamic "provisioner" {
    for_each = var.talos_image.secureboot ? [1] : []
    labels = ["shell"]
    content {
      inline = [
        "echo secureboot"
      ]
    }
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      talos_schematic_id = local.schematic_id
      talos_image = (jsonencode(var.talos_image))
      pve_node = var.pve_node
    }
  }

}
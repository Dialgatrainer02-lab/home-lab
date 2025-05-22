source "proxmox-iso" "alma-k8" {
  boot_command    = ["<up><tab>e<wait><down><down><end>  ip=dhcp inst.cmdline inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<f10>"]
  boot_wait       = "7s"
  bios            = "ovmf"
  machine         = "q35"
  qemu_agent      = true
  cpu_type        = "host"
  cores           = 2
  memory          = 2048
  os = "l26"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "10G"
    storage_pool = "local-zfs"
    type         = "scsi"
    format       = "raw"
  }
  efi_config {
    efi_storage_pool  = "local-zfs"
    efi_type          = "4m"
    pre_enrolled_keys = false
    efi_format        = "raw"
  }
  http_directory           = "${path.root}/kickstart"
  insecure_skip_tls_verify = true
  boot_iso {
    iso_checksum = "none"
    iso_urls = ["./downloaded_iso_path/977ffa5c530f281d5418b688b30333cdc55877b9.iso",
    "https://repo.almalinux.org/almalinux/9.5/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso"]
    // iso_download_pve = true
    iso_storage_pool = "local"
    unmount          = true
  }
  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  node                 = "${var.pve_node}"
  password             = "${var.pve_password}"
  username             = "${var.pve_username}"
  proxmox_url          = "${var.pve_endpoint}"
  ssh_password         = "${var.provision_passwd}"
  ssh_timeout          = "15m"
  ssh_username         = "${var.provision_user}"
  template_description = "Almalinux, generated on ${timestamp()}. Made by Packer"
}
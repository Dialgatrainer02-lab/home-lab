# not making lxc in packer as the lxc plugin is absolutely awful 

source "proxmox-iso" "almalinux" {
  bios            = "ovmf"
  qemu_agent      = true
  vm_name         = "alma-linux"
  vm_id           = 902
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
    pre_enrolled_keys = true # almalinux uses a signed shim so should work
    efi_format        = "raw"
  }
  tpm_config {
    tpm_storage_pool = var.pve_datastore
  }
  insecure_skip_tls_verify = true
  boot_iso {
    iso_checksum = "none"
    iso_download_pve = false
    iso_urls = ["https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10.0-x86_64-boot.iso"]
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
  ssh_username         = "packer"
  ssh_password         = "Password1"
  ssh_timeout          = "20m"
  http_directory       = "${path.root}/http"
  template_description = "almalinux, generated on ${timestamp()}. Made by Packer"
  tags                 = "almalinux;template"
  boot_wait            = "7s"
  boot_command         = ["<up><tab>e<wait><down><down><end>  ip=dhcp inst.cmdline inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<f10>"]
}

build {
  name   = "almalinux"
  sources = ["source.proxmox-iso.almalinux"]

  provisioner "file" {
    source      = "${path.root}/almalinux/remove_packer.service" # remove packer as it uses a weak password thats in plaintext use cloud-init to set user and keys up later
    destination = "/tmp/remove_packer.service"
  }

  provisioner "file" {
    source      = "${path.root}/almalinux/remove_packer.sh"
    destination = "/tmp/remove_packer.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/remove_packer.sh /opt/remove_packer.sh",
      "sudo cp /tmp/remove_packer.service /etc/systemd/system/remove-packer.service",
      "sudo chmod +x /opt/remove_packer.sh",
      "sudo systemctl enable remove-packer",
      "echo 'Done'",
    ]
  }

  // provisioner "breakpoint" {}



  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      // almalinux_vm_id    = 902
      pve_node = var.pve_node
    }
  }

}
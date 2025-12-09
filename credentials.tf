variable "pve_endpoint" {
  type = string
}

variable "pve_username" {
  type = string
}

variable "pve_password" {
  type = string
}

variable "tenancy_ocid" {
}

variable "user_ocid" {
  default = ""
}

variable "fingerprint" {
}

variable "private_key_path" {
  default = ""
}

variable "ssh_public_key" {
  default = ""
}

variable "compartment_ocid" {
}

variable "region" {
}

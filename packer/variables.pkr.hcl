variable "pve_endpoint" {
  type = string
}

variable "pve_username" {
  type    = string
  default = "root@pam"
}

variable "pve_password" {
  type = string
}

variable "pve_node" {
  type = string
  default = "pve"
}

variable "provision_user" {
    type = string
    default = "provision"
}

variable "provision_passwd" {
    type = string
    default = "Password1"
    description = "password for the provision user is not secure and ssh keys should be used"

}
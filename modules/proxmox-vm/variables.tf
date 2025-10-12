variable "machine" {
  type = object({
    name = string
    node_name = string
    description = string
    tags = list(string)
    spec = {
        cpus = number
        memory = number

    }

  })
}

data "proxmox_virtual_environment_datastores" "datastores" {
  for_each = toset(data.proxmox_virtual_environment_nodes.nodes.names)
  node_name = each.value
}
data "proxmox_virtual_environment_nodes" "nodes" {}
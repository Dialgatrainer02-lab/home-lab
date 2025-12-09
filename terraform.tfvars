controlplane_vm_nodes = ["controlplane0"]

controlplane_vm_spec = {
  cores     = 4
  memory    = 5042
  node_name = "pve"
  disk = {
    datastore_id = "local-zfs"
    size         = 34
  }
  ip_config = {
    ipv4 = {
      subnet  = "192.168.0.0/24"
      gateway = "192.168.0.1"
    }
    ipv6 = {
      subnet  = "2a02:c7c:6a58:7100:d384:ccaa:f867:91e5/64"
      gateway = "fe80::681:9bff:fe40:8d09"
    }
  }
}

worker_vm_nodes = ["worker0", "worker1", "worker2"]
worker_vm_spec = {
  node_name = "pve1"
  cores     = 2
  memory    = 4096
  disk = {
    datastore_id = "local-zfs"
    size         = 34
  }
  #    ip_config = {
  #    ipv4 = {
  # subnet = "192.168.0.0/24"
  # gateway = "192.168.0.1"
  #    }
  #    ipv6 = {
  # subnet = "2a02:c7c:6a58:7100:d384:ccaa:f867:91e5/64"
  # gateway = "fe80::681:9bff:fe40:8d09"
  #    }
  #    }
}

dns_vm_spec = {
  cores  = 2
  memory = 2048
  name   = "dns0"
  user   = "root"
  ip_config = {
    ipv4 = {
      address = "192.168.0.101/24",
      gateway = "192.168.0.1"
    },
    ipv6 = {
      address = "dhcp"
      gateway = "hello"
    }
  }
}

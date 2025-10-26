test {
  parallel = true
}

run "basic" {
    command = plan
    variables {
        proxmox_vm_metadata = {
            name = "test1"
            description = "test description"
            tags = ["test"]
            vm_id = 888
            node_name = "pve"
            on_boot = false
            agent = false
        }
        proxmox_vm_user_account = {
            username = "test"
            password = "test"
        }
        proxmox_vm_cpu = {
            cores = 2
            type = "kvm64"
        }
        proxmox_vm_disks = [{
            
        }]

    }
}
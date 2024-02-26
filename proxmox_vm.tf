resource "proxmox_vm_qemu" "vm" {
  name        = "vm-tf-build"
  agent       = 1
  target_node = "pve"
  clone       = "deb64"
  os_type     = "cloud-init"
  cores       = 2
  sockets     = 1
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  # Updated disk configurationabout:blank#blocked
  disks {
    scsi {
      scsi0 {
        disk {
          storage  = "DATA"
          size     = 30
          format   = "raw"
          backup   = false
          iothread = true
        }
      }
    }
  }

  # Updated network interface configuration
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init configuration
  ipconfig0 = "ip=dhcp"
}

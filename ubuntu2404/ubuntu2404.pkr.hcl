# Ubuntu Server Noble (24.04.x)
# ---
# Packer Template to create an Ubuntu Server (Noble 24.04.x) on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu2404" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"   
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # VM General Settings
    node = "lab"
    vm_id = "300"
    vm_name = "ubuntu2404"
    template_description = "Ubuntu Server 24.04 image"

    boot_iso {
      type = "scsi"
      iso_file = "local:iso/ubuntu-24.04-live-server-amd64.iso"
      unmount = true
      iso_checksum = "md5:b33b57dea8c827febc89f38b31d532e6"
    }

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"
    disks {
        disk_size = "20G"
        format = "raw"
        storage_pool = "local-lvm"
        #storage_pool_type = "lvm"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "1"
    
    # VM Memory Settings
    memory = "2048" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 
    
    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]

    boot                    = "c"
    boot_wait               = "10s"
    communicator            = "ssh"

    # PACKER Autoinstall Settings
    http_directory          = "http" 
    # (Optional) Bind IP Address and Port
    # http_bind_address       = "0.0.0.0"
    # http_port_min           = 8802
    # http_port_max           = 8802

    ssh_username            = "root"

    # (Option 1) Add your Password here
    # ssh_password        = "your-password"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file    = "~/.ssh/id_rsa"

    # Raise the timeout, when installation takes longer
    ssh_timeout             = "30m"
    ssh_pty                 = true
}

# Build Definition to create the VM Template
build {
    name = "ubuntu2404"
    sources = ["source.proxmox-iso.ubuntu2404"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Add additional provisioning scripts here
    # ...
}
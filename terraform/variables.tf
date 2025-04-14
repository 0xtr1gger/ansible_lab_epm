variable rg_name {
  type        = string
  default     = "rg-ansible-lab-epm"
  description = "The name for the resource group."
}

variable rg_location {
  type        = string
  default     = "japaneast"
  description = "The Azure region where resources will be provisioned."
}

variable vm_number {
  type        = number
  default     = 3
  description = "The number of VMs to create."
}


variable vnet_config {
  type = object({
    name          = string
    address_space = list(string)
    subnet = object({
      name             = string
      address_prefixes = list(string)
    })
  })
  default = {
    name          = "vnet-ansible-lab-epm"
    address_space = ["10.0.0.0/16"]
    subnet = {
      name             = "vsubnet-ansible-lab-epm"
      address_prefixes = ["10.0.1.0/24"]
    }

  }
}


variable vm_nic_config {
  type = object({
    name = string

    ip_configuration = object({
      name                          = string
    })

    public_ip = object({
      name              = string
      allocation_method = string
    })
  })

  default = {
    name = "vm-nic-ansible-lab-epm"

    ip_configuration = {
      name           = "ip-config-ansible-lab-epm"
    }

    public_ip = {
      name              = "public-ip-vm-ansible-lab-epm"
      allocation_method = "Dynamic"
    }
  }
}

variable nsg_config {
  type = object({
    name = string

    security_rules = list(object({
      name     = string
      priority = number

      direction = string
      access    = string
      protocol  = string

      source_port_range      = string
      destination_port_range = string

      source_address_prefix      = string
      destination_address_prefix = string
    }))
  })

  default = {
    name = "vm-nsg-ansible-lab-epm"
    security_rules = [
      {
        name     = "allow-SSH"
        priority = 100

        direction = "Inbound"
        access    = "Allow"
        protocol  = "Tcp"

        source_port_range      = "*"
        destination_port_range = "22"

        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name     = "allow-collectd"
        priority = 200

        direction = "Inbound"
        access    = "Allow"
        protocol  = "Tcp"

        source_port_range      = "*"
        destination_port_range = "9103"

        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name     = "deny-all-inbound"
        priority = 300

        direction = "Inbound"
        access    = "Deny"
        protocol  = "*"

        source_port_range      = "*"
        destination_port_range = "22"

        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
}

variable vm_admin_username {
  type        = string
  default     = "ansible"
  description = "The name for the administrator account on VMs."
}

variable ssh_public_key_file {
  type        = string
  description = "Path to the SSH public key file."
  default     = "~/.ssh/id_rsa.pub"
}

variable vm_config {
  type = object({
    size = string
    os_disk = object({
      caching              = string
      storage_account_type = string
    })
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })

  default = {
    size = "Standard_B1s"

    os_disk = {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }
    source_image_reference = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  }
}
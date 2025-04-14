terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.rg_location
}


resource "azurerm_virtual_network" "vnet" {
  name          = var.vnet_config.name
  address_space = var.vnet_config.address_space

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "vm_subnet" {
  name             = var.vnet_config.subnet.name
  address_prefixes = var.vnet_config.subnet.address_prefixes

  virtual_network_name = azurerm_virtual_network.vnet.name

  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_public_ip" "vm_public_ip" {
  count = var.vm_number

  name              = "${var.vm_nic_config.public_ip.name}-${count.index}"
  allocation_method = var.vm_nic_config.public_ip.allocation_method

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_interface" "vm_nic" {

  count = var.vm_number

  name = "${var.vm_nic_config.name}-${count.index}"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "${var.vm_nic_config.ip_configuration.name}-${count.index}"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.1.${count.index + 5}"

    subnet_id            = azurerm_subnet.vm_subnet.id
    public_ip_address_id = azurerm_public_ip.vm_public_ip[count.index].id
  }
}


resource "azurerm_network_security_group" "vm_nsg" {
  name = var.nsg_config.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  dynamic "security_rule" {
    for_each = var.nsg_config.security_rules
    content {
      name     = security_rule.value.name
      priority = security_rule.value.priority

      direction = security_rule.value.direction
      access    = security_rule.value.access
      protocol  = security_rule.value.protocol

      source_port_range      = security_rule.value.source_port_range
      destination_port_range = security_rule.value.destination_port_range

      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_vm_nic_association" {
  count = var.vm_number

  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "ansible_vm" {

  count = var.vm_number
  name = "ansible-vm-${count.index}"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  network_interface_ids = [azurerm_network_interface.vm_nic[count.index].id]

  size           = var.vm_config.size
  admin_username = var.vm_admin_username # ansible

  os_disk {
    caching              = var.vm_config.os_disk.caching
    storage_account_type = var.vm_config.os_disk.storage_account_type
  }
  source_image_reference {
    publisher = var.vm_config.source_image_reference.publisher
    offer     = var.vm_config.source_image_reference.offer
    sku       = var.vm_config.source_image_reference.sku
    version   = var.vm_config.source_image_reference.version
  }
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.ssh_public_key_file)
  }
}


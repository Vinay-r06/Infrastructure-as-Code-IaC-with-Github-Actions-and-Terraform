terraform {
    required_providers {
      azurerm = {
        source  = "hashicorp/azurerm"
        version = "~>3.0"
      }
    }
  backend "azurerm" {}  
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-terraform-rg"
  location = "South Africa North"

}

resource "azurerm_storage_account" "sa" {
  name                     = "vinaystorage2026"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }

}

resource "azurerm_virtual_network" "vnet" {
    name                = "vinay-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "vinay-subnet"
  address_prefixes     =  ["10.0.1.0/24"]  
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name   
}     

resource "azurerm_public_ip" "pip" {
  name                = "vinay-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}

resource "azurerm_network_interface" "nic" {
  name                = "vinay-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id

  }
}

resource "azurerm_linux_virtual_machine" "vm" {
    name                = "vinay-vm"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location 
    size                = "Standard_DS1_v2"

    admin_username = "azureadmin"

    network_interface_ids = [
        azurerm_network_interface.nic.id
    ]

    admin_ssh_key {

      username   = "azureadmin"
      public_key = file("id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

  }

  source_image_reference {

    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true

}

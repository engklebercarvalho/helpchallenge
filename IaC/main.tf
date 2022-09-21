terraform {
  required_version = ">= 0.12"

   required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
   }
}


################AZURE###################
#Configure the Azure Provider
provider "azurerm" {
  features {
   resource_group { prevent_deletion_if_contains_resources = false   }
  }
  version         = ">= 2.0"
  environment     = "public"
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  
}
#Create Azure Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group
  location = var.location
}
#Create Azure Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
}
#Create Azure Subnet
resource "azurerm_subnet" "internal" {
  name                 = "subnet-backend"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.10.0/24"]
}
#Create Azure Public IPs
resource "azurerm_public_ip" "frontend" {
  name                = "${var.virtual_machine_frontend}-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}
resource "azurerm_public_ip" "backend" {
  name                = "${var.virtual_machine_backend}-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}
#Create Azure Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                = var.storage_account
  resource_group_name = azurerm_resource_group.resource_group.name
 
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
 
}
#Create Azure Network Interface
resource "azurerm_network_interface" "frontend" {
  name                = "${var.virtual_machine_frontend}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "vm-frontend-ip-configuration"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address            = "10.10.10.4"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.frontend.id
  }
}
resource "azurerm_network_interface" "backend" {
  name                = "${var.virtual_machine_backend}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "vm-backend-ip-configuration"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address            = "10.10.10.5"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.backend.id
  }
}
resource "azurerm_network_interface" "database" {
  name                = "${var.virtual_machine_database}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "vm-backend-ip-configuration"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address            = "10.10.10.6"
    private_ip_address_allocation = "Static"
  }
}
#Create Azure Virtual Machines
resource "azurerm_virtual_machine" "frontend" {
  name                  = var.virtual_machine_frontend
  location              = azurerm_resource_group.resource_group.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.frontend.id]
  vm_size               = "Standard_B2ms"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "20.04.202010140"
  }
  storage_os_disk {
    name              = "${var.virtual_machine_frontend}-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "svc_Linux"
    admin_password = "Password1234!"
    custom_data    = file("azure-user-data-frontend.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }

  tags = {
    environment = "staging"
  }

  depends_on = [
    azurerm_virtual_machine.backend,
    azurerm_virtual_machine.database
  ]
}
resource "azurerm_virtual_machine" "backend" {
  name                  = var.virtual_machine_backend
  location              = azurerm_resource_group.resource_group.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.backend.id]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "20.04.202010140"
  }
  storage_os_disk {
    name              = "${var.virtual_machine_backend}-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "svc_Linux"
    admin_password = "Password1234!"
    custom_data    = file("azure-user-data-backend.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }

  tags = {
    environment = "staging"
  }

  depends_on = [
    azurerm_virtual_machine.database
  ]
}
resource "azurerm_virtual_machine" "database" {
  name                  = var.virtual_machine_database
  location              = azurerm_resource_group.resource_group.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.database.id]
  vm_size               = "Standard_B2ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "20.04.202010140"
  }
  storage_os_disk {
    name              = "${var.virtual_machine_database}-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "svc_Linux"
    admin_password = "Password1234!"
    custom_data    = file("azure-user-data-database.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }
}
#Create Azure Public DNS Records
resource "azurerm_dns_a_record" "azurefrontend" {
  name                = "azurefrontend"
  zone_name           = "cloudarch.com.br"
  resource_group_name = "rg-dns"
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.frontend.id
}
resource "azurerm_dns_a_record" "azurebackend" {
  name                = "azurebackend"
  zone_name           = "cloudarch.com.br"
  resource_group_name = "rg-dns"
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.backend.id
}

############################################################


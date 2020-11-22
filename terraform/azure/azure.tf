variable "prefix" {
  default = "alice"
}

provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [ "10.0.42.0/24" ]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_security_group" "ssh" {
  name                = "ssh"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ssh"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = azurerm_network_interface.main.private_ip_address
  }
}

resource "azurerm_linux_virtual_machine" "alice" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = "ubuntu"
  
  network_interface_ids = [ azurerm_network_interface.main.id ]

  admin_ssh_key {
    username = "ubuntu"
    public_key = file("./keys/ssh/id_rsa.pub")
  }

  source_image_reference {
    # Canonical:UbuntuServer:18.04-LTS
    # publisher = "Canonical"
    # offer     = "UbuntuServer"
    # sku       = "18.04-LTS"

    # Canonical:0001-com-ubuntu-server-focal:20_04-lts
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"

    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

data "template_file" "inventory" {
  template = file("./terraform/_templates/inventory.tpl")
  
  vars = {
    user = "ubuntu"
    host = join("", [azurerm_linux_virtual_machine.alice.name, " ansible_host=", azurerm_linux_virtual_machine.alice.public_ip_address])
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory"
}
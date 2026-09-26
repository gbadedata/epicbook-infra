data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

locals {
  location = data.azurerm_resource_group.main.location
  rg       = data.azurerm_resource_group.main.name
  tags = {
    project = "epicbook"
    owner   = "Oluwagbade Odimayo"
    course  = "DMI Week 10"
  }
}

# ---------------------------------------------------------------- Network

resource "azurerm_virtual_network" "main" {
  name                = "vnet-epicbook"
  location            = local.location
  resource_group_name = local.rg
  address_space       = ["10.40.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.3.0/24"]

  delegation {
    name = "mysql-flexible-server"

    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ---------------------------------------------------------------- Network security

resource "azurerm_network_security_group" "frontend" {
  name                = "nsg-epicbook-frontend"
  location            = local.location
  resource_group_name = local.rg
  tags                = local.tags

  security_rule {
    name                       = "allow-http-from-internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-restricted"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_allowed_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend" {
  name                = "nsg-epicbook-backend"
  location            = local.location
  resource_group_name = local.rg
  tags                = local.tags

  security_rule {
    name                       = "allow-app-from-frontend-subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.40.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-restricted"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-app-from-everywhere-else"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

# ---------------------------------------------------------------- Public IPs and NICs

resource "azurerm_public_ip" "frontend" {
  name                = "pip-epicbook-frontend"
  location            = local.location
  resource_group_name = local.rg
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# The backend's public IP is for Ansible SSH (restricted by the NSG) and outbound
# package downloads. The application port stays closed to the internet.
resource "azurerm_public_ip" "backend" {
  name                = "pip-epicbook-backend"
  location            = local.location
  resource_group_name = local.rg
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "frontend" {
  name                = "nic-epicbook-frontend"
  location            = local.location
  resource_group_name = local.rg
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend.id
  }
}

resource "azurerm_network_interface" "backend" {
  name                = "nic-epicbook-backend"
  location            = local.location
  resource_group_name = local.rg
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.backend.id
  }
}

# ---------------------------------------------------------------- Virtual machines

resource "azurerm_linux_virtual_machine" "frontend" {
  name                            = "vm-epicbook-frontend"
  computer_name                   = "epicbook-frontend"
  location                        = local.location
  resource_group_name             = local.rg
  size                            = var.frontend_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.frontend.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "backend" {
  name                            = "vm-epicbook-backend"
  computer_name                   = "epicbook-backend"
  location                        = local.location
  resource_group_name             = local.rg
  size                            = var.backend_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.backend.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# ---------------------------------------------------------------- MySQL (private access)

resource "azurerm_private_dns_zone" "mysql" {
  name                = "oluwagbade-epicbook.private.mysql.database.azure.com"
  resource_group_name = local.rg
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "link-vnet-epicbook"
  resource_group_name   = local.rg
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-epicbook-oluwagbade"
  location               = local.location
  resource_group_name    = local.rg
  administrator_login    = var.mysql_admin_login
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.database.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  tags                   = local.tags

  storage {
    size_gb = 20
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]

  lifecycle {
    # Azure picks an availability zone when none is requested.
    ignore_changes = [zone]
  }
}

resource "azurerm_mysql_flexible_database" "bookstore" {
  name                = "bookstore"
  resource_group_name = local.rg
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

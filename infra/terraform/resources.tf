resource "azurerm_resource_group" "main" {
  name     = "jenkins-${var.environment}"
  location = var.location

  tags = {
    managed_by  = "terraform"
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Сеть
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "jenkins-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "jenkins-shop-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "controller" {
  name                = "pip-jenkins-controller-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NSG для Controller: 8080 (Jenkins UI) и 22 (SSH) снаружи
resource "azurerm_network_security_group" "controller" {
  name                = "nsg-jenkins-controller-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-JNLP"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "50000"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Jenkins-UI"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG для Agent: только 22, и только из подсети
resource "azurerm_network_security_group" "agent" {
  name                = "nsg-jenkins-agent-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH-From-Subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.main.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "controller" {
  name                = "nic-jenkins-controller-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.controller.id
  }
}

resource "azurerm_network_interface" "agent" {
  name                = "nic-jenkins-agent-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.jenkins_agent_private_ip
  }
}

resource "azurerm_network_interface_security_group_association" "controller" {
  network_interface_id      = azurerm_network_interface.controller.id
  network_security_group_id = azurerm_network_security_group.controller.id
}

resource "azurerm_network_interface_security_group_association" "agent" {
  network_interface_id      = azurerm_network_interface.agent.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

# ---------------------------------------------------------------------------
# Вычисление
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "controller" {
  name                = "vm-jenkins-controller-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.controller.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-jenkins-controller-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init-controller.yaml.tftpl", {
    jenkins_casc_content = templatefile("${path.module}/jenkins-casc.yaml", {
      jenkins_agent_private_key = base64decode(var.jenkins_agent_private_key)
    })
    jenkins_admin_password    = var.jenkins_admin_password
    jenkins_agent_private_key = var.jenkins_agent_private_key
  }))

  tags = {
    managed_by  = "terraform"
    environment = var.environment
    role        = "jenkins-controller"
  }
}

resource "azurerm_linux_virtual_machine" "agent" {
  name                = "vm-jenkins-agent-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.agent.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-jenkins-agent-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init-agent.yaml.tftpl", {
    admin_username           = var.admin_username
    jenkins_agent_public_key = var.jenkins_agent_public_key
  }))

  tags = {
    managed_by  = "terraform"
    environment = var.environment
    role        = "jenkins-agent"
  }
}

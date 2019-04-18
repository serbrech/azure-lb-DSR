locals {
  internal_lb_frontend_ip_configuration_name = "internal-lb-ip"
}

resource "azurerm_virtual_network" "cluster_vnet" {
  name                = "${var.cluster_id}-vnet"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.region}"
  address_space       = ["${var.vnet_cidr}"]
}

resource "azurerm_route_table" "route_table" {
  name                = "${var.cluster_id}-node-routetable"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet" "master_subnet" {
  resource_group_name  = "${var.resource_group_name}"
  address_prefix       = "${var.subnet_cidr}"
  virtual_network_name = "${azurerm_virtual_network.cluster_vnet.name}"
  name                 = "${var.cluster_id}-subnet"
}

resource "azurerm_lb" "internal" {
  sku                 = "Standard"
  name                = "${var.cluster_id}-internal-lb"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.region}"

  frontend_ip_configuration {
    name                          = "${local.internal_lb_frontend_ip_configuration_name}"
    subnet_id                     = "${azurerm_subnet.master_subnet.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${cidrhost(var.subnet_cidr, -2)}" #last ip is reserved by azure
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
    subnet_id                 = "${azurerm_subnet.master_subnet.id}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.cluster_id}-nsg"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh-in"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_lb_probe" "internal_lb_probe_api_internal" {
  name                = "api-internal-probe"
  resource_group_name = "${var.resource_group_name}"
  interval_in_seconds = 10
  number_of_probes    = 3
  loadbalancer_id     = "${azurerm_lb.internal.id}"
  port                = 6443
  protocol            = "Tcp"
}

resource "azurerm_lb_backend_address_pool" "internal_lb_controlplane_pool" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.internal.id}"
  name                = "${var.cluster_id}-internal"
}

resource "azurerm_lb_rule" "internal_lb_rule_api_internal" {
  name                           = "api-internal"
  resource_group_name            = "${var.resource_group_name}"
  protocol                       = "Tcp"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.internal_lb_controlplane_pool.id}"
  loadbalancer_id                = "${azurerm_lb.internal.id}"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "${local.internal_lb_frontend_ip_configuration_name}"
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 4
  load_distribution              = "Default"
  probe_id                       = "${azurerm_lb_probe.internal_lb_probe_api_internal.id}"
}

resource "azurerm_network_interface" "master" {
  count               = "${var.instance_count}"
  name                = "${var.cluster_id}-master-nic-${count.index}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    subnet_id                     = "${var.subnet_id}"
    name                          = "master-${count.index}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${cidrhost(var.subnet_cidr, 5 + count.index)}" # azure reserves first 3 ip, 4th is for bootstrap VM, so we start at 5
    public_ip_address_id = "${element(azurerm_public_ip.master.*.id, count.index)}"
  }
}

resource "azurerm_public_ip" "master" {
  location = "${var.region}"
  resource_group_name = "${var.resource_group_name}"
  count = "${var.instance_count}"
  name = "${var.cluster_id}-pip-${count.index}"
  allocation_method = "Static"
  idle_timeout_in_minutes = 30
  sku="Standard"
}

resource "azurerm_network_interface_backend_address_pool_association" "master_internal" {
  count                   = "${var.instance_count}"
  network_interface_id    = "${element(azurerm_network_interface.master.*.id, count.index)}"
  backend_address_pool_id = "${var.ilb_backend_pool_id}"
  ip_configuration_name   = "master-${count.index}"                                          #must be the same as nic's ip configuration name.
}

resource "azurerm_availability_set" "master" {
  name                         = "mater-as"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  managed                      = true
  platform_update_domain_count = 5
  platform_fault_domain_count  = 3                            # the available fault domain number depends on the region, so this needs to be configurable or dynamic
}


resource "azurerm_virtual_machine" "master" {
  count                 = "${var.instance_count}"
  name                  = "lbdsr-${count.index}"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.master.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.master.id}"

  delete_os_disk_on_termination = true

  identity {
    type         = "UserAssigned"
    identity_ids = ["${var.identity}"]
  }

  storage_os_disk {
    name              = "masterosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "100"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "lbdsr-vm-${count.index}"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${var.ssh_key}"
        }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.bootdiag.primary_blob_endpoint}"
  }
}

resource "random_string" "storage_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_storage_account" "bootdiag" {
  name                     = "bootdiagmasters${random_string.storage_suffix.result}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
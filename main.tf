
locals{
    cluster_id = "lb_dsr"
    region = "eastus"
    vnet_cidr = "10.100.0.0/16"
    subnet_cidr="${cidrsubnet(local.vnet_cidr, 3, 1)}"
    vm_size = "Standard_DS4_v2"
    ssh_key ="ssh-rsa AAAAB3NzaC1y<snip>zx8sb9uGJ9DZZLQ=="
}

resource "azurerm_resource_group" "main" {
  name     = "${local.cluster_id}-rg"
  location = "${local.region}"
}


resource "azurerm_user_assigned_identity" "main" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${local.region}"

  name = "${local.cluster_id}-identity"
}

resource "azurerm_role_assignment" "main" {
  scope                = "${azurerm_resource_group.main.id}"
  role_definition_name = "Contributor"
  principal_id         = "${azurerm_user_assigned_identity.main.principal_id}"
}

module "network" {
    source = "./network"
    resource_group_name = "${azurerm_resource_group.main.name}"
    region="${local.region}"
    cluster_id = "${local.cluster_id}"
    subnet_cidr = "${local.subnet_cidr}"
    vnet_cidr = "${local.vnet_cidr}"
}

module "vms" {
    source = "./VMs"
    instance_count = 2
    resource_group_name = "${azurerm_resource_group.main.name}"
    region="${local.region}"
    cluster_id = "${local.cluster_id}"
    vm_size = "${local.vm_size}"
    ilb_backend_pool_id = "${module.network.internal_lb_backend_pool_id}"
    subnet_id = "${module.network.subnet_id}"
    subnet_cidr = "${local.subnet_cidr}"
    identity = "${azurerm_user_assigned_identity.main.id}"
    ssh_key = "${local.ssh_key}"
}

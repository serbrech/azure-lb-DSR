output "vnet_id" {
  value = "${azurerm_virtual_network.cluster_vnet.id}"
}

# output "lb_ip" {
#   value = "${azurerm_public_ip.cluster_public_ip.ip_address}"
# }

output "subnet_id" {
  value = "${azurerm_subnet.master_subnet.id}"
}

output "internal_lb_backend_pool_id" {
  value = "${azurerm_lb_backend_address_pool.internal_lb_controlplane_pool.id}"
}
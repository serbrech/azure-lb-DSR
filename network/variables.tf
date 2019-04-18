variable "region" {
  type        = "string"
  description = "The region for the deployment."
}

variable "resource_group_name" {
  type        = "string"
  description = "The resource group name for the deployment."
}

variable "cluster_id" {
  type = "string"
}

variable "vnet_cidr" {
    type = "string"
}

variable "subnet_cidr" {
    type = "string"
}

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

variable "vm_size" {
  type = "string"
}

variable "instance_count" {
  type = "string"
}

variable "ilb_backend_pool_id" {
  type = "string"
}

variable "subnet_id" {
  type        = "string"
  description = "The subnet to attach the masters to."
}

variable "subnet_cidr" {
  type        = "string"
  description = "the subnet cidr"
}

variable "identity" {
  type        = "string"
  description = "The user assigned identity id for the vm."
}

variable "ssh_key" {
  type        = "string"
  description = "ssh key"
}
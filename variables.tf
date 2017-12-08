variable "resourcegroupname" {
  default = "testenvgroup"
}

variable "region" {
  default = "westeurope"
}

variable "networkname" {
  default = "testenvnetwork"
}

variable "subnetname" {
  default = "testenvsubnet"
}

variable "publicipname" {
  default = "testenvpublicip"
}

variable "publicipsgname" {
  default = "testenvpublicipsg"
}

variable "nicname" {
 default = "testenvnic"
}

variable "testenvpublicipsgname" {
  default = "testenvpublicipsg"
}

variable "customer_arm_subscription_id" {}
variable "customer_arm_client_id" {}
variable "customer_arm_client_secret" {}
variable "customer_arm_tenant_id" {}

variable "vmscount" {
  default = 2
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "/home/mpastecki/.ssh/id_rsa"
}

variable "PRIVATE_KEY_FILE_NAME" {
  default = "id_rsa"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "/home/mpastecki/.ssh/id_rsa.pub"
}

variable "ansible_inventory_name" {
  default = "test"
}

variable "oms_workspace_region" {}
variable "oms_workspace_name" {}
variable "oms_workspace_id" {}
variable "oms_workspace_key" {}

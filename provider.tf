# Configure the Azure Provider
provider "azurerm" {
  subscription_id = "${var.customer_arm_subscription_id}"
  client_id       = "${var.customer_arm_client_id}"
  client_secret   = "${var.customer_arm_client_secret}"
  tenant_id       = "${var.customer_arm_tenant_id}"
}

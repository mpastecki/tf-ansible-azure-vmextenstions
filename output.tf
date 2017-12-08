output "public_ips" {
  value = "${join(",", data.azurerm_public_ip.datasourceip.*.ip_address)}"
}

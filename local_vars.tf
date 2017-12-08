# Local named expressions/values
data "null_data_source" "local_vars" {
  inputs = {
    # LinuxDiagnostic virtual machine extension settings common across all VMs
    linux_diagnostic_vm_extn_type_handler_version                           = "2.3"
    diags_settings                                                          = "{ 'storageAccountName': '${azurerm_storage_account.testenvstorageaccount.name}', 'storageAccountKey': '${azurerm_storage_account.testenvstorageaccount.primary_access_key}'}"

    # OmsAgentForLinux virtual machine extension settings common across all VMs
    oms_agent_for_linux_vm_extn_type_handler_version                        = "1.0"
    oms_agent_for_linux_vm_extn_auto_upgrade_minor_version                  = "true"
    oms_settings                                                            = "{ 'workspaceId': '${var.oms_workspace_id}' }"

    oms_protected_settings                                                  = "{ 'workspaceKey': '${var.oms_workspace_key}' }"
  }
}

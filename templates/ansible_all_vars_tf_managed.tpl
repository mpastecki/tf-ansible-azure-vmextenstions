---
# file: vars_tf_managed
# Non-sensitive group variables and references to sensitive variables.
# NOTE: The contents of this file are managed by terraform

############################################################################
# Settings for azure test VMs
############################################################################

region: "${region}"
resource_group: "${azurerm_resource_group.testenvgroup.name}"
diags_type_handler_version: "${linux_diagnostic_vm_extn_type_handler_version}"
diags_settings: "${diags_settings}"

oms_type_handler_version: "${oms_agent_for_linux_vm_extn_type_handler_version}"
omsagent_settings: "${oms_settings}"
omsagent_protected_settings: "${oms_protected_settings}"
oms_agent_for_linux_vm_extn_auto_upgrade_minor_version: "${oms_agent_for_linux_vm_extn_auto_upgrade_minor_version}"

resource "azurerm_resource_group" "testenvgroup" {
    name     = "${var.resourcegroupname}"
    location = "${var.region}"

    tags {
        environment = "Terraform Test"
    }
}

resource "azurerm_virtual_network" "testenvnetwork" {
    name                = "${var.networkname}"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.testenvgroup.name}"

    tags {
        environment = "Terraform Test"
    }
}

resource "azurerm_subnet" "testenvsubnet" {
    name                 = "${var.subnetname}"
    resource_group_name  = "${azurerm_resource_group.testenvgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.testenvnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "testenvpublicip" {
    count                        = "${var.vmscount}"
    name                         = "${var.publicipname}${count.index}"
    location                     = "${var.region}"
    resource_group_name          = "${azurerm_resource_group.testenvgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Test"
    }
}

resource "azurerm_network_security_group" "testenvpublicipnsg" {
    count               = "${var.vmscount}"
    name                = "${var.testenvpublicipsgname}${count.index}"
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.testenvgroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Test"
    }
}

resource "azurerm_network_interface" "testenvnic" {
    count               = "${var.vmscount}"
    name                = "${var.nicname}${count.index}"
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.testenvgroup.name}"

    ip_configuration {
        name                          = "testenvNicConfiguration${count.index}"
        subnet_id                     = "${azurerm_subnet.testenvsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.testenvpublicip.*.id, count.index)}"
    }

    tags {
        environment = "Terraform Test"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.testenvgroup.name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "testenvstorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.testenvgroup.name}"
    location            = "${var.region}"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "Terraform Test"
    }
}

resource "azurerm_virtual_machine" "testenvvm" {
    count                 = "${var.vmscount}"
    name                  = "myVM${count.index}"
    location              = "${var.region}"
    resource_group_name   = "${azurerm_resource_group.testenvgroup.name}"
    network_interface_ids = ["${element(azurerm_network_interface.testenvnic.*.id, count.index)}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "azvm${count.index}"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBA57xS0i+HNMNjRMLIBcXgxR+H3NKQ1283sGiZ1UMpgalt4BwY+uL3P3D0RLABynMSNjTRC7IjVIiDYEeRKZD6QOvE3Rs3dBnR9AVmaQoOHZNsAarNE+2jWir9NFtFi03fV8s0lYYFE4pnZIxO0q1KivaUE/ovGCyhXFP4uy1t/Ya4e8OicMm2ARTzm6z4XRayb5GKrRnavbEiz/+YvuvP4kB0U8T93/4QBHSOXzGUtszIVK/H3TpDCpjIxeY3dZc6kmcXUDQet6UdedzId6geJKO3R6e4AFfHn9ZrXlbdB4bEC0aFi+RNpZP/fgJWq97x47lVKg3rM+EEcmmWjCj"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.testenvstorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Test"
    }
}

data "azurerm_public_ip" "datasourceip" {
    count = "${var.vmscount}"
    name = "${var.publicipname}${count.index}"
    resource_group_name = "${azurerm_resource_group.testenvgroup.name}"
    depends_on = ["azurerm_virtual_machine.testenvvm"]
}

data "template_file" "ansible_hosts" {
  template = "${file("templates/ansiblehosts.tpl")}"
  vars = {
    vms_names   = "${join("\n", azurerm_virtual_machine.testenvvm.*.name)}"
  }
}

data "template_file" "ansible_all_vars_tf_managed" {
  template = "${file("templates/ansible_all_vars_tf_managed.tpl")}"
  vars {
    region							= "${var.region}"
    azurerm_resource_group.testenvgroup.name			= "${azurerm_resource_group.testenvgroup.name}"
    linux_diagnostic_vm_extn_type_handler_version		= "${data.null_data_source.local_vars.outputs["linux_diagnostic_vm_extn_type_handler_version"]}"
    diags_settings						= "${data.null_data_source.local_vars.outputs["diags_settings"]}"
    oms_agent_for_linux_vm_extn_type_handler_version		= "${data.null_data_source.local_vars.outputs["oms_agent_for_linux_vm_extn_type_handler_version"]}"
    oms_settings						= "${data.null_data_source.local_vars.outputs["oms_settings"]}"
    oms_protected_settings					= "${data.null_data_source.local_vars.outputs["oms_protected_settings"]}"
    oms_agent_for_linux_vm_extn_auto_upgrade_minor_version	= "${data.null_data_source.local_vars.outputs["oms_agent_for_linux_vm_extn_auto_upgrade_minor_version"]}"
  }
} 

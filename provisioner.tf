resource "null_resource" "vmsinstall_provisioner" {

  count = "${var.vmscount}"

  depends_on = [
    "azurerm_virtual_machine.testenvvm"
  ]

  triggers {
    key = "${azurerm_virtual_machine.testenvvm.*.id[count.index]}"
  }

  connection {
    host        = "${element(data.azurerm_public_ip.datasourceip.*.ip_address, count.index)}"
    user = "azureuser"
    agent = true
  }

  #############################################################
  # Upload and configure directories/files for Ansible
  #############################################################

  provisioner "file" {
    source = "${var.PATH_TO_PRIVATE_KEY}"
    destination = "/home/azureuser/.ssh/${var.PRIVATE_KEY_FILE_NAME}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/azureuser/ansible/playbooks/inventories/${var.ansible_inventory_name}/",
      "sudo chown -R azureuser:azureuser /home/azureuser/ansible",
      "sudo chown azureuser:azureuser /home/azureuser/.ssh/${var.PRIVATE_KEY_FILE_NAME}",
      "sudo chmod 600 /home/azureuser/.ssh/${var.PRIVATE_KEY_FILE_NAME}"
    ]
  }

  provisioner "file" {
    source      = "playbooks"
    destination = "/home/azureuser/ansible/"
  }

  # Generate Ansible hosts/inventory file from template
  provisioner "file" {
    content     = "${data.template_file.ansible_hosts.rendered}"
    destination = "/home/azureuser/ansible/playbooks/inventories/${var.ansible_inventory_name}/hosts"
  }

  # Generate Ansible vars file from template
  provisioner "file" {
    content     = "${data.template_file.ansible_all_vars_tf_managed.rendered}"
    destination = "/home/azureuser/ansible/playbooks/vmsvariables.yml"
  }


  #############################################################
  # Install Ansible and configure addons
  #############################################################

  provisioner "remote-exec" {
    inline = [
<<EOT
#!/bin/bash

## Cleanup code to run on exit (success or failure)
#function finish {
#  # Remove the uploaded deployment directories
#  sudo rm -rf "/home/azureuser/ansible/playbooks"
#}
#trap finish EXIT

# Install Ansible and dependencies
echo ""
echo "$(date) => [INFO]  => Install Ansible and dependencies."
sudo apt-get install software-properties-common -y
sudo apt-get install python-pip -y
sudo apt-get install python-setuptools -y
sudo pip install ansible[azure]
#sudo apt-add-repository ppa:ansible/ansible -y
#sudo apt-get update -y && sudo apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install python-jmespath ansible -y

# Set Ansible configuration via environment variables
echo ""
echo "$(date) => [INFO]  => Set Ansible configuration via environment variables."
export ANSIBLE_HOST_KEY_CHECKING=False
	
# Perform Ansible run to configure VMs
echo ""
echo "$(date) => [INFO]  => Perform Ansible run to configure VMs."
cd /home/azureuser/ansible/playbooks && \
ansible-playbook  diagsoms.yml \
--inventory-file=inventories/${var.ansible_inventory_name}/hosts \
--key-file="/home/azureuser/.ssh/${var.PRIVATE_KEY_FILE_NAME}"
EOT
    ]
  }
}

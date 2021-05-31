
provider "azurerm" {
features {}
}

resource "azurerm_resource_group" "mmps_rs" {
	name = "mmps_rs"
	location = "westus"
}

resource "azurerm_virtual_network" "mmps_net"{
	name = "mmps_net"
	location = "westus"
	address_space = ["10.0.0.0/16"]
	resource_group_name = "${azurerm_resource_group.mmps_rs.name}"
}

resource "azurerm_subnet" "mmps_subnet" {
  name                 = "mmps-sub"
  virtual_network_name = "${azurerm_virtual_network.mmps_net.name}"
  resource_group_name  = "${azurerm_resource_group.mmps_rs.name}"
  address_prefixes      = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "mmps_nsg"{
  name = "mmps_seg"
  location = "${azurerm_virtual_network.mmps_net.location}"
  resource_group_name = "${azurerm_resource_group.mmps_rs.name}"
  security_rule {
  			name = "HTTP"
  			priority = "100"
  			direction = "Inbound"
  			access = "Allow"
  			protocol = "TCP"
  			source_port_range = "*"
  			destination_port_range = "80"
  			source_address_prefix = "*"
  			destination_address_prefix = "*"
  			}

  security_rule{
  			name = "ssh"
  			priority = "101"
  			direction = "Inbound"
  			access = "Allow"
  			protocol = "TCP"
  			source_port_range = "*"
  			destination_port_range = "22"
  			source_address_prefix = "*"
  			destination_address_prefix = "*"
  			}

  }

resource "azurerm_public_ip" "mmps_public" {
	name = "mmps-pub"
	resource_group_name = "${ azurerm_resource_group.mmps_rs.name	}"
	allocation_method = "Dynamic"
	location =  "${azurerm_resource_group.mmps_rs.location}"

}

resource "azurerm_network_interface" "mmps_nic"{
	    name = "mmps_nic"
	    location = "${azurerm_virtual_network.mmps_net.location}"
	    resource_group_name = "${azurerm_resource_group.mmps_rs.name}"
	 //   network_security_group_id = "${azurerm_network_security_group.mmps_nsg.id}"

	ip_configuration {
	  name = "pub-nic"
	  //location = "${azurerm_resource_group.mmps_rs.location }"
	  subnet_id = "${azurerm_subnet.mmps_subnet.id}"
	 private_ip_address_allocation =     "Dynamic"
	  public_ip_address_id = "${azurerm_public_ip.mmps_public.id}"
	 
	}

}


resource "azurerm_linux_virtual_machine" "mmpsserver" {
  name                = "mmpsserver1"
  resource_group_name = "${azurerm_resource_group.mmps_rs.name}"
  location            = "${azurerm_resource_group.mmps_rs.location}"
  size                = "Standard_B1S"
  admin_username      = "manuprasad"
  network_interface_ids = [
    azurerm_network_interface.mmps_nic.id
  ]

  admin_ssh_key {
    username   = "manuprasad"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }


  provisioner "remote-exec" { 
    inline = ["echo 'Hello World'"]

    connection {
      type = "ssh"
      host = "${azurerm_linux_virtual_machine.mmpsserver.public_ip_address}"
      user = "manuprasad"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  provisioner "local-exec" {
    command = "echo [servers] > ./ansi-inventory ; echo ${ azurerm_linux_virtual_machine.mmpsserver.public_ip_address } >> ./ansi-inventory   "
  }


  provisioner "local-exec" {
    command = "ansible-playbook  -i  ./ansi-inventory   --private-key ~/.ssh/id_rsa httpd.yml"
  }


}


output "vm_ip" {
 value = "${azurerm_linux_virtual_machine.mmpsserver.public_ip_address}"
 }


output "vm_dns" {
 value = "http://${azurerm_linux_virtual_machine.mmpsserver.public_ip_address}"
 }

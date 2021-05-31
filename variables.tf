variable "ssh_key"{
	description = "ssh key for ubuntu"
	default = "/home/manuprasad/.ssh/id_rsa"
}

variable "ssh_key_path"{
	
	description = "path of the ssh"
	default = "/home/manuprasad/.ssh/id_rsa"

}

variable "ssh_pubkey"{
    description = "Public half of SSH key"
    default = "/home/manuprasad/.ssh/id_rsa.pub"	
}

variable "ssh_key_private"{

	description = "priavte key file"
	default = "~/.ssh/id_rsa"
}
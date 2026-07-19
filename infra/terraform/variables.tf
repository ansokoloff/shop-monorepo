variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "admin_username" {
  type    = string
  default = "adminuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key used to authenticate to the VMs"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "jenkins_admin_password" {
  type        = string
  description = "Пароль администратора Jenkins, задаётся через JCasC"
  sensitive   = true
}

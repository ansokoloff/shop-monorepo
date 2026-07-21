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
variable "jenkins_agent_private_key" {
  type        = string
  description = "Base64-encoded private key (PEM format) for SSH authentication to the Jenkins agent. Store the output of `[Convert]::ToBase64String([IO.File]::ReadAllBytes(<keyfile>))` as the secret value to avoid newline/whitespace corruption."
  sensitive   = true
}

variable "jenkins_agent_public_key" {
  type        = string
  description = "SSH public key used to authenticate to the Jenkins agent VM"
  sensitive   = true
}

variable "jenkins_agent_private_ip" {
  type        = string
  description = "Private IP address for the Jenkins agent VM"
  default     = "10.0.1.22"
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

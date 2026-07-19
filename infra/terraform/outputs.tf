output "controller_public_ip" {
  description = "Публичный IP Jenkins Controller"
  value       = azurerm_public_ip.controller.ip_address
}

output "controller_private_ip" {
  description = "Приватный IP Jenkins Controller"
  value       = azurerm_network_interface.controller.private_ip_address
}

output "agent_private_ip" {
  description = "Приватный IP Jenkins Agent"
  value       = azurerm_network_interface.agent.private_ip_address
}

output "jenkins_url" {
  description = "URL Jenkins UI"
  value       = "http://${azurerm_public_ip.controller.ip_address}:8080"
}

output "controller_ssh_command" {
  description = "Команда для SSH-подключения к Controller"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.controller.ip_address}"
}

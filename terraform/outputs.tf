# Only non-sensitive values are output. These four are handed over manually to the
# application repository for Ansible.

output "app_public_ip" {
  description = "Frontend (Nginx) public IP: the EpicBook URL"
  value       = azurerm_public_ip.frontend.ip_address
}

output "backend_ansible_host" {
  description = "Backend public IP, used only by Ansible over restricted SSH"
  value       = azurerm_public_ip.backend.ip_address
}

output "backend_private_ip" {
  description = "Backend private IP, used by Nginx as the proxy upstream"
  value       = azurerm_network_interface.backend.private_ip_address
}

output "mysql_fqdn" {
  description = "MySQL Flexible Server FQDN, resolvable only inside the VNet"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

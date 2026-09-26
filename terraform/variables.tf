variable "resource_group_name" {
  description = "Existing resource group that holds EpicBook (created before Terraform, with the state storage)"
  type        = string
  default     = "rg-oluwagbade-epicbook"
}

variable "location" {
  description = "Azure region (UK West: MySQL Flexible Server is not available in UK South on this subscription)"
  type        = string
  default     = "ukwest"
}

variable "admin_username" {
  description = "Admin user on both VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Public SSH key for the VMs, read from the Azure DevOps secure file at plan time"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "Source addresses allowed to SSH to the VMs (the pipeline agent and the admin workstation)"
  type        = list(string)
}

variable "frontend_vm_size" {
  description = "Frontend VM size (Nginx only)"
  type        = string
  default     = "Standard_B1s"
}

variable "backend_vm_size" {
  description = "Backend VM size (Node.js and npm install need about 2 GB)"
  type        = string
  default     = "Standard_B1ms"
}

variable "mysql_admin_login" {
  description = "MySQL administrator login"
  type        = string
  default     = "epicbookadmin"
}

variable "mysql_admin_password" {
  description = "MySQL administrator password, supplied from a secret pipeline variable"
  type        = string
  sensitive   = true
}

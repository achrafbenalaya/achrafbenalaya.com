variable "prefix" {
  description = "Prefix for all resources"
  default     = "copilot"
}

variable "location" {
    description = "Region to create resources"
    default     = "West Europe"
}

variable "vm_count" {
  description = "Number of virtual machines"
  default     = 2
}

variable "count" {
  description = "Number of virtual machines"
  default     = 2
}




# variable "admin_password" {
#   description = "Virtual Machine admin password"
# }
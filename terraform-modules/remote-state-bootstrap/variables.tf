variable "prefix" {
  type        = string
  description = "Customer shortCode used as a prefix in resource names (lowercase alphanumeric, max 8 chars)."
}

variable "location" {
  type        = string
  description = "Azure region for the resource group and storage account, e.g. 'westeurope'."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}

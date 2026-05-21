variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace to onboard to Microsoft Sentinel."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace (used in dependent resource references)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the Log Analytics workspace."
  type        = string
}

variable "location" {
  description = "Azure region of the Log Analytics workspace."
  type        = string
}

variable "tags" {
  description = "Tags applied to resources created by this module."
  type        = map(string)
  default     = {}
}

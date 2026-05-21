variable "prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "location" {
  description = "Azure region for all resources in this module instance."
  type        = string
}

variable "resource_group_name" {
  description = "Name of a pre-existing resource group to deploy resources into."
  type        = string
}

variable "log_analytics_topology" {
  description = "Logical topology label for the workspace. Each topology is implemented by calling the module once per region/continent — this value is used only as documentation; it does not change resource count within a single module call."
  type        = string
  default     = "global"

  validation {
    condition     = contains(["global", "per-region", "per-continent"], var.log_analytics_topology)
    error_message = "log_analytics_topology must be one of: global, per-region, per-continent."
  }
}

variable "additional_locations" {
  description = "Extra regions for per-region or per-continent topologies. Callers instantiate the module once per region; this list is informational only within a single call."
  type        = list(string)
  default     = []
}

variable "event_hub_enabled" {
  description = "Whether to create an Event Hub namespace and diagnostics hub for SIEM integration."
  type        = bool
  default     = true
}

variable "event_hub_max_throughput_units" {
  description = "Maximum throughput units for the Event Hub namespace auto-inflate setting."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "Log Analytics workspace data retention in days. Must be between 30 and 730."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "root_prefix" {
  description = "Prefix applied to every management group display name and name, e.g. \"contoso\"."
  type        = string
}

variable "layout" {
  description = "Management group hierarchy layout. Valid values: \"caf\" (full CAF hierarchy), \"flat\" (root only), \"custom\" (root only — extend manually)."
  type        = string
  default     = "caf"

  validation {
    condition     = contains(["caf", "flat", "custom"], var.layout)
    error_message = "layout must be one of: caf, flat, custom."
  }
}

variable "subscription_ids" {
  description = "Map of management group key to list of subscription IDs to associate. Valid keys: platform, landingzones, corp, online, sandbox, decommissioned, root."
  type        = map(list(string))
  default     = {}
}

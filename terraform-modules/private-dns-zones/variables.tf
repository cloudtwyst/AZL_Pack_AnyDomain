variable "resource_group_name" {
  description = "Name of the resource group where private DNS zones are created."
  type        = string
}

variable "zones" {
  description = "List of private DNS zone names to create. When empty, the built-in default list of common Azure PaaS zones is used."
  type        = list(string)
  default     = []
}

variable "vnet_links" {
  description = "Map of link name to VNet details. A VNet link is created for every combination of zone and link entry."
  type = map(object({
    vnet_id           = string
    auto_registration = bool
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

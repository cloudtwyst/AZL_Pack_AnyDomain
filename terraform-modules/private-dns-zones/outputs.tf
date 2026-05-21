output "zone_ids" {
  description = "Map of private DNS zone name to resource ID."
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}

output "zone_names" {
  description = "List of private DNS zone names created by this module."
  value       = keys(azurerm_private_dns_zone.this)
}

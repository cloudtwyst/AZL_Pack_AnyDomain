output "epac_build_client_id" {
  description = "Client (application) ID of the epac-build service principal."
  value       = azuread_application.epac_build.client_id
}

output "epac_deploy_client_id" {
  description = "Client (application) ID of the epac-deploy service principal."
  value       = azuread_application.epac_deploy.client_id
}

output "epac_build_object_id" {
  description = "Object ID of the epac-build service principal."
  value       = azuread_service_principal.epac_build.object_id
}

output "epac_deploy_object_id" {
  description = "Object ID of the epac-deploy service principal."
  value       = azuread_service_principal.epac_deploy.object_id
}

output "tenant_id" {
  description = "Azure AD tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}

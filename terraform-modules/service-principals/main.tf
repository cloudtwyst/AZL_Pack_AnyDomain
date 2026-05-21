data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# epac-build — read-only plan generation
# ---------------------------------------------------------------------------

resource "azuread_application" "epac_build" {
  display_name = "${var.prefix}-epac-build"
}

resource "azuread_service_principal" "epac_build" {
  client_id = azuread_application.epac_build.client_id
}

resource "azuread_application_federated_identity_credential" "epac_build" {
  for_each = toset(var.github_environments)

  application_id = azuread_application.epac_build.id
  display_name   = "github-${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:environment:${each.key}"
}

# Build SP needs read-only access to generate deployment plans (no write).
resource "azurerm_role_assignment" "epac_build_policy_reader" {
  scope                = var.root_management_group_id
  role_definition_name = "Resource Policy Reader"
  principal_id         = azuread_service_principal.epac_build.object_id
}

# ---------------------------------------------------------------------------
# epac-deploy — applies policy and role assignments
# ---------------------------------------------------------------------------

resource "azuread_application" "epac_deploy" {
  display_name = "${var.prefix}-epac-deploy"
}

resource "azuread_service_principal" "epac_deploy" {
  client_id = azuread_application.epac_deploy.client_id
}

resource "azuread_application_federated_identity_credential" "epac_deploy" {
  for_each = toset(var.github_environments)

  application_id = azuread_application.epac_deploy.id
  display_name   = "github-${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:environment:${each.key}"
}

resource "azurerm_role_assignment" "epac_deploy_policy_contributor" {
  scope                = var.root_management_group_id
  role_definition_name = "Resource Policy Contributor"
  principal_id         = azuread_service_principal.epac_deploy.object_id
}

# User Access Administrator is required for Deploy-RolesPlan.ps1.
resource "azurerm_role_assignment" "epac_deploy_uaa" {
  scope                = var.root_management_group_id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.epac_deploy.object_id
}

variable "prefix" {
  description = "Prefix used in service principal display names, e.g. \"contoso\"."
  type        = string
}

variable "root_management_group_id" {
  description = "ARM resource ID of the root management group. Role assignments are scoped here."
  type        = string
}

variable "github_org" {
  description = "GitHub organisation name, e.g. \"my-org\"."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix), e.g. \"azure-landing-zone\"."
  type        = string
}

variable "github_environments" {
  description = "List of GitHub environment names for OIDC federation. A federated credential is created for each environment on both service principals."
  type        = list(string)
  default     = ["epac-dev", "epac-nonprod", "epac-prod"]
}

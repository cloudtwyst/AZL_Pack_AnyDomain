# service-principals

Creates EPAC (Enterprise Policy as Code) service principals with OIDC Workload Identity Federation for GitHub Actions. No client secrets are created.

## Service principals

| SP | Purpose | Roles at root MG |
|----|---------|-----------------|
| `{prefix}-epac-build` | `Build-DeploymentPlans.ps1` — read-only plan generation | Resource Policy Contributor |
| `{prefix}-epac-deploy` | `Deploy-PolicyPlan.ps1`, `Deploy-RolesPlan.ps1` | Resource Policy Contributor, User Access Administrator |

## OIDC federation

A federated identity credential is created for each value in `github_environments` on both service principals. The subject claim format is:

```
repo:{github_org}/{github_repo}:environment:{environment_name}
```

The token audience is `api://AzureADTokenExchange` (standard Azure OIDC).

## Usage

```hcl
module "epac_sps" {
  source                   = "../terraform-modules/service-principals"
  prefix                   = "contoso"
  root_management_group_id = module.management_groups.root_management_group_id
  github_org               = "my-org"
  github_repo              = "azure-landing-zone"
}
```

## GitHub Actions configuration

Add the following secrets/variables to each GitHub environment (`epac-dev`, `epac-nonprod`, `epac-prod`):

| Name | Value |
|------|-------|
| `AZURE_CLIENT_ID` | `epac_build_client_id` or `epac_deploy_client_id` |
| `AZURE_TENANT_ID` | `tenant_id` output |
| `AZURE_SUBSCRIPTION_ID` | Your management subscription ID |

Use `azure/login@v2` with `client-id`, `tenant-id`, `subscription-id` (no secret needed).

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `prefix` | string | yes | — | SP display name prefix |
| `root_management_group_id` | string | yes | — | Root MG ARM resource ID |
| `github_org` | string | yes | — | GitHub organisation |
| `github_repo` | string | yes | — | GitHub repository name |
| `github_environments` | list(string) | no | `["epac-dev","epac-nonprod","epac-prod"]` | OIDC environments |

## Outputs

| Name | Description |
|------|-------------|
| `epac_build_client_id` | Build SP client ID |
| `epac_deploy_client_id` | Deploy SP client ID |
| `epac_build_object_id` | Build SP object ID |
| `epac_deploy_object_id` | Deploy SP object ID |
| `tenant_id` | Azure AD tenant ID |

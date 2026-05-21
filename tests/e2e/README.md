# End-to-end tests

These tests deploy the pack against a real Azure subscription and verify
that all resources are created as expected.

## Prerequisites

- Azure subscription dedicated to CI testing (not a production subscription).
- Service principal with Owner on the subscription.
- Environment variables:
  - `ARM_TENANT_ID`
  - `ARM_SUBSCRIPTION_ID`
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET` (or OIDC — preferred in CI)

## Running

```bash
cd tests/e2e
go test -v -timeout 60m ./...
```

## Structure

```
e2e/
  management_groups_test.go    — verifies MG hierarchy is created correctly
  monitoring_backbone_test.go  — verifies LAW + EH resources
  service_principals_test.go   — verifies SP + federated credentials
  policy_pipeline_test.go      — deploys a test policy, verifies compliance
```

> **Note:** E2e tests are not run on every PR. They run nightly against a
> dedicated test subscription. See `.github/workflows/e2e.yml` (added in v1.1).

## Cost estimate

A full e2e run deploys and destroys:
- 1 x Log Analytics workspace (~$0.10/GB ingested; test run ingests <1 MB)
- 1 x Event Hub namespace (Basic tier, ~$0.01/hour × ~1 hour = $0.01)
- Management groups (free)
- Service principals (free)

Total per run: **< $1.00**. Tear-down is automatic.

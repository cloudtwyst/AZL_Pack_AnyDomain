# Azure Secure Landing Zone — Solution Pack

A reusable, customer-agnostic pack that stands up EPAC + DINE-driven monitoring +
secure solution lifecycle in any customer's Azure tenant. Target onboarding time: 2–4 weeks.

See [SOLUTION-PACK.md](SOLUTION-PACK.md) for the full specification.

## Quick start

```powershell
Import-Module ./solpack/solpack.psm1
solpack validate customer-config.yaml
solpack init
solpack render
solpack deploy
```

## Requirements

- PowerShell 7+
- Terraform 1.6+
- Azure CLI
- EPAC (Enterprise Policy as Code)

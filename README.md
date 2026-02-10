## CI/CD (GitHub Actions)

Este repo tem dois workflows em `.github/workflows/`:

- `terraform-ci.yml` (CI)
  - Em PR: `terraform fmt -check`, `terraform validate` e scans (tfsec/checkov + gitleaks/trufflehog).
  - (Opcional) `terraform plan` no PR se `AWS_ROLE_ARN` estiver configurado (OIDC).
- `terraform-cd.yml` (CD opcional)
  - Manual (`workflow_dispatch`) com `plan` ou `apply`.
  - Usa `environment: production` para permitir gate/aprovacao no GitHub.
  - Assume Role via OIDC (sem chaves estaticas).

### Requisitos (OIDC)

1. No GitHub, configure `AWS_ROLE_ARN` como **Secret** ou **Variable** (repo ou org) apontando para uma IAM Role na AWS.
2. Na AWS, crie (se ainda nao existir) o OIDC Provider `token.actions.githubusercontent.com` e uma IAM Role com trust policy permitindo o seu repositorio.

Exemplo (ajuste `ACCOUNT_ID`, `OWNER` e `REPO`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GithubActionsCDProductionEnv",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:environment:production"
        }
      }
    },
    {
      "Sid": "GithubActionsCIPlanPR",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:pull_request"
        }
      }
    }
  ]
}
```

Para o desafio, voce pode anexar uma policy ampla (ex.: `AdministratorAccess`) a essa Role. Em ambiente real, ajuste para least-privilege.

### Gate de aprovacao (CD)

No GitHub: `Settings -> Environments -> production` e habilite aprovacao manual. O job `Terraform CD` vai esperar aprovacao antes de executar.

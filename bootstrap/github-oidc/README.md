# GitHub Actions ↔ AWS OIDC Bootstrap

One-time setup that lets GitHub Actions assume an IAM role in AWS without static credentials.

## What this creates

1. **IAM OIDC Identity Provider** for `token.actions.githubusercontent.com` (one per account)
2. **Two IAM Roles** with trust policies scoped to `nperezcaro/Terraform_AWS`:
   - `npc-awslab-gha-terraform-plan` — assumable only on `pull_request` events
   - `npc-awslab-gha-terraform-apply` — assumable only via the `dev` GitHub Environment
3. **Managed policies** attached to each role (ReadOnlyAccess for plan, AdministratorAccess for apply; scope down later)

## How OIDC federation works

```
GitHub Actions runner          AWS STS                  AWS IAM
─────────────────────          ────────                 ───────
1. Request OIDC token  ──────►
   (signed JWT)
                                                        Trust policy:
2. Assume role with  ────────► Verify JWT signature ──► - issuer = GitHub
   web identity                Check claims:             - sub = repo:owner/repo:...
                                aud, sub, iss            - aud = sts.amazonaws.com
                                                        ✓ allow
3. Receive temporary  ◄──────  Issue STS credentials
   credentials                  (15 min – 12 hr TTL)
   (AKIA..., session token)
```

No long-lived keys live anywhere. The JWT is valid for ~5 min; the STS credentials it produces are scoped to one role and one session.

## Apply order

1. **First time only:** apply this bootstrap from your laptop with admin credentials
2. Copy the `terraform_plan_role_arn` and `terraform_apply_role_arn` outputs into GitHub Secrets:
   - `AWS_PLAN_ROLE_ARN`
   - `AWS_APPLY_ROLE_ARN`
3. Create a GitHub Environment named `dev` in repo Settings → Environments
4. Set these GitHub Variables (repo or environment level) in Settings → Variables:
   - `DB_NAME` — e.g. `appdb`
   - `DB_USERNAME` — e.g. `dbadmin`
5. From this point forward, all Terraform and Ansible runs use OIDC — no local AWS creds needed

## Apply

```bash
cd bootstrap/github-oidc
export AWS_PROFILE=admin  # or whatever profile has admin rights
cp terraform.tfvars.example terraform.tfvars
# edit backend.tf with your actual S3 bucket / DynamoDB table names
terraform init
terraform apply
```

## Scoping permissions down later

`AdministratorAccess` is the maximally permissive starting point. Once your infra is stable, replace it with a custom policy listing only the actions Terraform actually needs. Use `aws iam generate-service-last-accessed-details` against the role after a few applies to see what's actually being called.

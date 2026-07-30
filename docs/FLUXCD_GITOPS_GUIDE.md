# FluxCD GitOps Guide

## Objective

Automate WordPress customer instance deployments with FluxCD.

## Workflow

1. Feature branches: run YAML + Helm + secret scanning CI checks.
2. Pull request merged to main: Flux source-controller detects the commit in Git.
3. Flux kustomize-controller reconciles [flux-system](../flux-system) and [clusters/production/wordpress-instances](../clusters/production/wordpress-instances).
4. Flux applies Kubernetes Secret resources for each customer namespace.

## Secret Strategy (Without SOPS)

1. Create per-customer secret files like [customer006-secrets.yaml](../clusters/production/wordpress-instances/customer006-secrets.yaml).
2. Keep production-only secret overrides in local untracked files (for example: `*-secrets.private.yaml`) and inject them through your deployment process.
3. If you keep secrets in Git, ensure repository access controls are strict and rotate credentials frequently.

### Alternatives for Safer Secret Handling

1. External Secrets Operator with cloud secret backends (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault).
2. Bitnami Sealed Secrets to keep encrypted Secret manifests in Git without SOPS.
3. CSI Secrets Store driver to mount secrets from external providers at runtime.

## Adding a New Customer Instance

1. Copy [customer006-release.yaml](../clusters/production/wordpress-instances/customer006-release.yaml) to a new customer file.
2. Update customer values (namespace, domain, node, resources).
3. Copy and update [customer006-secrets.yaml](../clusters/production/wordpress-instances/customer006-secrets.yaml).
4. Add both files to [kustomization.yaml](../clusters/production/wordpress-instances/kustomization.yaml).
5. Open a PR; CI runs on the branch.
6. Merge to main; Flux pulls and reconciles automatically based on the configured interval.

## Sync Options (Flux GitOps)

1. Interval-based pull (default): Flux reconciles GitRepository and Kustomization objects on a schedule.
2. Webhook-driven pull: configure Flux notifications receiver so pushes trigger immediate reconcile.
3. Manual/operational reconcile: trigger on demand with `flux reconcile source git <name>` and `flux reconcile kustomization <name>`.
4. Image automation: use ImageRepository/ImagePolicy/ImageUpdateAutomation for Git commit updates that Flux then reconciles.
5. Branch/environment split: run separate GitRepository/Kustomization per environment branch or path for controlled promotion.

## Notes

- Keep database and WordPress secrets out of plaintext YAML values files.
- Use separate secret files per customer namespace to reduce blast radius.
- Rotate database and WordPress salts regularly.

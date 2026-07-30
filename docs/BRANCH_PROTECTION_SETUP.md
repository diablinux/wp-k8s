# Branch Protection Setup (main)

This repository includes a branch protection payload template at:

- .github/branch-protection/main-required-checks.json

It requires the `yaml-lint-and-secret-scan` status check to pass before merging into `main`.
It allows the latest pusher to approve their own PR.
It does not require an approving review (solo-maintainer mode).

## Apply With GitHub CLI

Run from the repository root after authenticating with `gh auth login`:

```bash
OWNER="REPLACE_ME_OWNER"
REPO="wp-k8s"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${OWNER}/${REPO}/branches/main/protection" \
  --input .github/branch-protection/main-required-checks.json
```

## Verify

```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  "/repos/${OWNER}/${REPO}/branches/main/protection"
```

## Notes

- Ensure the workflow job name remains `yaml-lint-and-secret-scan` in [.github/workflows/yaml-security-ci.yml](../.github/workflows/yaml-security-ci.yml).
- If you rename the CI job, update the `context` field in the JSON template.
- `require_last_push_approval: false` allows the latest pusher (including PR author) to approve.
- `required_approving_review_count: 0` removes mandatory reviewer approvals while still enforcing required status checks.

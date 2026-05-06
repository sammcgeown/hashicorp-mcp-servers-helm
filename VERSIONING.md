# Chart Versioning

This document describes how chart versions are managed in this repository and how the release pipeline works.

## How releases work

Pushes to `main` that touch any file under `charts/` trigger the `release-helm-charts` GitHub Actions workflow. The workflow uses [`helm/chart-releaser-action`](https://github.com/helm/chart-releaser-action), which:

1. Compares each chart's `version` in `Chart.yaml` against existing GitHub release tags (e.g. `vault-mcp-0.1.1`).
2. For any chart whose version has no matching tag, packages it and creates a GitHub release with the `.tgz` as an asset.
3. Updates the `gh-pages` Helm repository index so the new version is immediately installable.

`CR_SKIP_EXISTING: true` is set, so a chart whose version already has a release tag is silently skipped rather than failing the job.

**Consequence:** if you push changes to a chart without bumping its `version`, no new release is produced.

## Semantic versioning rules

Chart versions follow [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`), applied to the Helm chart itself — not the application it deploys.

| Change type | Version field | Examples |
|---|---|---|
| Bug fixes, template corrections, values default changes | `PATCH` (0.1.1 → 0.1.2) | Fixing a service name mismatch, removing a deprecated annotation |
| New optional features | `MINOR` (0.1.x → 0.2.0) | Adding PodDisruptionBudget, NOTES.txt, helm tests |
| Breaking changes to the values schema | `MAJOR` (0.x.x → 1.0.0) | Renaming or removing a required values key |

### appVersion

`appVersion` tracks the **default application image tag** in `values.yaml`. It should be updated whenever the `image.tag` default changes. It does not affect the chart release tag — only `version` does.

## Two-field summary

```yaml
version: 0.2.0      # Chart version — controls GitHub release tags
appVersion: "0.5.2" # Default image tag — informational only
```

## Dependency coordination

`hashicorp-mcp` is a parent chart that bundles `vault-mcp` and `terraform-mcp` as pre-packaged dependencies (`.tgz` files in `charts/hashicorp-mcp/charts/`). Any change to a subchart requires updating the parent. Follow this order:

```
1.  Bump the subchart's version in charts/<subchart>/Chart.yaml
    - Also bump appVersion if the default image tag changed

2.  Package the updated subchart into the parent's charts/ directory:
      helm package charts/vault-mcp -d charts/hashicorp-mcp/charts/
      helm package charts/terraform-mcp -d charts/hashicorp-mcp/charts/

3.  Delete the old .tgz files from charts/hashicorp-mcp/charts/
    (helm package does not remove them automatically)

4.  Update charts/hashicorp-mcp/Chart.yaml:
    - Set each dependency's version to the new subchart version
    - Bump the parent chart's own version

5.  Regenerate the lock file:
      helm dependency update charts/hashicorp-mcp

6.  Lint and template-check all three charts:
      helm lint charts/vault-mcp
      helm lint charts/terraform-mcp
      helm lint charts/hashicorp-mcp
      helm template test charts/hashicorp-mcp

7.  Commit all changed files together in a single commit (or one per chart).
```

## Which chart(s) to bump

| What changed | Bump |
|---|---|
| Subchart templates or values only | Subchart + parent |
| Parent templates or values only | Parent only |
| Both subchart and parent | Both subcharts + parent |
| Only `appVersion` (image tag update, no other change) | Subchart (`PATCH`) + parent (`PATCH`) |

## Example: bumping after a bug fix to vault-mcp

```bash
# 1. Edit charts/vault-mcp/Chart.yaml: version 0.2.0 -> 0.2.1

# 2. Repackage
helm package charts/vault-mcp -d charts/hashicorp-mcp/charts/

# 3. Remove old package
rm charts/hashicorp-mcp/charts/vault-mcp-0.2.0.tgz

# 4. Edit charts/hashicorp-mcp/Chart.yaml:
#    - dependencies vault-mcp version: "0.2.0" -> "0.2.1"
#    - version: 0.2.0 -> 0.2.1

# 5. Regenerate lock
helm dependency update charts/hashicorp-mcp

# 6. Lint
helm lint charts/vault-mcp charts/hashicorp-mcp

# 7. Commit
git add charts/vault-mcp/Chart.yaml \
        charts/hashicorp-mcp/Chart.yaml \
        charts/hashicorp-mcp/Chart.lock \
        charts/hashicorp-mcp/charts/vault-mcp-0.2.1.tgz
git commit -m "fix(vault-mcp): bump to 0.2.1"
```

## Adding a new subchart

1. Create the chart under `charts/<name>/` following the existing pattern.
2. Add it as a dependency in `charts/hashicorp-mcp/Chart.yaml` with `condition: <name>.enabled`.
3. Add a disabled-by-default block in `charts/hashicorp-mcp/values.yaml`.
4. Follow the dependency coordination steps above.
5. Start at `version: 0.1.0` for new charts.

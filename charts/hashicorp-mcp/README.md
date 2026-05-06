# HashiCorp MCP Helm Chart

A parent Helm chart for deploying multiple HashiCorp Model Context Protocol (MCP) servers with a unified ingress configuration.

> **Note:** This Helm chart is provided "as-is" and is not officially maintained by HashiCorp.

## Overview

This parent chart provides a centralized way to deploy and manage multiple HashiCorp MCP servers with a single ingress that routes traffic based on URL paths. Each MCP server is deployed as a subchart and can be independently enabled or disabled.

## Features

- **Unified Ingress or HTTPRoute**: Single domain with path-based routing via Kubernetes Ingress or Gateway API HTTPRoute
- **Optional Subcharts**: Enable only the MCP servers you need
- **TLS Support**: Built-in support for TLS with cert-manager integration (works with both Ingress and HTTPRoute)
- **Flexible Configuration**: Override subchart values as needed

## Architecture

```
https://mcp.example.com/terraform  →  Terraform MCP Server
https://mcp.example.com/vault      →  Vault MCP Server
```

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+
- (Optional) cert-manager for automatic TLS certificate management

## Installation

### Installation from Repository

```bash
helm repo add hashicorp-mcp https://sammcgeown.github.io/hashicorp-mcp-servers-helm/
helm repo update
helm install hashicorp-mcp hashicorp-mcp/hashicorp-mcp -n mcp-servers --create-namespace
```

### Installation from Source

```bash
git clone https://github.com/sammcgeown/hashicorp-mcp-servers-helm.git
cd hashicorp-mcp-servers-helm

helm dependency update charts/hashicorp-mcp
helm install hashicorp-mcp charts/hashicorp-mcp -n mcp-servers --create-namespace
```

### Installation with Custom Values

```bash
helm install hashicorp-mcp hashicorp-mcp/hashicorp-mcp -f custom-values.yaml -n mcp-servers --create-namespace
```

## Configuration

### Parent Chart Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable unified Ingress | `true` |
| `ingress.ingressClassName` | Ingress class name | `traefik` |
| `ingress.host` | Hostname for all MCP servers | `mcp.example.com` |
| `ingress.annotations` | Custom annotations for ingress | `{}` |
| `ingress.tls.enabled` | Enable TLS | `true` |
| `ingress.tls.secretName` | TLS secret name | `hashicorp-mcp-tls` |
| `httproute.enabled` | Enable Gateway API HTTPRoute (mutually exclusive with ingress) | `false` |
| `certificate.enabled` | Enable cert-manager Certificate (works with ingress or httproute) | `false` |
| `terraform-mcp.enabled` | Enable Terraform MCP subchart | `true` |
| `terraform-mcp.path` | Path prefix for Terraform MCP | `/terraform` |
| `terraform-mcp.image.repository` | Container image repository | `hashicorp/terraform-mcp-server` |
| `terraform-mcp.image.tag` | Container image tag | `0.5.2` |
| `terraform-mcp.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `terraform-mcp.tls.mount` | Mount TLS certificate into the pod | `false` |
| `terraform-mcp.tls.secretName` | TLS secret name to mount | `hashicorp-mcp-tls` |
| `vault-mcp.enabled` | Enable Vault MCP subchart | `true` |
| `vault-mcp.path` | Path prefix for Vault MCP | `/vault` |
| `vault-mcp.image.repository` | Container image repository | `hashicorp/vault-mcp-server` |
| `vault-mcp.image.tag` | Container image tag | `0.2.0` |
| `vault-mcp.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `vault-mcp.tls.mount` | Mount TLS certificate into the pod | `false` |
| `vault-mcp.tls.secretName` | TLS secret name to mount | `hashicorp-mcp-tls` |

### Subchart Configuration

Override any subchart value by prefixing it with the subchart name:

```yaml
terraform-mcp:
  enabled: true
  path: /terraform
  replicaCount: 5
  env:
    TFE_ADDRESS: "https://terraform.example.com"

vault-mcp:
  enabled: true
  path: /vault
  replicaCount: 3
  env:
    VAULT_ADDR: "https://vault.example.com"
```

## Examples

### Minimal Configuration

```yaml
ingress:
  host: mcp.example.com

terraform-mcp:
  enabled: true
  tfeSecret:
    name: tfe-token-secret

vault-mcp:
  enabled: true
  vaultSecret:
    name: vault-token-secret
```

### Production Configuration with TLS

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  host: mcp.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  tls:
    enabled: true
    secretName: hashicorp-mcp-tls

certificate:
  enabled: true
  name: hashicorp-mcp-tls
  commonName: mcp.example.com
  issuer:
    name: letsencrypt-production
    kind: ClusterIssuer

terraform-mcp:
  enabled: true
  path: /terraform
  replicaCount: 5
  image:
    tag: "0.5.2"
  tls:
    mount: true
    secretName: hashicorp-mcp-tls
  tfeSecret:
    name: tfe-token-secret
  env:
    TFE_ADDRESS: "https://terraform.example.com"
    ENABLE_TF_OPERATIONS: "true"
  resources:
    requests:
      cpu: "200m"
      memory: "256Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
  podDisruptionBudget:
    enabled: true
    minAvailable: 2

vault-mcp:
  enabled: true
  path: /vault
  replicaCount: 3
  image:
    tag: "0.2.0"
  tls:
    mount: true
    secretName: hashicorp-mcp-tls
  vaultSecret:
    name: vault-token-secret
  env:
    VAULT_ADDR: "https://vault.example.com"
  resources:
    requests:
      cpu: "200m"
      memory: "256Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"
  podDisruptionBudget:
    enabled: true
    minAvailable: 1
```

### Gateway API HTTPRoute Configuration

Use this when your cluster uses the Gateway API instead of a traditional Ingress controller:

```yaml
ingress:
  enabled: false

httproute:
  enabled: true
  hostnames:
    - mcp.example.com
  parentRefs:
    - name: my-gateway
      namespace: gateway-system

certificate:
  enabled: true
  commonName: mcp.example.com
  issuer:
    name: letsencrypt-production
    kind: ClusterIssuer
```

### Disable a Subchart

```yaml
terraform-mcp:
  enabled: false

vault-mcp:
  enabled: true
```

### Custom Path Configuration

```yaml
ingress:
  host: api.example.com

terraform-mcp:
  path: /v1/terraform

vault-mcp:
  path: /v1/vault
```

## Accessing the Services

After installation, the MCP endpoints will be available at:

- **Terraform MCP**: `https://<ingress.host><terraform-mcp.path>/mcp`
  - Example: `https://mcp.example.com/terraform/mcp`
- **Vault MCP**: `https://<ingress.host><vault-mcp.path>/mcp`
  - Example: `https://mcp.example.com/vault/mcp`

## Testing

Run the built-in connectivity tests after installation:

```bash
helm test hashicorp-mcp -n mcp-servers
```

## Upgrading

```bash
helm repo update
helm upgrade hashicorp-mcp hashicorp-mcp/hashicorp-mcp -f values.yaml -n mcp-servers
```

## Uninstalling

```bash
helm uninstall hashicorp-mcp -n mcp-servers
```

## Troubleshooting

### Check All Pods

```bash
kubectl get pods -n mcp-servers
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=terraform-mcp -n mcp-servers
kubectl logs -l app.kubernetes.io/name=vault-mcp -n mcp-servers
```

### Check Ingress

```bash
kubectl get ingress -n mcp-servers
kubectl describe ingress hashicorp-mcp-ingress -n mcp-servers
```

### Test Endpoints via Port-Forward

Service names follow the pattern `<release-name>-<subchart>-svc`. For a release named `hashicorp-mcp`:

```bash
# Terraform MCP
kubectl port-forward -n mcp-servers svc/hashicorp-mcp-terraform-mcp-svc 8080:80
curl http://localhost:8080/mcp

# Vault MCP
kubectl port-forward -n mcp-servers svc/hashicorp-mcp-vault-mcp-svc 8081:80
curl http://localhost:8081/mcp

# Test through ingress (if configured)
curl https://mcp.example.com/terraform/mcp
curl https://mcp.example.com/vault/mcp
```

### Dependency Issues

If you see errors about missing subcharts when installing from source:

```bash
helm dependency update charts/hashicorp-mcp
```

## Adding More MCP Servers

Additional MCP servers can be added as dependencies in `Chart.yaml`. Publish the new chart to the Helm repository first, then reference it:

```yaml
dependencies:
  - name: terraform-mcp
    version: "0.2.0"
    repository: "https://sammcgeown.github.io/hashicorp-mcp-servers-helm/"
    condition: terraform-mcp.enabled
  - name: vault-mcp
    version: "0.2.0"
    repository: "https://sammcgeown.github.io/hashicorp-mcp-servers-helm/"
    condition: vault-mcp.enabled
  - name: another-mcp
    version: "0.1.0"
    repository: "https://sammcgeown.github.io/hashicorp-mcp-servers-helm/"
    condition: another-mcp.enabled
```

Then add a path and enable flag in `values.yaml`:

```yaml
another-mcp:
  enabled: false
  path: /another
```

See [VERSIONING.md](../../VERSIONING.md) for the full process of adding and releasing a new subchart.

## Individual Subchart Documentation

- [Terraform MCP Chart](../terraform-mcp/README.md)
- [Vault MCP Chart](../vault-mcp/README.md)

## Support

For issues and questions:
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Vault MCP Server](https://github.com/hashicorp/vault-mcp-server)
- Create an issue in this repository

## License

See [LICENSE](../../LICENSE) file in the repository root.

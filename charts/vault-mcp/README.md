# Vault MCP Helm Chart

This Helm chart deploys the Vault Model Context Protocol (MCP) Server on Kubernetes.

> **Note:** This Helm chart is provided "as-is" and is not officially maintained by HashiCorp.

## Overview

The Vault MCP Server provides an MCP interface for interacting with HashiCorp Vault, enabling AI assistants and other tools to manage secrets, authentication, and other Vault operations.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- (Optional) A HashiCorp Vault instance and token - required only if you want the MCP server to perform actions in Vault

## Installation

### Basic Installation

```bash
helm install vault-mcp ./vault-mcp
```

### Installation with Custom Values

```bash
helm install vault-mcp ./vault-mcp -f custom-values.yaml
```

### Installation from Repository

If you're using a Helm repository:

```bash
helm repo add hashicorp-mcp <repository-url>
helm repo update
helm install vault-mcp hashicorp-mcp/vault-mcp
```

## Configuration

### Optional: Vault Token

The MCP server can run without a Vault token, but you'll need to configure one if you want it to perform actions in Vault:

#### Option 1: Create Secret via Values (Not Recommended for Production)

```yaml
vaultSecret:
  create: true
  token: "your-vault-token-here"
```

#### Option 2: Use Existing Secret (Recommended)

Create a Kubernetes secret manually:

```bash
kubectl create secret generic vault-token-secret \
  --from-literal=VAULT_TOKEN=your-vault-token-here
```

Then reference it in your values:

```yaml
vaultSecret:
  create: false
  name: vault-token-secret
```

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `3` |
| `image.repository` | Container image repository | `hashicorp/vault-mcp-server` |
| `image.tag` | Container image tag | `0.2.0` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.host` | Ingress hostname | `vault-mcp.lab.definit.co.uk` |
| `ingress.annotations` | Custom annotations for ingress | `{}` |
| `ingress.tls.enabled` | Enable TLS on ingress | `true` |
| `env.VAULT_ADDR` | Vault server URL | `https://vault.example.com` |
| `env.TRANSPORT_MODE` | Transport mode | `streamable-http` |
| `env.MCP_ENDPOINT` | MCP endpoint path | `/mcp` |

### Environment Variables

The chart supports extensive environment variable configuration:

#### Vault Settings
- `VAULT_ADDR`: URL of your Vault instance
- `VAULT_SKIP_VERIFY`: Skip TLS verification (use with caution)

#### Transport Configuration
- `TRANSPORT_MODE`: Transport protocol (`streamable-http`)
- `TRANSPORT_HOST`: Listen address
- `TRANSPORT_PORT`: Listen port

#### MCP Settings
- `MCP_ENDPOINT`: Endpoint path for MCP requests
- `MCP_SESSION_MODE`: Session handling mode
- `MCP_ALLOWED_ORIGINS`: CORS allowed origins
- `MCP_CORS_MODE`: CORS mode (`strict` or `permissive`)
- `MCP_RATE_LIMIT_GLOBAL`: Global rate limiting
- `MCP_RATE_LIMIT_SESSION`: Per-session rate limiting

### TLS Configuration

#### Using Cert-Manager

Enable automatic certificate generation:

```yaml
certificate:
  enabled: true
  name: vault-mcp-tls
  commonName: vault-mcp.example.com
  issuer:
    name: letsencrypt-production
    kind: ClusterIssuer

ingress:
  tls:
    enabled: true
    secretName: vault-mcp-tls
```

#### Using Existing TLS Secret

```yaml
tls:
  mount: true
  secretName: your-tls-secret

ingress:
  tls:
    enabled: true
    secretName: your-tls-secret
```

## Examples

### Minimal Configuration (Without Ingress)

```yaml
vaultSecret:
  create: false
```

### With Ingress Enabled

```yaml
ingress:
  enabled: true
  host: vault-mcp.example.com

vaultSecret:
  create: false
```

### Basic Configuration (With Vault Token)

```yaml
ingress:
  enabled: true
  host: vault-mcp.example.com

vaultSecret:
  create: false
  name: vault-token-secret
```

### Production Configuration

```yaml
replicaCount: 5

resources:
  requests:
    cpu: "200m"
    memory: "256Mi"
  limits:
    cpu: "1000m"
    memory: "1Gi"

vaultSecret:
  create: false
  name: vault-token-secret

ingress:
  enabled: true
  ingressClassName: nginx
  host: vault-mcp.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
  tls:
    enabled: true
    secretName: vault-mcp-tls

certificate:
  enabled: true
  name: vault-mcp-tls
  commonName: vault-mcp.example.com
  issuer:
    name: letsencrypt-production
    kind: ClusterIssuer

env:
  VAULT_ADDR: "https://vault.example.com"
  MCP_ALLOWED_ORIGINS: "https://app.example.com"
  MCP_RATE_LIMIT_GLOBAL: "20:40"
  MCP_RATE_LIMIT_SESSION: "10:20"
```

### Development Configuration

```yaml
replicaCount: 1

vaultSecret:
  create: true
  token: "dev-token-here"

ingress:
  enabled: false

env:
  VAULT_SKIP_VERIFY: "true"
  MCP_CORS_MODE: "permissive"
```

## Upgrading

```bash
helm upgrade vault-mcp ./vault-mcp -f values.yaml
```

## Uninstalling

```bash
helm uninstall vault-mcp
```

## Health Checks

The chart includes liveness and readiness probes:

- **Liveness Probe**: Checks `/health` endpoint every 10 seconds
- **Readiness Probe**: Checks `/health` endpoint every 10 seconds

## Accessing the Service

After installation, the MCP endpoint will be available at:

- **Internal**: `http://vault-mcp.<namespace>.svc.cluster.local/mcp`
- **External** (if ingress enabled): `https://<ingress.host>/mcp`

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=vault-mcp
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=vault-mcp
```

### Check Service

```bash
kubectl get svc vault-mcp
```

### Test Health Endpoint

```bash
kubectl port-forward svc/vault-mcp 8080:80
curl http://localhost:8080/health
```

## Support

For issues and questions:
- [Vault MCP Server Documentation](https://github.com/hashicorp/vault-mcp-server)
- Create an issue in the repository

## License

See [LICENSE](../../LICENSE) file in the repository root.

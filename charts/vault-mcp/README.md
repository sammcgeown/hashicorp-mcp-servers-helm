# Vault MCP Helm Chart

This Helm chart deploys the Vault Model Context Protocol (MCP) Server on Kubernetes.

> **Note:** This Helm chart is provided "as-is" and is not officially maintained by HashiCorp.


Please take note of the following warning, copied from the official Vault MCP Server docs:

> **⚠️ Beta Feature**
>
> Beta functionality is stable but possibly incomplete and subject to change. We strongly discourage using beta features in production deployments of Vault.

> **⚠️ Security Disclaimer**
>
> Depending on the query, the MCP server may expose certain Vault data, including Vault secrets, to MCP clients and LLMs interacting with the server. **Do not use the MCP server with untrusted MCP clients or LLMs.**
>
> Your use of third-party MCP clients and LLMs is subject solely to the terms of use for those MCP servers and LLMs. HashiCorp is not responsible for the performance of such third party tools. HashiCorp expressly disclaims any and all warranties and liability for third party MCP clients and LLMs, and may not be able to provide support to resolve issues caused by the third party tools.

## Overview

The Vault MCP Server provides an MCP interface for interacting with HashiCorp Vault, enabling AI assistants and other tools to manage secrets, authentication, and other Vault operations.

📖 **[Official Vault MCP Server Documentation](https://developer.hashicorp.com/vault/docs/mcp-server/overview)**

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+
- (Optional) A HashiCorp Vault instance and token - required only if you want the MCP server to perform actions in Vault

## Installation

### Basic Installation

```bash
helm install vault-mcp hashicorp-mcp/vault-mcp -n mcp-servers --create-namespace
```

### Installation with Custom Values

```bash
helm install vault-mcp hashicorp-mcp/vault-mcp -f custom-values.yaml -n mcp-servers --create-namespace
```

### Installation from Repository

```bash
helm repo add hashicorp-mcp https://sammcgeown.github.io/hashicorp-mcp-servers-helm/
helm repo update
helm install vault-mcp hashicorp-mcp/vault-mcp -n mcp-servers --create-namespace
```

## Configuration

### Vault Authentication

The MCP server supports multiple authentication approaches. Configure the method that matches your Vault setup.

#### Token Authentication (simplest)

Create a Kubernetes secret containing the Vault token:

```bash
kubectl create secret generic vault-token-secret \
  --from-literal=VAULT_TOKEN=your-vault-token-here \
  -n mcp-servers
```

Reference it in your values:

```yaml
vaultSecret:
  name: vault-token-secret  # chart injects VAULT_TOKEN from this secret
```

To create the secret via the chart (not recommended for production):

```yaml
vaultSecret:
  create: true
  name: vault-token-secret
  token: "your-vault-token-here"
```

#### Alternative Auth Methods (AppRole, Kubernetes Auth, etc.)

Set `vaultSecret.name` to an empty string to skip VAULT_TOKEN injection entirely. The application then relies on other environment variables or a Vault agent sidecar:

```yaml
vaultSecret:
  name: ""  # no VAULT_TOKEN env var injected

env:
  VAULT_ADDR: "https://vault.example.com"
  # configure AppRole or other auth via additional env vars or a sidecar
```

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `3` |
| `image.repository` | Container image repository | `hashicorp/vault-mcp-server` |
| `image.tag` | Container image tag | `0.2.0` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable Ingress | `false` |
| `ingress.ingressClassName` | Ingress class name | `traefik` |
| `ingress.host` | Ingress hostname | `vault-mcp.example.com` |
| `ingress.annotations` | Custom annotations for ingress | `{}` |
| `ingress.tls.enabled` | Enable TLS on ingress | `true` |
| `httproute.enabled` | Enable Gateway API HTTPRoute (mutually exclusive with ingress) | `false` |
| `tls.mount` | Mount TLS certificate into the pod | `false` |
| `tls.secretName` | Name of the TLS secret to mount | `vault-mcp-tls` |
| `certificate.enabled` | Enable cert-manager Certificate | `false` |
| `vaultSecret.name` | Secret containing VAULT_TOKEN; set to `""` to disable injection | `vault-token-secret` |
| `vaultSecret.create` | Create the secret from chart values | `false` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `false` |
| `podDisruptionBudget.minAvailable` | Minimum available pods during disruption | `1` |
| `env.VAULT_ADDR` | Vault server URL | `https://vault.example.com` |
| `env.TRANSPORT_MODE` | Transport mode | `streamable-http` |
| `env.MCP_ENDPOINT` | MCP endpoint path | `/mcp` |

### Environment Variables

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

`certificate.enabled` works independently of whether you use Ingress or HTTPRoute:

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

#### Mounting TLS into the Pod

Enable when the application itself needs to serve or verify TLS (sets `MCP_TLS_CERT_FILE` and `MCP_TLS_KEY_FILE` automatically):

```yaml
tls:
  mount: true
  secretName: vault-mcp-tls
```

## Examples

### Minimal Configuration (No Ingress)

```yaml
vaultSecret:
  name: vault-token-secret

env:
  VAULT_ADDR: "https://vault.example.com"
```

### With Ingress Enabled

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  host: vault-mcp.example.com

vaultSecret:
  name: vault-token-secret

env:
  VAULT_ADDR: "https://vault.example.com"
```

### With Gateway API HTTPRoute

```yaml
ingress:
  enabled: false

httproute:
  enabled: true
  hostnames:
    - vault-mcp.example.com
  parentRefs:
    - name: my-gateway
      namespace: gateway-system

vaultSecret:
  name: vault-token-secret

env:
  VAULT_ADDR: "https://vault.example.com"
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

podDisruptionBudget:
  enabled: true
  minAvailable: 2

vaultSecret:
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

## Testing

Run the built-in connectivity test after installation:

```bash
helm test vault-mcp -n mcp-servers
```

The test pod performs a `wget --spider` check against the MCP endpoint on the chart's service.

## Upgrading

```bash
helm repo update
helm upgrade vault-mcp hashicorp-mcp/vault-mcp -f values.yaml -n mcp-servers
```

## Uninstalling

```bash
helm uninstall vault-mcp -n mcp-servers
```

## Health Checks

The chart includes liveness and readiness probes on the `/health` endpoint:

- **Liveness Probe**: initial delay 30s, period 10s
- **Readiness Probe**: initial delay 5s, period 10s

## Security

All pods run with a restricted security context:

- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true`
- `capabilities.drop: ["ALL"]`
- `seccompProfile: RuntimeDefault`

## Accessing the Service

After installation, the MCP endpoint will be available at:

- **Internal**: `http://<release-name>-vault-mcp-svc.<namespace>.svc.cluster.local/mcp`
- **External** (if ingress enabled): `https://<ingress.host>/mcp`

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=vault-mcp -n mcp-servers
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=vault-mcp -n mcp-servers
```

### Check Service

Service names follow the pattern `<release-name>-vault-mcp-svc`:

```bash
kubectl get svc -l app.kubernetes.io/name=vault-mcp -n mcp-servers
```

### Test Health Endpoint

```bash
# Replace <release-name> with your Helm release name
kubectl port-forward -n mcp-servers svc/<release-name>-vault-mcp-svc 8080:80
curl http://localhost:8080/health
curl http://localhost:8080/mcp
```

## Support

For issues and questions:
- [Official Vault MCP Server Documentation](https://developer.hashicorp.com/vault/docs/mcp-server/overview)
- [Vault MCP Server GitHub](https://github.com/hashicorp/vault-mcp-server)
- Create an issue in the repository

## License

See [LICENSE](../../LICENSE) file in the repository root.

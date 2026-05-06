# Terraform MCP Helm Chart

This Helm chart deploys the Terraform Model Context Protocol (MCP) Server on Kubernetes.

> **Note:** This Helm chart is provided "as-is" and is not officially maintained by HashiCorp.

## Overview

The Terraform MCP Server provides an MCP interface for interacting with Terraform Enterprise/Cloud, enabling AI assistants and other tools to manage Terraform workspaces, runs, and configurations.

📖 **[Official Terraform MCP Server Documentation](https://developer.hashicorp.com/terraform/mcp-server)**

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+
- (Optional) A Terraform Enterprise or Terraform Cloud API token - required only if you want the MCP server to perform actions in Terraform Enterprise/Cloud

## Installation

### Basic Installation

```bash
helm install terraform-mcp hashicorp-mcp/terraform-mcp -n mcp-servers --create-namespace
```

### Installation with Custom Values

```bash
helm install terraform-mcp hashicorp-mcp/terraform-mcp -f custom-values.yaml -n mcp-servers --create-namespace
```

### Installation from Repository

```bash
helm repo add hashicorp-mcp https://sammcgeown.github.io/hashicorp-mcp-servers-helm/
helm repo update
helm install terraform-mcp hashicorp-mcp/terraform-mcp -n mcp-servers --create-namespace
```

## Configuration

### Optional: Terraform Enterprise/Cloud API Token

The MCP server can run without a Terraform Enterprise/Cloud API token, but you'll need to configure one if you want it to perform actions in Terraform Enterprise or Cloud:

#### Option 1: Use Existing Secret (Recommended)

Create a Kubernetes secret manually:

```bash
kubectl create secret generic tfe-token-secret \
  --from-literal=TFE_TOKEN=your-tfe-token-here \
  -n mcp-servers
```

Then reference it in your values:

```yaml
tfeSecret:
  name: tfe-token-secret
```

#### Option 2: Create Secret via Values (Not Recommended for Production)

```yaml
tfeSecret:
  create: true
  token: "your-tfe-token-here"
```

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `3` |
| `image.repository` | Container image repository | `hashicorp/terraform-mcp-server` |
| `image.tag` | Container image tag | `0.5.2` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable Ingress | `false` |
| `ingress.ingressClassName` | Ingress class name | `traefik` |
| `ingress.host` | Ingress hostname | `terraform-mcp.example.com` |
| `ingress.annotations` | Custom annotations for ingress | `{}` |
| `ingress.tls.enabled` | Enable TLS on ingress | `true` |
| `httproute.enabled` | Enable Gateway API HTTPRoute (mutually exclusive with ingress) | `false` |
| `tls.mount` | Mount TLS certificate into the pod | `false` |
| `tls.secretName` | Name of the TLS secret to mount | `terraform-mcp-tls` |
| `certificate.enabled` | Enable cert-manager Certificate | `false` |
| `tfeSecret.name` | Secret containing TFE_TOKEN | `tfe-token-secret` |
| `tfeSecret.create` | Create the secret from chart values | `false` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `false` |
| `podDisruptionBudget.minAvailable` | Minimum available pods during disruption | `1` |
| `env.TFE_ADDRESS` | Terraform Enterprise/Cloud URL | `https://app.terraform.io` |
| `env.TRANSPORT_MODE` | Transport mode | `streamable-http` |
| `env.MCP_ENDPOINT` | MCP endpoint path | `/mcp` |
| `env.ENABLE_TF_OPERATIONS` | Enable Terraform operations | `false` |

### Environment Variables

#### Terraform Enterprise Settings
- `TFE_ADDRESS`: URL of your Terraform Enterprise or Cloud instance
- `TFE_SKIP_TLS_VERIFY`: Skip TLS verification (use with caution)

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

#### Feature Flags
- `ENABLE_TF_OPERATIONS`: Enable Terraform operations (default: `false`)

### TLS Configuration

#### Using Cert-Manager

`certificate.enabled` works independently of whether you use Ingress or HTTPRoute:

```yaml
certificate:
  enabled: true
  name: terraform-mcp-tls
  commonName: terraform-mcp.example.com
  issuer:
    name: letsencrypt-production
    kind: ClusterIssuer

ingress:
  tls:
    enabled: true
    secretName: terraform-mcp-tls
```

#### Mounting TLS into the Pod

Enable when the application itself needs to serve or verify TLS (sets `MCP_TLS_CERT_FILE` and `MCP_TLS_KEY_FILE` automatically):

```yaml
tls:
  mount: true
  secretName: terraform-mcp-tls
```

## Examples

### Minimal Configuration (No Ingress)

```yaml
tfeSecret:
  name: tfe-token-secret

env:
  TFE_ADDRESS: "https://app.terraform.io"
```

### With Ingress Enabled

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  host: terraform-mcp.example.com

tfeSecret:
  name: tfe-token-secret
```

### With Gateway API HTTPRoute

```yaml
ingress:
  enabled: false

httproute:
  enabled: true
  hostnames:
    - terraform-mcp.example.com
  parentRefs:
    - name: my-gateway
      namespace: gateway-system

tfeSecret:
  name: tfe-token-secret
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

tfeSecret:
  name: tfe-token-secret

ingress:
  enabled: true
  ingressClassName: nginx
  host: terraform-mcp.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
  tls:
    enabled: true
    secretName: terraform-mcp-tls

certificate:
  enabled: true
  name: terraform-mcp-tls
  commonName: terraform-mcp.example.com
  issuer:
    name: letsencrypt-production
    kind: ClusterIssuer

env:
  TFE_ADDRESS: "https://terraform.example.com"
  MCP_ALLOWED_ORIGINS: "https://app.example.com"
  MCP_RATE_LIMIT_GLOBAL: "20:40"
  MCP_RATE_LIMIT_SESSION: "10:20"
  ENABLE_TF_OPERATIONS: "true"
```

### Development Configuration

```yaml
replicaCount: 1

tfeSecret:
  create: true
  token: "dev-token-here"

ingress:
  enabled: false

env:
  TFE_SKIP_TLS_VERIFY: "true"
  MCP_CORS_MODE: "permissive"
```

## Testing

Run the built-in connectivity test after installation:

```bash
helm test terraform-mcp -n mcp-servers
```

The test pod performs a `wget --spider` check against the MCP endpoint on the chart's service.

## Upgrading

```bash
helm repo update
helm upgrade terraform-mcp hashicorp-mcp/terraform-mcp -f values.yaml -n mcp-servers
```

## Uninstalling

```bash
helm uninstall terraform-mcp -n mcp-servers
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

- **Internal**: `http://<release-name>-terraform-mcp-svc.<namespace>.svc.cluster.local/mcp`
- **External** (if ingress enabled): `https://<ingress.host>/mcp`

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=terraform-mcp -n mcp-servers
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=terraform-mcp -n mcp-servers
```

### Check Service

Service names follow the pattern `<release-name>-terraform-mcp-svc`:

```bash
kubectl get svc -l app.kubernetes.io/name=terraform-mcp -n mcp-servers
```

### Test Health Endpoint

```bash
# Replace <release-name> with your Helm release name
kubectl port-forward -n mcp-servers svc/<release-name>-terraform-mcp-svc 8080:80
curl http://localhost:8080/health
curl http://localhost:8080/mcp
```

## Support

For issues and questions:
- [Official Terraform MCP Server Documentation](https://developer.hashicorp.com/terraform/mcp-server)
- [Terraform MCP Server GitHub](https://github.com/hashicorp/terraform-mcp-server)
- Create an issue in the repository

## License

See [LICENSE](../../LICENSE) file in the repository root.

# Terraform MCP Helm Chart

This Helm chart deploys the Terraform Model Context Protocol (MCP) Server on Kubernetes.

> **Note:** This Helm chart is provided "as-is" and is not officially maintained by HashiCorp.

## Overview

The Terraform MCP Server provides an MCP interface for interacting with Terraform Enterprise/Cloud, enabling AI assistants and other tools to manage Terraform workspaces, runs, and configurations.

📖 **[Official Terraform MCP Server Documentation](https://developer.hashicorp.com/terraform/mcp-server)**

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- (Optional) A Terraform Enterprise or Terraform Cloud API token - required only if you want the MCP server to perform actions in Terraform Enterprise/Cloud

## Installation

### Basic Installation

```bash
helm install terraform-mcp ./terraform-mcp
```

### Installation with Custom Values

```bash
helm install terraform-mcp ./terraform-mcp -f custom-values.yaml
```

### Installation from Repository

If you're using a Helm repository:

```bash
helm repo add hashicorp-mcp <repository-url>
helm repo update
helm install terraform-mcp hashicorp-mcp/terraform-mcp
```

## Configuration

### Optional: Terraform Enterprise/Cloud API Token

The MCP server can run without a Terraform Enterprise/Cloud API token, but you'll need to configure one if you want it to perform actions in Terraform Enterprise or Cloud:

#### Option 1: Create Secret via Values (Not Recommended for Production)

```yaml
tfeSecret:
  create: true
  token: "your-tfe-token-here"
```

#### Option 2: Use Existing Secret (Recommended)

Create a Kubernetes secret manually:

```bash
kubectl create secret generic tfe-token-secret \
  --from-literal=TFE_TOKEN=your-tfe-token-here
```

Then reference it in your values:

```yaml
tfeSecret:
  create: false
  name: tfe-token-secret
```

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `3` |
| `image.repository` | Container image repository | `hashicorp/terraform-mcp-server` |
| `image.tag` | Container image tag | `0.3.0` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.host` | Ingress hostname | `terraform-mcp.lab.definit.co.uk` |
| `ingress.annotations` | Custom annotations for ingress | `{}` |
| `ingress.tls.enabled` | Enable TLS on ingress | `true` |
| `env.TFE_ADDRESS` | Terraform Enterprise/Cloud URL | `https://app.terraform.io` |
| `env.TRANSPORT_MODE` | Transport mode | `streamable-http` |
| `env.MCP_ENDPOINT` | MCP endpoint path | `/mcp` |

### Environment Variables

The chart supports extensive environment variable configuration:

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
- `ENABLE_TF_OPERATIONS`: Enable Terraform operations

### TLS Configuration

#### Using Cert-Manager

Enable automatic certificate generation:

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
tfeSecret:
  create: false
```

### With Ingress Enabled

```yaml
ingress:
  enabled: true
  host: terraform-mcp.example.com

tfeSecret:
  create: false
```

### Basic Configuration (With TFE Token)

```yaml
ingress:
  enabled: true
  host: terraform-mcp.example.com

tfeSecret:
  create: false
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

tfeSecret:
  create: false
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

## Upgrading

```bash
helm upgrade terraform-mcp ./terraform-mcp -f values.yaml
```

## Uninstalling

```bash
helm uninstall terraform-mcp
```

## Health Checks

The chart includes liveness and readiness probes:

- **Liveness Probe**: Checks `/health` endpoint every 10 seconds
- **Readiness Probe**: Checks `/health` endpoint every 10 seconds

## Accessing the Service

After installation, the MCP endpoint will be available at:

- **Internal**: `http://terraform-mcp.<namespace>.svc.cluster.local/mcp`
- **External** (if ingress enabled): `https://<ingress.host>/mcp`

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=terraform-mcp
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=terraform-mcp
```

### Check Service

```bash
kubectl get svc terraform-mcp
```

### Test Health Endpoint

```bash
kubectl port-forward svc/terraform-mcp 8080:80
curl http://localhost:8080/health
```

## Support

For issues and questions:
- [Official Terraform MCP Server Documentation](https://developer.hashicorp.com/terraform/mcp-server)
- [Terraform MCP Server GitHub](https://github.com/hashicorp/terraform-mcp-server)
- Create an issue in the repository

## License

See [LICENSE](../../LICENSE) file in the repository root.

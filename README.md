# hashicorp-mcp-servers-helm
Helm Chart to deploy HashiCorp's MCP servers

> **Note:** These Helm charts are provided "as-is" and are not officially maintained by HashiCorp.

## Overview

This repository contains Helm charts for deploying HashiCorp Model Context Protocol (MCP) servers on Kubernetes. MCP servers provide an interface for AI assistants and other tools to interact with HashiCorp products.

## Available Charts

### hashicorp-mcp (Parent Chart)

A unified parent chart that deploys multiple HashiCorp MCP servers with a single ingress configuration for centralized routing.

**Features:**
- Single domain with path-based routing (e.g., `mcp.example.com/terraform`, `mcp.example.com/vault`)
- Enable/disable individual MCP servers as needed
- Centralized TLS and ingress configuration
- Easy management of multiple MCP servers

**Use this chart when:**
- You want to deploy multiple MCP servers under a unified domain
- You prefer centralized ingress and TLS management
- You want path-based routing for different MCP services

📖 [Full Documentation](./charts/hashicorp-mcp/README.md)

### terraform-mcp (Standalone Chart)

Deploys the Terraform MCP Server for interacting with Terraform Enterprise/Cloud.

**Features:**
- Manage Terraform workspaces, runs, and configurations through MCP
- Optional Terraform Enterprise/Cloud integration
- Standalone deployment with optional ingress
- Can be used independently or as part of the parent chart

**Use this chart when:**
- You only need Terraform MCP functionality
- You want independent deployment and management
- You have existing ingress infrastructure

📖 [Full Documentation](./charts/terraform-mcp/README.md)

### vault-mcp (Standalone Chart)

Deploys the Vault MCP Server for interacting with HashiCorp Vault.

**Features:**
- Manage secrets, authentication, and Vault operations through MCP
- Optional Vault token integration
- Standalone deployment with optional ingress
- Can be used independently or as part of the parent chart

**Use this chart when:**
- You only need Vault MCP functionality
- You want independent deployment and management
- You have existing ingress infrastructure

📖 [Full Documentation](./charts/vault-mcp/README.md)

## Quick Start

### Deploy All MCP Servers (Unified Ingress)

```bash
cd charts/hashicorp-mcp
helm dependency update
helm install hashicorp-mcp . -n mcp-servers --create-namespace
```

Access at:
- `https://mcp.example.com/terraform/mcp`
- `https://mcp.example.com/vault/mcp`

### Deploy Individual MCP Server

```bash
# Terraform MCP only
helm install terraform-mcp ./charts/terraform-mcp -n mcp-servers --create-namespace

# Vault MCP only
helm install vault-mcp ./charts/vault-mcp -n mcp-servers --create-namespace
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    hashicorp-mcp (Parent)                   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │          Unified Ingress Controller                │   │
│  │     https://mcp.example.com                        │   │
│  └────────────────────────────────────────────────────┘   │
│                    │                    │                  │
│       /terraform   │                    │  /vault          │
│                    ▼                    ▼                  │
│  ┌──────────────────────┐  ┌──────────────────────┐      │
│  │   terraform-mcp      │  │     vault-mcp        │      │
│  │   (subchart)         │  │     (subchart)       │      │
│  └──────────────────────┘  └──────────────────────┘      │
└─────────────────────────────────────────────────────────────┘

           OR deploy independently:

┌──────────────────────┐        ┌──────────────────────┐
│   terraform-mcp      │        │     vault-mcp        │
│   (standalone)       │        │   (standalone)       │
│   Own ingress/domain │        │   Own ingress/domain │
└──────────────────────┘        └──────────────────────┘
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- (Optional) cert-manager for automatic TLS certificate management
- (Optional) Terraform Enterprise/Cloud account and token (for Terraform MCP)
- (Optional) HashiCorp Vault instance and token (for Vault MCP)

## Configuration

Each chart can be configured independently. See the individual chart documentation for detailed configuration options.

### Common Configuration Patterns

**Disable ingress on subcharts (when using parent chart):**
```yaml
terraform-mcp:
  ingress:
    enabled: false
```

**Enable ingress on standalone charts:**
```yaml
ingress:
  enabled: true
  host: terraform-mcp.example.com
```

**Configure secrets:**
```bash
# Terraform token
kubectl create secret generic tfe-token-secret \
  --from-literal=TFE_TOKEN=your-token

# Vault token
kubectl create secret generic vault-token-secret \
  --from-literal=VAULT_TOKEN=your-token
```

## Repository Structure

```
.
├── charts/
│   ├── hashicorp-mcp/      # Parent chart with unified ingress
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/
│   │   └── README.md
│   ├── terraform-mcp/       # Terraform MCP standalone chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/
│   │   └── README.md
│   └── vault-mcp/           # Vault MCP standalone chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── README.md
├── LICENSE
└── README.md
```

## Support

For issues and questions:
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Vault MCP Server](https://github.com/hashicorp/vault-mcp-server)
- Create an issue in this repository

## License

See [LICENSE](./LICENSE) file.

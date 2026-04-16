# AI Gateway Lab

A complete AI Gateway lab using Kubernetes, Gateway API, kgateway, agentgateway, and a mock LLM (httpbun).

## What's Inside

- **manifests/** - Kubernetes YAML files for Gateway, HTTPRoute, AgentgatewayBackend, and httpbun
- **rust/** - Rust dynamic module source code for Envoy transformations
- **Dockerfile** - Multi-stage Docker build for custom Envoy image

## Quick Start

1. Install kgateway and agentgateway
2. Apply the manifests:
   \\\ash
   kubectl apply -f manifests/httpbun.yaml
   kubectl apply -f manifests/httpbun-backend.yaml
   kubectl apply -f manifests/httpbun-route.yaml
   \\\
3. Port-forward and test:
   \\\ash
   kubectl port-forward -n agentgateway-system svc/agentgateway-proxy 8082:80
   curl -X POST http://localhost:8082/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gpt-4","messages":[{"role":"user","content":"Hello"}]}'
   \\\

## Blog Post

[Link to your blog post]

## Friction Log

See [docs/friction-log.md](docs/friction-log.md) for troubleshooting notes.

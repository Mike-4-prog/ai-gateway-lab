# AI Gateway Lab

A complete AI Gateway lab using Kubernetes, Gateway API, kgateway, agentgateway, and a mock LLM (httpbun).

## What's Inside

- **manifests/** - Kubernetes YAML files for Gateway, HTTPRoute, AgentgatewayBackend, and httpbun
- **rust/** - Rust dynamic module source code for Envoy transformations
- **Dockerfile** - Multi-stage Docker build for custom Envoy image

## Project Structure

```text
ai-gateway-lab/
├── .gitignore
├── README.md
├── Dockerfile
├── manifests/
│ ├── agent-gateway.yaml
│ ├── envoy-example.yaml
│ ├── gateway.yaml
│ ├── httpbun.yaml
│ ├── httpbun-backend.yaml
│ └── httpbun-route.yaml
└── rust/
├── rustformations/
│ ├── Cargo.toml
│ └── src/
│ ├── http_simple_mutations.rs
│ └── lib.rs
└── transformations/
├── Cargo.toml
└── src/
├── jinja.rs
└── lib.rs
```

## Quick Start

1. Install kgateway and agentgateway

2. Apply the manifests:

```bash
kubectl apply -f manifests/httpbun.yaml
kubectl apply -f manifests/httpbun-backend.yaml
kubectl apply -f manifests/httpbun-route.yaml
```
3. Port-forward and test:
   
```bash
kubectl port-forward -n agentgateway-system svc/agentgateway-proxy 8082:80
curl -X POST http://localhost:8082/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gpt-4","messages":[{"role":"user","content":"Hello"}]}'
```

# booking-service-eks

A customer appointment booking microservice, built step-by-step as a learning project
for production-grade Kubernetes/SRE/DevOps practices on AWS EKS.

## Status

🚧 Actively in development, built incrementally one piece at a time (app code → Docker →
Helm → CI → GitOps → monitoring). Not yet production-deployed.

## Goal

Learn, hands-on, how a real production service gets built and operated on Kubernetes —
not just the application code, but the full delivery and operability story around it:
containerization, packaging, CI/CD, GitOps, and observability.

## Stack

- **App:** Python (FastAPI)
- **Container:** Docker
- **Orchestration:** Kubernetes (AWS EKS)
- **Packaging:** Helm
- **CI:** GitHub Actions
- **CD:** ArgoCD (GitOps)
- **Observability:** Prometheus + Grafana
- **Infra (where applicable):** Terraform

## Structure

```
.
├── app/            # FastAPI application source
├── alembic/         # DB schema migrations (alembic.ini lives at repo root)
├── terraform/       # RDS + supporting networking (subnet group, SG) for the sandbox DB
├── k8s/             # Plain K8s manifests not yet folded into the Helm chart
├── charts/          # Helm chart(s)
├── .github/         # GitHub Actions workflows
└── argocd/          # ArgoCD Application manifests
```

(Structure grows incrementally as the project develops — not everything above exists yet.)

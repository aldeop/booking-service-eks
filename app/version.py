"""Bumped by hand on real changes -- imported wherever the running version
needs surfacing (currently /healthz and the FastAPI app's own OpenAPI
metadata), so a full CI -> GHCR -> ArgoCD rollout can be visibly confirmed
end-to-end, not just inferred from pod names/ages changing."""

APP_VERSION = "0.2.0"

# ---- Builder stage ---------------------------------------------------------
# Installs the production dependencies into a self-contained venv. Keeping
# this in its own stage means pip's cache, wheel metadata, and (if a future
# dependency ever needs compiling) build tooling never end up in the image
# we actually ship — only /opt/venv gets copied into the runtime stage below.
FROM python:3.12-slim AS builder

WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy only the dependency manifest first so this layer is cache-hit as long
# as requirements.txt doesn't change, even if application code does.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- Runtime stage ----------------------------------------------------------
FROM python:3.12-slim AS runtime

# Explicit numeric UID/GID (not a named system account) so this lines up
# cleanly with the pod-level runAsNonRoot/runAsUser settings we'll set in the
# Helm chart later — Kubernetes checks the UID, not the username.
RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid appuser --no-create-home --shell /usr/sbin/nologin appuser

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
# Only the application package is copied in — no tests/, scripts/, .env*,
# or dev requirements. Smaller image, smaller attack surface, and it forces
# a hard line between "runs in the container" and "local dev tooling".
COPY app ./app

# The migration Job runs `alembic upgrade head` using this same image (just
# a different command than the default CMD below), so the migration scripts
# need to travel with the app rather than living in a separate image.
COPY alembic ./alembic
COPY alembic.ini .

USER appuser

EXPOSE 8000

# Belt-and-braces for standalone `docker run`. Inside the cluster the
# readiness/liveness probes (app/routers/health.py, wired up in the Helm
# chart) are what Kubernetes actually acts on — this HEALTHCHECK is mostly
# useful for local testing and non-k8s docker hosts.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2)" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

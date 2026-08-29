from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from app.routers import appointments, health
from app.version import APP_VERSION

app = FastAPI(title="booking-service", version=APP_VERSION)

app.include_router(health.router)
app.include_router(appointments.router)

# Exposes /metrics with request count/latency histograms out of the box — matches the
# ServiceMonitor scrape pattern from our reference doc and the kube-prometheus-stack
# we've already deployed in the sandbox (Lesson 5/10).
Instrumentator().instrument(app).expose(app)

# Deliberately no database schema setup here. Touching the DB at app-startup makes the
# app hard to test (it did — see scripts/create_tables.py's docstring) and isn't a real
# migration strategy anyway. Schema changes are a deploy-time concern (Alembic, or a
# migration Job per the reference doc's Flyway pattern), not an app-boot side effect.

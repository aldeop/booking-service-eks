from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db

router = APIRouter()


@router.get("/healthz")
def healthz():
    """
    Liveness: is this process alive and able to respond at all? Deliberately checks
    nothing external — a dependency outage should never cause Kubernetes to kill and
    restart this container (that's what readiness is for).
    """
    return {"status": "ok"}


@router.get("/readyz")
def readyz(db: Session = Depends(get_db)):
    """
    Readiness: can this instance actually serve traffic right now? A failing DB
    connection here means Kubernetes stops routing traffic to this pod without
    restarting it — the pod comes back into rotation automatically once the DB is
    reachable again.
    """
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"database not reachable: {exc}",
        )
    return {"status": "ready"}

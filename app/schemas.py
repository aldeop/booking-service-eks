from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class AppointmentCreate(BaseModel):
    customer_name: str
    provider_name: str
    scheduled_at: datetime
    notes: Optional[str] = None


class AppointmentOut(AppointmentCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int

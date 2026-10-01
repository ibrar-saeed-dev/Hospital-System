from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, timezone
from enum import Enum
from models.hospital import GeoJSONPoint

class RequestStatus(str, Enum):
    REQUEST_SENT = "request_sent"
    HOSPITAL_REVIEWING = "hospital_reviewing"
    ACCEPTED = "accepted"
    PATIENT_TRANSFERRED = "patient_transferred"
    ADMITTED = "admitted"
    REJECTED = "rejected"
    CANCELLED = "cancelled"
    EXPIRED = "expired"
    NO_CAPACITY = "no_capacity"

class RequestModel(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    patient_reference: str
    requester_id: str
    required_resources: List[str]
    urgency: str  # e.g., low, medium, high, critical
    location: GeoJSONPoint
    selected_hospital_id: Optional[str] = None
    status: RequestStatus = RequestStatus.REQUEST_SENT
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    accepted_at: Optional[datetime] = None
    reservation_expires_at: Optional[datetime] = None

    class Config:
        populate_by_name = True
        use_enum_values = True

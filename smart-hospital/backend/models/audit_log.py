from pydantic import BaseModel, Field
from typing import Any, Dict, Optional
from datetime import datetime, timezone

class AuditLogModel(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    hospital_id: str
    resource_type: str
    old_values: Dict[str, Any]
    new_values: Dict[str, Any]
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Config:
        populate_by_name = True

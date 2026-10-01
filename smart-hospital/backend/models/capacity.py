from pydantic import BaseModel, Field, model_validator
from typing import Optional
from datetime import datetime, timezone
from enum import Enum

class ResourceType(str, Enum):
    GENERAL_BED = "general_bed"
    EMERGENCY_BED = "emergency_bed"
    ICU_BED = "icu_bed"
    NICU_BED = "nicu_bed"
    VENTILATOR = "ventilator"
    OPERATION_THEATRE = "operation_theatre"
    ISOLATION_BED = "isolation_bed"
    DIALYSIS = "dialysis"
    TRAUMA = "trauma"
    AMBULANCE = "ambulance"

class CapacityModel(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    hospital_id: str
    resource_type: ResourceType
    total: int = 0
    occupied: int = 0
    reserved: int = 0
    temporarily_unavailable: int = 0
    available: int = 0
    last_updated: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    @model_validator(mode="before")
    @classmethod
    def calculate_available(cls, values):
        if isinstance(values, dict):
            total = values.get("total", 0)
            occupied = values.get("occupied", 0)
            reserved = values.get("reserved", 0)
            temp_unavail = values.get("temporarily_unavailable", 0)
            values["available"] = max(0, total - occupied - reserved - temp_unavail)
        return values

    class Config:
        populate_by_name = True
        use_enum_values = True

from pydantic import BaseModel, Field
from typing import List, Literal, Optional

class GeoJSONPoint(BaseModel):
    type: Literal["Point"] = "Point"
    coordinates: List[float]  # [longitude, latitude]

class HospitalModel(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    name: str
    address: str
    contact: str
    location: GeoJSONPoint
    verification_status: str = "verified"  # verified | pending | rejected
    emergency_available: bool = True
    account_status: str = "active"  # active | inactive

    class Config:
        populate_by_name = True

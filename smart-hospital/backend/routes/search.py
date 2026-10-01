from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from typing import List, Dict, Any
from services.auth import get_current_user
from services.matcher import search_hospitals

router = APIRouter(tags=["Hospital Search"])

class SearchRequest(BaseModel):
    required_resources: List[str] = Field(..., example=["icu_bed", "ventilator"])
    latitude: float = Field(..., example=17.44)
    longitude: float = Field(..., example=78.38)
    max_distance_km: float = Field(default=30.0, ge=0.1, example=30.0)

class CapacityDetail(BaseModel):
    total: int
    occupied: int
    reserved: int
    temporarily_unavailable: int
    available: int

class HospitalMatchItem(BaseModel):
    hospital_id: str
    name: str
    address: str
    contact: str
    location: Dict[str, Any]
    distance_km: float
    estimated_travel_minutes: float
    match_percent: float
    capacities: Dict[str, CapacityDetail]
    last_updated: Any
    stale: bool

class HospitalExcludedItem(BaseModel):
    hospital_id: str
    name: str
    address: str
    contact: str
    location: Dict[str, Any]
    distance_km: float
    estimated_travel_minutes: float
    exclusion_reason: str
    capacities: Dict[str, CapacityDetail]
    last_updated: Any
    stale: bool

class SearchResponse(BaseModel):
    suitable: List[HospitalMatchItem]
    excluded: List[HospitalExcludedItem]

@router.post("/search", response_model=SearchResponse)
async def search(
    request: SearchRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    return await search_hospitals(
        latitude=request.latitude,
        longitude=request.longitude,
        required_resources=request.required_resources,
        max_distance_km=request.max_distance_km
    )

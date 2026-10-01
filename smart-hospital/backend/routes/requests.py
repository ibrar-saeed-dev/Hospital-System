from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from services.auth import get_current_user, require_role
from services.referral import (
    create_referral_request,
    get_user_requests,
    get_hospital_requests,
    accept_request,
    reject_request,
    cancel_request,
    update_request_status,
)

router = APIRouter(prefix="/requests", tags=["Referral Requests"])

class CreateReferralRequest(BaseModel):
    patient_reference: str = Field(..., example="PAT-98231")
    required_resources: List[str] = Field(..., example=["icu_bed", "ventilator"])
    urgency: str = Field(..., example="critical")  # low | medium | high | critical
    latitude: float = Field(..., example=17.44)
    longitude: float = Field(..., example=78.38)
    selected_hospital_id: str = Field(..., example="6abdfa6abdd18fdca3435a11")

class StatusUpdateRequest(BaseModel):
    status: str = Field(..., example="patient_transferred")

@router.post("", response_model=Dict[str, Any])
async def create_request(
    body: CreateReferralRequest,
    current_user: Dict[str, Any] = Depends(require_role("patient", "coordinator"))
):
    return await create_referral_request(
        requester_id=str(current_user["_id"]),
        patient_reference=body.patient_reference,
        required_resources=body.required_resources,
        urgency=body.urgency,
        latitude=body.latitude,
        longitude=body.longitude,
        selected_hospital_id=body.selected_hospital_id
    )

@router.get("/mine", response_model=List[Dict[str, Any]])
async def get_my_requests(
    current_user: Dict[str, Any] = Depends(require_role("patient", "coordinator"))
):
    return await get_user_requests(str(current_user["_id"]))

@router.get("/hospital", response_model=List[Dict[str, Any]])
async def get_hospital_received_requests(
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    hospital_id = current_user.get("hospital_id")
    if not hospital_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current staff user is not linked to any hospital."
        )
    return await get_hospital_requests(hospital_id)

@router.patch("/{id}/accept", response_model=Dict[str, Any])
async def accept_hospital_request(
    id: str,
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    return await accept_request(id, current_user)

@router.patch("/{id}/reject", response_model=Dict[str, Any])
async def reject_hospital_request(
    id: str,
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    return await reject_request(id, current_user)

@router.patch("/{id}/cancel", response_model=Dict[str, Any])
async def cancel_user_request(
    id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    return await cancel_request(id, str(current_user["_id"]))

@router.patch("/{id}/status", response_model=Dict[str, Any])
async def update_status(
    id: str,
    body: StatusUpdateRequest,
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    return await update_request_status(id, body.status, current_user)

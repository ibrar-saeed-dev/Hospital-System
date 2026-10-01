from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Dict, Any
from services.auth import require_role
from services.analytics import list_all_hospitals_admin, verify_hospital_admin

router = APIRouter(prefix="/admin", tags=["Admin Management"])

class VerifyHospitalRequest(BaseModel):
    verification_status: str = Field(..., example="verified")  # verified | rejected | pending

@router.get("/hospitals", response_model=List[Dict[str, Any]])
async def get_all_hospitals_admin(
    current_user: Dict[str, Any] = Depends(require_role("admin"))
):
    return await list_all_hospitals_admin()

@router.patch("/hospitals/{id}/verify", response_model=Dict[str, Any])
async def verify_hospital(
    id: str,
    body: VerifyHospitalRequest,
    current_user: Dict[str, Any] = Depends(require_role("admin"))
):
    return await verify_hospital_admin(id, body.verification_status)

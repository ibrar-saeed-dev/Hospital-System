from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
from services.auth import require_role
from services.analytics import get_hospital_analytics, get_system_analytics

router = APIRouter(prefix="/analytics", tags=["Analytics"])

@router.get("/hospital", response_model=Dict[str, Any])
async def get_hospital_metrics(
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    hospital_id = current_user.get("hospital_id")
    if not hospital_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current staff user is not linked to any hospital."
        )
    return await get_hospital_analytics(hospital_id)

@router.get("/system", response_model=Dict[str, Any])
async def get_system_metrics(
    current_user: Dict[str, Any] = Depends(require_role("admin"))
):
    return await get_system_analytics()

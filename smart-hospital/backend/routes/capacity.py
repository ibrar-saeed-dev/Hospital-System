from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from services.auth import get_current_user, require_role
from services.capacity import get_hospital_capacities, update_resource_capacity

router = APIRouter(tags=["Capacity Management"])

class CapacityUpdateRequest(BaseModel):
    total: int = Field(ge=0, description="Total capacity count")
    occupied: int = Field(ge=0, description="Occupied count")
    temporarily_unavailable: int = Field(ge=0, description="Temporarily unavailable count")

@router.get("/capacity/my-hospital", response_model=List[Dict[str, Any]])
async def get_my_hospital_capacity(current_user: Dict[str, Any] = Depends(require_role("staff"))):
    hospital_id = current_user.get("hospital_id")
    if not hospital_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current staff user is not linked to any hospital."
        )
    return await get_hospital_capacities(hospital_id)

@router.put("/capacity/{resource_type}", response_model=Dict[str, Any])
async def update_my_capacity(
    resource_type: str,
    body: CapacityUpdateRequest,
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    hospital_id = current_user.get("hospital_id")
    if not hospital_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current staff user is not linked to any hospital."
        )
    return await update_resource_capacity(
        hospital_id=hospital_id,
        user_id=str(current_user["_id"]),
        resource_type=resource_type,
        total=body.total,
        occupied=body.occupied,
        temporarily_unavailable=body.temporarily_unavailable
    )

@router.put("/hospitals/{hospital_id}/capacity/{resource_type}", response_model=Dict[str, Any])
async def update_hospital_capacity(
    hospital_id: str,
    resource_type: str,
    body: CapacityUpdateRequest,
    current_user: Dict[str, Any] = Depends(require_role("staff"))
):
    user_hospital_id = current_user.get("hospital_id")
    if user_hospital_id != hospital_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Forbidden: You are assigned to hospital '{user_hospital_id}' and cannot modify capacity for hospital '{hospital_id}'."
        )
    
    return await update_resource_capacity(
        hospital_id=hospital_id,
        user_id=str(current_user["_id"]),
        resource_type=resource_type,
        total=body.total,
        occupied=body.occupied,
        temporarily_unavailable=body.temporarily_unavailable
    )

@router.get("/hospitals/{id}/capacity", response_model=List[Dict[str, Any]])
async def get_hospital_capacity_public(
    id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    return await get_hospital_capacities(id)

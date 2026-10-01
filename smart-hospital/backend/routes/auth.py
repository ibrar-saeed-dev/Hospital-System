from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from typing import Optional, Dict, Any
from database import get_database
from services.auth import verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    email: str
    password: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    name: str
    hospital_id: Optional[str] = None

class UserProfileResponse(BaseModel):
    id: str
    email: str
    name: str
    role: str
    hospital_id: Optional[str] = None

@router.post("/login", response_model=LoginResponse)
async def login(credentials: LoginRequest):
    db = get_database()
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection unavailable"
        )

    user = await db.users.find_one({"email": credentials.email})
    if not user or not verify_password(credentials.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    user_id = str(user["_id"])
    role = user["role"]
    hospital_id = user.get("hospital_id")

    token_payload = {
        "user_id": user_id,
        "role": role,
        "hospital_id": hospital_id,
        "sub": user["email"]
    }

    access_token = create_access_token(token_payload)

    return LoginResponse(
        access_token=access_token,
        role=role,
        name=user["name"],
        hospital_id=hospital_id
    )

@router.get("/me", response_model=UserProfileResponse)
async def get_me(current_user: Dict[str, Any] = Depends(get_current_user)):
    return UserProfileResponse(
        id=str(current_user["_id"]),
        email=current_user["email"],
        name=current_user["name"],
        role=current_user["role"],
        hospital_id=current_user.get("hospital_id")
    )

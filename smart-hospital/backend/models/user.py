from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from enum import Enum

class UserRole(str, Enum):
    PATIENT = "patient"
    COORDINATOR = "coordinator"
    STAFF = "staff"
    ADMIN = "admin"

class UserModel(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    email: str
    password_hash: str
    role: UserRole
    hospital_id: Optional[str] = None  # Only for staff
    name: str

    class Config:
        populate_by_name = True
        use_enum_values = True

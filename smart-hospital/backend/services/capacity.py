from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import HTTPException, status
from bson import ObjectId
from database import get_database

def format_capacity_doc(doc: Dict[str, Any]) -> Dict[str, Any]:
    doc["id"] = str(doc.get("_id", doc.get("id", "")))
    if "_id" in doc:
        del doc["_id"]
    
    last_updated = doc.get("last_updated")
    if isinstance(last_updated, datetime):
        if last_updated.tzinfo is None:
            last_updated = last_updated.replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        diff_minutes = (now - last_updated).total_seconds() / 60.0
        doc["minutes_since_update"] = round(diff_minutes, 2)
        doc["stale"] = diff_minutes > 30.0
    else:
        doc["minutes_since_update"] = 0.0
        doc["stale"] = False

    return doc

async def get_hospital_capacities(hospital_id: str) -> List[Dict[str, Any]]:
    db = get_database()
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection unavailable"
        )

    cursor = db.capacities.find({"hospital_id": hospital_id})
    capacities = await cursor.to_list(length=100)
    return [format_capacity_doc(c) for c in capacities]

async def update_resource_capacity(
    hospital_id: str,
    user_id: str,
    resource_type: str,
    total: int,
    occupied: int,
    temporarily_unavailable: int
) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection unavailable"
        )

    # 1. Validation for negative values
    if total < 0 or occupied < 0 or temporarily_unavailable < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Capacity numbers cannot be negative."
        )

    # 2. Find existing record
    existing = await db.capacities.find_one({
        "hospital_id": hospital_id,
        "resource_type": resource_type
    })

    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Capacity record for resource type '{resource_type}' not found for hospital '{hospital_id}'."
        )

    reserved = existing.get("reserved", 0)

    # 3. Validate total bounds
    if occupied + reserved + temporarily_unavailable > total:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Invalid capacity allocation: Sum of occupied ({occupied}), "
                f"reserved ({reserved}), and temporarily unavailable ({temporarily_unavailable}) "
                f"exceeds total capacity ({total})."
            )
        )

    # 4. Calculate available & timestamp
    available = total - occupied - reserved - temporarily_unavailable
    now = datetime.now(timezone.utc)

    old_values = {
        "total": existing.get("total", 0),
        "occupied": existing.get("occupied", 0),
        "reserved": reserved,
        "temporarily_unavailable": existing.get("temporarily_unavailable", 0),
        "available": existing.get("available", 0)
    }

    new_values = {
        "total": total,
        "occupied": occupied,
        "reserved": reserved,
        "temporarily_unavailable": temporarily_unavailable,
        "available": available
    }

    # 5. Update capacity document
    update_doc = {
        "total": total,
        "occupied": occupied,
        "temporarily_unavailable": temporarily_unavailable,
        "available": available,
        "last_updated": now
    }

    await db.capacities.update_one(
        {"_id": existing["_id"]},
        {"$set": update_doc}
    )

    # 6. AuditLog entry
    audit_doc = {
        "user_id": user_id,
        "hospital_id": hospital_id,
        "resource_type": resource_type,
        "old_values": old_values,
        "new_values": new_values,
        "timestamp": now
    }
    await db.audit_logs.insert_one(audit_doc)

    # Fetch updated document
    updated_doc = await db.capacities.find_one({"_id": existing["_id"]})
    return format_capacity_doc(updated_doc)

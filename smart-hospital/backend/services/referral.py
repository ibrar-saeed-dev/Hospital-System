import asyncio
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Optional
from fastapi import HTTPException, status
from bson import ObjectId
from database import get_database

def format_request_doc(doc: Dict[str, Any]) -> Dict[str, Any]:
    doc["id"] = str(doc["_id"])
    if "_id" in doc:
        del doc["_id"]

    now = datetime.now(timezone.utc)
    expires_at = doc.get("reservation_expires_at")
    req_status = doc.get("status")

    if expires_at and req_status in ["request_sent", "hospital_reviewing"]:
        if isinstance(expires_at, datetime):
            if expires_at.tzinfo is None:
                expires_at = expires_at.replace(tzinfo=timezone.utc)
            diff_sec = (expires_at - now).total_seconds()
            doc["minutes_left"] = max(0.0, round(diff_sec / 60.0, 1))
        else:
            doc["minutes_left"] = 0.0
    else:
        doc["minutes_left"] = 0.0

    loc = doc.get("location")
    if isinstance(loc, dict) and "coordinates" in loc and len(loc["coordinates"]) >= 2:
        doc["longitude"] = loc["coordinates"][0]
        doc["latitude"] = loc["coordinates"][1]

    return doc

async def create_referral_request(
    requester_id: str,
    patient_reference: str,
    required_resources: List[str],
    urgency: str,
    latitude: float,
    longitude: float,
    selected_hospital_id: str,
    reservation_minutes: int = 15
) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection unavailable"
        )

    now = datetime.now(timezone.utc)
    reserved_resources = []

    # Atomic reservation per required resource
    for res_type in required_resources:
        res = await db.capacities.find_one_and_update(
            {
                "hospital_id": selected_hospital_id,
                "resource_type": res_type,
                "available": {"$gte": 1}
            },
            {
                "$inc": {"available": -1, "reserved": 1},
                "$set": {"last_updated": now}
            }
        )

        if res is None:
            # ROLLBACK previous reservations
            for roll_res in reserved_resources:
                await db.capacities.update_one(
                    {"hospital_id": selected_hospital_id, "resource_type": roll_res},
                    {
                        "$inc": {"available": 1, "reserved": -1},
                        "$set": {"last_updated": now}
                    }
                )

            # Record failed request with status no_capacity
            no_cap_doc = {
                "patient_reference": patient_reference,
                "requester_id": requester_id,
                "required_resources": required_resources,
                "urgency": urgency,
                "location": {"type": "Point", "coordinates": [longitude, latitude]},
                "selected_hospital_id": selected_hospital_id,
                "status": "no_capacity",
                "created_at": now
            }
            await db.requests.insert_one(no_cap_doc)

            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"No capacity available for resource '{res_type}' at selected hospital."
            )
        else:
            reserved_resources.append(res_type)

    # Success: Save request with status request_sent
    expires_at = now + timedelta(minutes=reservation_minutes)
    hosp_name = None
    try:
        h = await db.hospitals.find_one({"_id": ObjectId(selected_hospital_id)})
        if h:
            hosp_name = h.get("name")
    except Exception:
        h = await db.hospitals.find_one({"_id": selected_hospital_id})
        if h:
            hosp_name = h.get("name")

    req_doc = {
        "patient_reference": patient_reference,
        "requester_id": requester_id,
        "required_resources": required_resources,
        "urgency": urgency,
        "location": {"type": "Point", "coordinates": [longitude, latitude]},
        "selected_hospital_id": selected_hospital_id,
        "hospital_name": hosp_name,
        "status": "request_sent",
        "created_at": now,
        "reservation_expires_at": expires_at
    }

    result = await db.requests.insert_one(req_doc)
    req_doc["_id"] = result.inserted_id
    return format_request_doc(req_doc)

async def get_user_requests(requester_id: str) -> List[Dict[str, Any]]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    cursor = db.requests.find({"requester_id": requester_id}).sort("created_at", -1)
    reqs = await cursor.to_list(length=100)
    for r in reqs:
        h_id = r.get("selected_hospital_id")
        if h_id:
            try:
                h = await db.hospitals.find_one({"_id": ObjectId(h_id)})
            except Exception:
                h = await db.hospitals.find_one({"_id": h_id})
            if h:
                r["hospital_name"] = h.get("name")
                r["hospital_address"] = h.get("address")
                h_loc = h.get("location")
                if isinstance(h_loc, dict) and "coordinates" in h_loc and len(h_loc["coordinates"]) >= 2:
                    r["hospital_longitude"] = h_loc["coordinates"][0]
                    r["hospital_latitude"] = h_loc["coordinates"][1]
    return [format_request_doc(r) for r in reqs]

async def get_hospital_requests(hospital_id: str) -> List[Dict[str, Any]]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    cursor = db.requests.find({"selected_hospital_id": hospital_id}).sort("created_at", -1)
    reqs = await cursor.to_list(length=100)
    for r in reqs:
        if not r.get("hospital_name"):
            try:
                h = await db.hospitals.find_one({"_id": ObjectId(hospital_id)})
            except Exception:
                h = await db.hospitals.find_one({"_id": hospital_id})
            if h:
                r["hospital_name"] = h.get("name")
    return [format_request_doc(r) for r in reqs]

async def accept_request(request_id: str, staff_user: Dict[str, Any]) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    try:
        req = await db.requests.find_one({"_id": ObjectId(request_id)})
    except Exception:
        req = await db.requests.find_one({"_id": request_id})

    if not req:
        raise HTTPException(status_code=404, detail="Request not found.")

    staff_hospital_id = staff_user.get("hospital_id")
    if req.get("selected_hospital_id") != staff_hospital_id:
        raise HTTPException(status_code=403, detail="Forbidden: You can only accept requests for your own hospital.")

    now = datetime.now(timezone.utc)
    expires_at = req.get("reservation_expires_at")
    if expires_at and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if req["status"] not in ["request_sent", "hospital_reviewing"]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot accept request with status '{req['status']}'."
        )

    if expires_at and expires_at < now:
        raise HTTPException(status_code=400, detail="Reservation for this request has expired.")

    # Move each reserved resource to occupied (reserved -1, occupied +1)
    for res_type in req.get("required_resources", []):
        old_cap = await db.capacities.find_one({
            "hospital_id": staff_hospital_id,
            "resource_type": res_type
        })
        await db.capacities.update_one(
            {"hospital_id": staff_hospital_id, "resource_type": res_type},
            {
                "$inc": {"reserved": -1, "occupied": 1},
                "$set": {"last_updated": now}
            }
        )
        new_cap = await db.capacities.find_one({
            "hospital_id": staff_hospital_id,
            "resource_type": res_type
        })

        # Write AuditLog entry
        if old_cap and new_cap:
            await db.audit_logs.insert_one({
                "user_id": str(staff_user["_id"]),
                "hospital_id": staff_hospital_id,
                "resource_type": res_type,
                "old_values": {
                    "reserved": old_cap.get("reserved", 0),
                    "occupied": old_cap.get("occupied", 0)
                },
                "new_values": {
                    "reserved": new_cap.get("reserved", 0),
                    "occupied": new_cap.get("occupied", 0)
                },
                "timestamp": now
            })

    # Update request status to accepted
    await db.requests.update_one(
        {"_id": req["_id"]},
        {"$set": {"status": "accepted", "accepted_at": now}}
    )

    updated_req = await db.requests.find_one({"_id": req["_id"]})
    return format_request_doc(updated_req)

async def reject_request(request_id: str, staff_user: Dict[str, Any]) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    try:
        req = await db.requests.find_one({"_id": ObjectId(request_id)})
    except Exception:
        req = await db.requests.find_one({"_id": request_id})

    if not req:
        raise HTTPException(status_code=404, detail="Request not found.")

    staff_hospital_id = staff_user.get("hospital_id")
    if req.get("selected_hospital_id") != staff_hospital_id:
        raise HTTPException(status_code=403, detail="Forbidden: You can only reject requests for your own hospital.")

    now = datetime.now(timezone.utc)

    # Release reservation if in active status
    if req["status"] in ["request_sent", "hospital_reviewing"]:
        for res_type in req.get("required_resources", []):
            await db.capacities.update_one(
                {"hospital_id": staff_hospital_id, "resource_type": res_type},
                {
                    "$inc": {"reserved": -1, "available": 1},
                    "$set": {"last_updated": now}
                }
            )

    await db.requests.update_one(
        {"_id": req["_id"]},
        {"$set": {"status": "rejected"}}
    )

    updated_req = await db.requests.find_one({"_id": req["_id"]})
    return format_request_doc(updated_req)

async def cancel_request(request_id: str, requester_id: str) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    try:
        req = await db.requests.find_one({"_id": ObjectId(request_id)})
    except Exception:
        req = await db.requests.find_one({"_id": request_id})

    if not req:
        raise HTTPException(status_code=404, detail="Request not found.")

    if req.get("requester_id") != requester_id:
        raise HTTPException(status_code=403, detail="Forbidden: Only the requester can cancel this request.")

    now = datetime.now(timezone.utc)
    hosp_id = req.get("selected_hospital_id")
    current_status = req.get("status")

    if current_status in ["accepted", "patient_transferred", "admitted", "rejected", "cancelled", "expired"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel request with status '{current_status}'."
        )

    if current_status in ["request_sent", "hospital_reviewing"]:
        for res_type in req.get("required_resources", []):
            await db.capacities.update_one(
                {"hospital_id": hosp_id, "resource_type": res_type},
                {
                    "$inc": {"reserved": -1, "available": 1},
                    "$set": {"last_updated": now}
                }
            )

    await db.requests.update_one(
        {"_id": req["_id"]},
        {"$set": {"status": "cancelled"}}
    )

    updated_req = await db.requests.find_one({"_id": req["_id"]})
    return format_request_doc(updated_req)

async def update_request_status(
    request_id: str,
    new_status: str,
    staff_user: Dict[str, Any]
) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    try:
        req = await db.requests.find_one({"_id": ObjectId(request_id)})
    except Exception:
        req = await db.requests.find_one({"_id": request_id})

    if not req:
        raise HTTPException(status_code=404, detail="Request not found.")

    staff_hospital_id = staff_user.get("hospital_id")
    if req.get("selected_hospital_id") != staff_hospital_id:
        raise HTTPException(status_code=403, detail="Forbidden: You can only update requests for your own hospital.")

    current_status = req.get("status")

    # Strict state machine validation
    allowed_transitions = {
        "request_sent": ["accepted", "rejected"],
        "hospital_reviewing": ["accepted", "rejected"],
        "accepted": ["patient_transferred"],
        "patient_transferred": ["admitted"],
    }

    allowed = allowed_transitions.get(current_status, [])
    if new_status not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status transition from '{current_status}' to '{new_status}'. Allowed next status: {allowed}"
        )

    # Note: If moving to 'accepted', call accept_request logic or endpoint. For 'patient_transferred' and 'admitted', update status.
    await db.requests.update_one(
        {"_id": req["_id"]},
        {"$set": {"status": new_status}}
    )

    updated_req = await db.requests.find_one({"_id": req["_id"]})
    return format_request_doc(updated_req)

async def expire_stale_reservations():
    db = get_database()
    if db is None:
        return

    now = datetime.now(timezone.utc)
    cursor = db.requests.find({
        "status": {"$in": ["request_sent", "hospital_reviewing"]},
        "reservation_expires_at": {"$lt": now}
    })

    expired_requests = await cursor.to_list(length=200)
    for req in expired_requests:
        # Atomic status update to ensure expiry and capacity release happen EXACTLY ONCE
        res = await db.requests.find_one_and_update(
            {
                "_id": req["_id"],
                "status": {"$in": ["request_sent", "hospital_reviewing"]}
            },
            {
                "$set": {"status": "expired"}
            }
        )
        if res is not None:
            hosp_id = req.get("selected_hospital_id")
            for res_type in req.get("required_resources", []):
                await db.capacities.update_one(
                    {"hospital_id": hosp_id, "resource_type": res_type},
                    {
                        "$inc": {"reserved": -1, "available": 1},
                        "$set": {"last_updated": now}
                    }
                )

async def start_expiry_background_task(interval_seconds: int = 30):
    while True:
        try:
            await expire_stale_reservations()
        except Exception as e:
            print(f"Error in background reservation expiry task: {e}")
        await asyncio.sleep(interval_seconds)

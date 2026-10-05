from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Optional
from fastapi import HTTPException, status
from bson import ObjectId
from database import get_database

async def get_hospital_analytics(hospital_id: str) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    # 1. Capacities Aggregation for Totals & Occupancy per resource
    caps_cursor = db.capacities.find({"hospital_id": hospital_id})
    capacities = await caps_cursor.to_list(length=100)

    total_cap = 0
    total_occ = 0
    total_res = 0
    total_avail = 0
    resource_occupancy = []
    icu_occ_percent = 0.0

    for c in capacities:
        tot = c.get("total", 0)
        occ = c.get("occupied", 0)
        resv = c.get("reserved", 0)
        avail = c.get("available", 0)
        r_type = c.get("resource_type", "")

        total_cap += tot
        total_occ += occ
        total_res += resv
        total_avail += avail

        occ_pct = round((occ / tot * 100.0), 1) if tot > 0 else 0.0
        resource_occupancy.append({
            "resource_type": r_type,
            "total": tot,
            "occupied": occ,
            "reserved": resv,
            "available": avail,
            "occupancy_percent": occ_pct
        })

        if r_type == "icu_bed":
            icu_occ_percent = occ_pct

    totals = {
        "total": total_cap,
        "occupied": total_occ,
        "reserved": total_res,
        "available": total_avail,
        "overall_occupancy_percent": round((total_occ / total_cap * 100.0), 1) if total_cap > 0 else 0.0
    }

    # 2. Request Counts by Status
    status_pipeline = [
        {"$match": {"selected_hospital_id": hospital_id}},
        {"$group": {"_id": "$status", "count": {"$sum": 1}}}
    ]
    status_docs = await db.requests.aggregate(status_pipeline).to_list(length=20)
    raw_status_counts = {doc["_id"]: doc["count"] for doc in status_docs}

    pending_count = raw_status_counts.get("request_sent", 0) + raw_status_counts.get("hospital_reviewing", 0)
    request_counts_by_status = {
        "accepted": raw_status_counts.get("accepted", 0),
        "rejected": raw_status_counts.get("rejected", 0),
        "expired": raw_status_counts.get("expired", 0),
        "cancelled": raw_status_counts.get("cancelled", 0),
        "pending": pending_count,
        "admitted": raw_status_counts.get("admitted", 0),
        "patient_transferred": raw_status_counts.get("patient_transferred", 0),
        "no_capacity": raw_status_counts.get("no_capacity", 0)
    }

    # 3. Average Response Time in Minutes for Accepted Requests
    resp_pipeline = [
        {
            "$match": {
                "selected_hospital_id": hospital_id,
                "status": {"$in": ["accepted", "patient_transferred", "admitted"]},
                "accepted_at": {"$ne": None}
            }
        },
        {
            "$project": {
                "resp_time_mins": {
                    "$divide": [
                        {"$subtract": ["$accepted_at", "$created_at"]},
                        60000.0
                    ]
                }
            }
        },
        {
            "$group": {
                "_id": None,
                "avg_response_time": {"$avg": "$resp_time_mins"}
            }
        }
    ]
    resp_res = await db.requests.aggregate(resp_pipeline).to_list(length=1)
    avg_resp_time = round(resp_res[0]["avg_response_time"], 2) if resp_res and resp_res[0]["avg_response_time"] is not None else 0.0

    # 4. Daily Request Counts for Last 7 Days
    now = datetime.now(timezone.utc)
    seven_days_ago = now - timedelta(days=7)

    daily_pipeline = [
        {
            "$match": {
                "selected_hospital_id": hospital_id,
                "created_at": {"$gte": seven_days_ago}
            }
        },
        {
            "$group": {
                "_id": {
                    "$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}
                },
                "count": {"$sum": 1}
            }
        },
        {"$sort": {"_id": 1}}
    ]
    daily_docs = await db.requests.aggregate(daily_pipeline).to_list(length=10)
    daily_map = {doc["_id"]: doc["count"] for doc in daily_docs}

    # Fill 7-day series
    daily_requests = []
    for i in range(6, -1, -1):
        day_str = (now - timedelta(days=i)).strftime("%Y-%m-%d")
        daily_requests.append({
            "date": day_str,
            "count": daily_map.get(day_str, 0)
        })

    return {
        "totals": totals,
        "resource_occupancy": resource_occupancy,
        "icu_occupancy_percent": icu_occ_percent,
        "request_counts_by_status": request_counts_by_status,
        "avg_response_time_minutes": avg_resp_time,
        "daily_requests": daily_requests
    }

async def get_system_analytics() -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    now = datetime.now(timezone.utc)

    # 1. Top 5 Hospitals by Overall Occupancy
    top_hosp_pipeline = [
        {
            "$group": {
                "_id": "$hospital_id",
                "total_capacity": {"$sum": "$total"},
                "total_occupied": {"$sum": "$occupied"}
            }
        },
        {
            "$project": {
                "hospital_id": "$_id",
                "total_capacity": 1,
                "total_occupied": 1,
                "occupancy_percent": {
                    "$cond": [
                        {"$gt": ["$total_capacity", 0]},
                        {"$multiply": [{"$divide": ["$total_occupied", "$total_capacity"]}, 100]},
                        0
                    ]
                }
            }
        },
        {"$sort": {"occupancy_percent": -1}},
        {"$limit": 5}
    ]
    top_docs = await db.capacities.aggregate(top_hosp_pipeline).to_list(length=5)

    top_hospitals = []
    for doc in top_docs:
        h_id = doc["hospital_id"]
        try:
            h_obj = await db.hospitals.find_one({"_id": ObjectId(h_id)})
        except Exception:
            h_obj = await db.hospitals.find_one({"_id": h_id})

        name = h_obj["name"] if h_obj else "Unknown Hospital"
        top_hospitals.append({
            "hospital_id": h_id,
            "name": name,
            "total_capacity": doc["total_capacity"],
            "total_occupied": doc["total_occupied"],
            "occupancy_percent": round(doc["occupancy_percent"], 1)
        })

    # 2. Most Requested Resource Types
    resource_pipeline = [
        {"$unwind": "$required_resources"},
        {"$group": {"_id": "$required_resources", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}
    ]
    resource_docs = await db.requests.aggregate(resource_pipeline).to_list(length=20)
    most_requested_resources = [{"resource_type": doc["_id"], "count": doc["count"]} for doc in resource_docs]

    # 3. Request Counts by Status
    status_pipeline = [
        {"$group": {"_id": "$status", "count": {"$sum": 1}}}
    ]
    status_docs = await db.requests.aggregate(status_pipeline).to_list(length=20)
    request_counts_by_status = {doc["_id"]: doc["count"] for doc in status_docs}

    # 4. Request Counts by Urgency
    urgency_pipeline = [
        {"$group": {"_id": "$urgency", "count": {"$sum": 1}}}
    ]
    urgency_docs = await db.requests.aggregate(urgency_pipeline).to_list(length=20)
    request_counts_by_urgency = {doc["_id"]: doc["count"] for doc in urgency_docs}

    # 5. Average Response Time Across All Hospitals
    resp_pipeline = [
        {
            "$match": {
                "accepted_at": {"$ne": None}
            }
        },
        {
            "$project": {
                "resp_time_mins": {
                    "$divide": [
                        {"$subtract": ["$accepted_at", "$created_at"]},
                        60000.0
                    ]
                }
            }
        },
        {
            "$group": {
                "_id": None,
                "avg_response_time": {"$avg": "$resp_time_mins"}
            }
        }
    ]
    resp_res = await db.requests.aggregate(resp_pipeline).to_list(length=1)
    avg_resp_time = round(resp_res[0]["avg_response_time"], 2) if resp_res and resp_res[0]["avg_response_time"] is not None else 0.0

    # 6. Requests per Day for Last 7 Days Across System
    seven_days_ago = now - timedelta(days=7)
    daily_pipeline = [
        {"$match": {"created_at": {"$gte": seven_days_ago}}},
        {
            "$group": {
                "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
                "count": {"$sum": 1}
            }
        },
        {"$sort": {"_id": 1}}
    ]
    daily_docs = await db.requests.aggregate(daily_pipeline).to_list(length=10)
    daily_map = {doc["_id"]: doc["count"] for doc in daily_docs}

    daily_requests = []
    for i in range(6, -1, -1):
        day_str = (now - timedelta(days=i)).strftime("%Y-%m-%d")
        daily_requests.append({
            "date": day_str,
            "count": daily_map.get(day_str, 0)
        })

    # 7. Hospitals with Stale Data (not updated in > 30 minutes)
    stale_pipeline = [
        {
            "$group": {
                "_id": "$hospital_id",
                "latest_update": {"$max": "$last_updated"}
            }
        }
    ]
    stale_docs = await db.capacities.aggregate(stale_pipeline).to_list(length=100)

    stale_hospitals = []
    for doc in stale_docs:
        h_id = doc["_id"]
        lu = doc["latest_update"]
        is_stale = True
        diff_mins = None

        if isinstance(lu, datetime):
            if lu.tzinfo is None:
                lu = lu.replace(tzinfo=timezone.utc)
            diff_mins = round((now - lu).total_seconds() / 60.0, 1)
            is_stale = diff_mins > 30.0

        if is_stale:
            try:
                h_obj = await db.hospitals.find_one({"_id": ObjectId(h_id)})
            except Exception:
                h_obj = await db.hospitals.find_one({"_id": h_id})

            stale_hospitals.append({
                "hospital_id": h_id,
                "name": h_obj["name"] if h_obj else "Unknown Hospital",
                "last_updated": lu.isoformat() if isinstance(lu, datetime) else None,
                "minutes_since_update": diff_mins
            })

    return {
        "top_hospitals_by_occupancy": top_hospitals,
        "most_requested_resources": most_requested_resources,
        "request_counts_by_status": request_counts_by_status,
        "request_counts_by_urgency": request_counts_by_urgency,
        "avg_response_time_minutes": avg_resp_time,
        "daily_requests": daily_requests,
        "stale_hospitals": stale_hospitals
    }

async def list_all_hospitals_admin() -> List[Dict[str, Any]]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    hospitals = await db.hospitals.find({}).to_list(length=100)
    results = []

    for h in hospitals:
        h_id = str(h["_id"])
        
        # Calculate occupancy metrics for this hospital
        caps = await db.capacities.find({"hospital_id": h_id}).to_list(length=50)
        tot_cap = 0
        tot_occ = 0
        icu_tot = 0
        icu_occ = 0
        lu = None

        for c in caps:
            tot = c.get("total", 0)
            occ = c.get("occupied", 0)
            r_type = c.get("resource_type", "")
            tot_cap += tot
            tot_occ += occ

            if r_type == "icu_bed":
                icu_tot += tot
                icu_occ += occ

            c_lu = c.get("last_updated")
            if isinstance(c_lu, datetime):
                if lu is None or c_lu > lu:
                    lu = c_lu

        overall_occ_pct = round((tot_occ / tot_cap * 100.0), 1) if tot_cap > 0 else 0.0
        icu_occ_pct = round((icu_occ / icu_tot * 100.0), 1) if icu_tot > 0 else 0.0
        lu_iso = lu.isoformat() if isinstance(lu, datetime) else None

        loc = h.get("location")
        lat = None
        lng = None
        if isinstance(loc, dict) and "coordinates" in loc and len(loc["coordinates"]) >= 2:
            lng = loc["coordinates"][0]
            lat = loc["coordinates"][1]

        results.append({
            "id": h_id,
            "name": h.get("name"),
            "address": h.get("address"),
            "contact": h.get("contact"),
            "location": loc,
            "latitude": lat,
            "longitude": lng,
            "overall_occupancy_percent": overall_occ_pct,
            "icu_occupancy_percent": icu_occ_pct,
            "total_capacity": tot_cap,
            "total_occupied": tot_occ,
            "verification_status": h.get("verification_status", "verified"),
            "account_status": h.get("account_status", "active"),
            "last_capacity_update": lu_iso
        })

    return results

async def verify_hospital_admin(hospital_id: str, verification_status: str) -> Dict[str, Any]:
    db = get_database()
    if db is None:
        raise HTTPException(status_code=500, detail="Database connection unavailable")

    if verification_status not in ["verified", "rejected", "pending"]:
        raise HTTPException(status_code=400, detail="Status must be 'verified', 'rejected', or 'pending'")

    try:
        query = {"_id": ObjectId(hospital_id)}
    except Exception:
        query = {"_id": hospital_id}

    res = await db.hospitals.update_one(query, {"$set": {"verification_status": verification_status}})
    if res.matched_count == 0:
        raise HTTPException(status_code=404, detail="Hospital not found")

    updated_h = await db.hospitals.find_one(query)
    updated_h["id"] = str(updated_h["_id"])
    del updated_h["_id"]
    return updated_h

from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import HTTPException, status
from database import get_database

async def search_hospitals(
    latitude: float,
    longitude: float,
    required_resources: List[str],
    max_distance_km: float = 30.0
) -> Dict[str, List[Dict[str, Any]]]:
    db = get_database()
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection unavailable"
        )

    if not required_resources:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one required resource must be specified."
        )

    safe_max_dist = max(0.1, max_distance_km)
    max_distance_meters = safe_max_dist * 1000.0

    # 1. MongoDB $geoNear aggregation (2dsphere index on location)
    pipeline = [
        {
            "$geoNear": {
                "near": {
                    "type": "Point",
                    "coordinates": [longitude, latitude]  # GeoJSON: [lng, lat]
                },
                "distanceField": "distance_meters",
                "maxDistance": max_distance_meters,
                "spherical": True,
                "query": {
                    "verification_status": "verified",
                    "account_status": "active"
                }
            }
        }
    ]

    hospitals = await db.hospitals.aggregate(pipeline).to_list(length=100)

    suitable_hospitals = []
    excluded_hospitals = []

    now = datetime.now(timezone.utc)

    for hosp in hospitals:
        hosp_id = str(hosp["_id"])
        distance_meters = hosp.get("distance_meters", 0.0)
        distance_km = round(distance_meters / 1000.0, 2)
        # travel time at 30 km/h: (distance_km / 30) * 60 minutes
        travel_minutes = round((distance_km / 30.0) * 60.0, 1)

        # Fetch capacity records for required resources
        caps_cursor = db.capacities.find({
            "hospital_id": hosp_id,
            "resource_type": {"$in": required_resources}
        })
        cap_docs = await caps_cursor.to_list(length=len(required_resources))
        cap_map = {c["resource_type"]: c for c in cap_docs}

        missing_reasons = []
        capacity_summary = {}
        last_updated_times = []

        for res in required_resources:
            cap = cap_map.get(res)
            if not cap:
                missing_reasons.append(f"No {res} capacity record")
                capacity_summary[res] = {
                    "total": 0,
                    "occupied": 0,
                    "reserved": 0,
                    "temporarily_unavailable": 0,
                    "available": 0
                }
            else:
                avail = cap.get("available", 0)
                tot = cap.get("total", 0)
                occ = cap.get("occupied", 0)
                resv = cap.get("reserved", 0)
                temp_unavail = cap.get("temporarily_unavailable", 0)

                capacity_summary[res] = {
                    "total": tot,
                    "occupied": occ,
                    "reserved": resv,
                    "temporarily_unavailable": temp_unavail,
                    "available": avail
                }

                lu = cap.get("last_updated")
                if isinstance(lu, datetime):
                    if lu.tzinfo is None:
                        lu = lu.replace(tzinfo=timezone.utc)
                    last_updated_times.append(lu)

                if avail < 1:
                    missing_reasons.append(f"No {res} available")

        # Stale check (>30 minutes)
        if last_updated_times:
            most_recent_lu = max(last_updated_times)
            diff_min = (now - most_recent_lu).total_seconds() / 60.0
            is_stale = diff_min > 30.0
            lu_iso = most_recent_lu.isoformat()
        else:
            is_stale = False
            lu_iso = None

        hosp_item = {
            "hospital_id": hosp_id,
            "name": hosp["name"],
            "address": hosp.get("address", ""),
            "contact": hosp.get("contact", ""),
            "location": hosp.get("location"),
            "distance_km": distance_km,
            "estimated_travel_minutes": travel_minutes,
            "capacities": capacity_summary,
            "last_updated": lu_iso,
            "stale": is_stale
        }

        # HARD FILTER: Check if any required resource has available < 1
        if missing_reasons:
            hosp_item["exclusion_reason"] = ", ".join(missing_reasons)
            excluded_hospitals.append(hosp_item)
        else:
            # SCORING (0-100 match %)
            dist_score = max(0.0, 1.0 - (distance_km / safe_max_dist))

            avail_ratios = []
            occ_ratios = []
            for res in required_resources:
                tot = capacity_summary[res]["total"]
                if tot > 0:
                    avail_ratios.append(capacity_summary[res]["available"] / tot)
                    occ_ratios.append(capacity_summary[res]["occupied"] / tot)
                else:
                    avail_ratios.append(0.0)
                    occ_ratios.append(1.0)

            avg_avail_score = sum(avail_ratios) / len(avail_ratios) if avail_ratios else 0.0
            avg_occ = sum(occ_ratios) / len(occ_ratios) if occ_ratios else 1.0
            low_occ_score = max(0.0, 1.0 - avg_occ)

            score = (0.5 * dist_score) + (0.3 * avg_avail_score) + (0.2 * low_occ_score)
            hosp_item["match_percent"] = round(score * 100.0, 1)

            suitable_hospitals.append(hosp_item)

    # Sort suitable hospitals by match_percent descending
    suitable_hospitals.sort(key=lambda x: x["match_percent"], reverse=True)

    return {
        "suitable": suitable_hospitals,
        "excluded": excluded_hospitals
    }

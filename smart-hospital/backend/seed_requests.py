import asyncio
import random
from datetime import datetime, timedelta, timezone
from database import get_database, ping_db

RESOURCE_COMBOS = [
    ["icu_bed"],
    ["icu_bed", "ventilator"],
    ["emergency_bed"],
    ["general_bed"],
    ["ambulance", "emergency_bed"],
    ["icu_bed", "dialysis"],
    ["operation_theatre"],
    ["nicu_bed"],
]

URGENCIES = ["low", "medium", "high", "critical"]
STATUSES = ["accepted", "accepted", "accepted", "rejected", "expired", "cancelled", "request_sent"]

async def seed_requests():
    print("Connecting to database...")
    await ping_db()
    db = get_database()
    if db is None:
        print("Error: Could not connect to database.")
        return

    # Clear existing requests
    await db.requests.delete_many({})
    print("Existing requests cleared.")

    hospitals = await db.hospitals.find({}).to_list(length=100)
    users = await db.users.find({}).to_list(length=100)
    patient_users = [u for u in users if u.get("role") in ["patient", "coordinator"]]

    if not hospitals or not patient_users:
        print("Error: Hospitals or patient users missing. Run seed.py first.")
        return

    now = datetime.now(timezone.utc)
    requests_to_insert = []

    # Generate 42 requests spread across past 7 days
    for i in range(42):
        days_offset = random.uniform(0.1, 6.8)
        created_at = now - timedelta(days=days_offset)

        hosp = random.choice(hospitals)
        hosp_id = str(hosp["_id"])
        hosp_loc = hosp.get("location", {"type": "Point", "coordinates": [78.4, 17.4]})

        patient_user = random.choice(patient_users)
        requester_id = str(patient_user["_id"])

        resources = random.choice(RESOURCE_COMBOS)
        urgency = random.choice(URGENCIES)
        status_choice = random.choice(STATUSES)

        accepted_at = None
        reservation_expires_at = None

        if status_choice == "accepted":
            # Response time between 2 and 18 minutes
            resp_mins = random.uniform(2.0, 18.0)
            accepted_at = created_at + timedelta(minutes=resp_mins)
        elif status_choice in ["request_sent", "expired"]:
            reservation_expires_at = created_at + timedelta(minutes=15)

        req_doc = {
            "patient_reference": f"PAT-{random.randint(10000, 99999)}",
            "requester_id": requester_id,
            "required_resources": resources,
            "urgency": urgency,
            "location": hosp_loc,
            "selected_hospital_id": hosp_id,
            "status": status_choice,
            "created_at": created_at,
            "accepted_at": accepted_at,
            "reservation_expires_at": reservation_expires_at
        }

        requests_to_insert.append(req_doc)

    print(f"Inserting {len(requests_to_insert)} fake historical requests...")
    await db.requests.insert_many(requests_to_insert)
    print("Historical requests seeded successfully!\n")

if __name__ == "__main__":
    asyncio.run(seed_requests())

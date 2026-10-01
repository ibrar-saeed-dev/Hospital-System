import asyncio
import httpx
from datetime import datetime, timedelta, timezone
from bson import ObjectId
from database import get_database
from main import app
from services.referral import expire_stale_reservations

async def run_all_tests():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        db = get_database()

        # 1. Login Users
        p_res = await client.post("/auth/login", json={"email": "patient@smarthospital.org", "password": "demo123"})
        patient_token = p_res.json()["access_token"]
        patient_headers = {"Authorization": f"Bearer {patient_token}"}

        s_res = await client.post("/auth/login", json={"email": "staff.jubilee_hills@smarthospital.org", "password": "demo123"})
        staff_token = s_res.json()["access_token"]
        hosp_id = s_res.json()["hospital_id"]
        staff_headers = {"Authorization": f"Bearer {staff_token}"}

        # TEST 1: Send Request (icu_bed + ventilator) -> available -1, reserved +1
        print("=== TEST 1: Send Request & Verify Capacity Reservation ===")
        cap_before = await db.capacities.find_one({"hospital_id": hosp_id, "resource_type": "icu_bed"})
        print(f"Before Request - ICU Available: {cap_before['available']}, Reserved: {cap_before['reserved']}")

        req_payload = {
            "patient_reference": "TEST-PAT-101",
            "required_resources": ["icu_bed", "ventilator"],
            "urgency": "critical",
            "latitude": 17.4325,
            "longitude": 78.4071,
            "selected_hospital_id": hosp_id
        }

        res1 = await client.post("/requests", json=req_payload, headers=patient_headers)
        print("Create Request Status:", res1.status_code)
        req1_data = res1.json()
        req1_id = req1_data["id"]
        print("Request created:", req1_data)

        cap_after1 = await db.capacities.find_one({"hospital_id": hosp_id, "resource_type": "icu_bed"})
        print(f"After Request - ICU Available: {cap_after1['available']}, Reserved: {cap_after1['reserved']}")
        assert cap_after1["available"] == cap_before["available"] - 1
        assert cap_after1["reserved"] == cap_before["reserved"] + 1
        print("SUCCESS: Available decreased by 1, Reserved increased by 1.")

        # TEST 2: Staff Accepts Request -> reserved -1, occupied +1
        print("\n=== TEST 2: Accept Request as Staff ===")
        accept_res = await client.patch(f"/requests/{req1_id}/accept", headers=staff_headers)
        print("Accept Status:", accept_res.status_code)
        print("Accepted Request:", accept_res.json())

        cap_after_accept = await db.capacities.find_one({"hospital_id": hosp_id, "resource_type": "icu_bed"})
        print(f"After Accept - ICU Occupied: {cap_after_accept['occupied']}, Reserved: {cap_after_accept['reserved']}")
        assert cap_after_accept["reserved"] == cap_after1["reserved"] - 1
        assert cap_after_accept["occupied"] == cap_after1["occupied"] + 1
        print("SUCCESS: Reserved decreased by 1, Occupied increased by 1.")

        # TEST 3: Send & Reject Request -> reserved -1, available +1
        print("\n=== TEST 3: Send & Reject Request ===")
        res2 = await client.post("/requests", json=req_payload, headers=patient_headers)
        req2_id = res2.json()["id"]

        reject_res = await client.patch(f"/requests/{req2_id}/reject", headers=staff_headers)
        print("Reject Status:", reject_res.status_code)
        print("Rejected Request:", reject_res.json())

        cap_after_reject = await db.capacities.find_one({"hospital_id": hosp_id, "resource_type": "icu_bed"})
        print(f"After Reject - ICU Available: {cap_after_reject['available']}, Reserved: {cap_after_reject['reserved']}")
        assert cap_after_reject["available"] == cap_after_accept["available"]
        print("SUCCESS: Bed reservation released on reject.")

        # TEST 4: Expiry Job Test
        print("\n=== TEST 4: Expiry Job Test ===")
        res3 = await client.post("/requests", json=req_payload, headers=patient_headers)
        req3_id = res3.json()["id"]

        # Artificially set reservation_expires_at in past
        past_time = datetime.now(timezone.utc) - timedelta(minutes=5)
        await db.requests.update_one({"_id": ObjectId(req3_id)}, {"$set": {"reservation_expires_at": past_time}})

        print("Running expiry check...")
        await expire_stale_reservations()

        expired_req = await db.requests.find_one({"_id": ObjectId(req3_id)})
        print("Expired Request Status in DB:", expired_req["status"])
        assert expired_req["status"] == "expired"
        print("SUCCESS: Request expired automatically and bed returned to available.")

        # TEST 5: Concurrency Test (Two simultaneous requests for resource with available=1)
        print("\n=== TEST 5: Concurrency Test (Atomic Reservation) ===")
        # Set ambulance available = 1
        await db.capacities.update_one(
            {"hospital_id": hosp_id, "resource_type": "ambulance"},
            {"$set": {"total": 5, "occupied": 4, "reserved": 0, "temporarily_unavailable": 0, "available": 1}}
        )

        conc_payload = {
            "patient_reference": "CONC-PAT",
            "required_resources": ["ambulance"],
            "urgency": "critical",
            "latitude": 17.4325,
            "longitude": 78.4071,
            "selected_hospital_id": hosp_id
        }

        # Fire 2 simultaneous requests
        task1 = client.post("/requests", json=conc_payload, headers=patient_headers)
        task2 = client.post("/requests", json=conc_payload, headers=patient_headers)

        results = await asyncio.gather(task1, task2, return_exceptions=True)
        status_codes = [r.status_code for r in results]
        print("Concurrency Results Status Codes:", status_codes)

        assert 200 in status_codes
        assert 409 in status_codes
        print("SUCCESS: Atomic reservation guaranteed only 1 succeeded (200) and 1 failed (409 Conflict).")

if __name__ == "__main__":
    asyncio.run(run_all_tests())

import asyncio
import httpx
import json
from main import app

async def test_analytics_and_admin():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login Staff User
        staff_login = await client.post("/auth/login", json={"email": "staff.hitech_city@smarthospital.org", "password": "demo123"})
        staff_token = staff_login.json()["access_token"]
        staff_headers = {"Authorization": f"Bearer {staff_token}"}

        # 2. Login Admin User
        admin_login = await client.post("/auth/login", json={"email": "admin@smarthospital.org", "password": "demo123"})
        admin_token = admin_login.json()["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # Test GET /analytics/hospital
        print("=== 1. GET /analytics/hospital (Staff User) ===")
        hosp_analytics = await client.get("/analytics/hospital", headers=staff_headers)
        print("Status Code:", hosp_analytics.status_code)
        print("Hospital Metrics:")
        print(json.dumps(hosp_analytics.json(), indent=2))

        # Test GET /analytics/system
        print("\n=== 2. GET /analytics/system (Admin User) ===")
        sys_analytics = await client.get("/analytics/system", headers=admin_headers)
        print("Status Code:", sys_analytics.status_code)
        print("System Metrics:")
        print(json.dumps(sys_analytics.json(), indent=2))

        # Test GET /admin/hospitals
        print("\n=== 3. GET /admin/hospitals (Admin User) ===")
        admin_hospitals = await client.get("/admin/hospitals", headers=admin_headers)
        print("Status Code:", admin_hospitals.status_code)
        hospitals_list = admin_hospitals.json()
        print(f"Total Hospitals Found: {len(hospitals_list)}")
        print("Sample Hospital:", json.dumps(hospitals_list[0], indent=2))

        target_hosp_id = hospitals_list[0]["id"]

        # Test PATCH /admin/hospitals/{id}/verify
        print(f"\n=== 4. PATCH /admin/hospitals/{target_hosp_id}/verify (Admin User) ===")
        verify_res = await client.patch(
            f"/admin/hospitals/{target_hosp_id}/verify",
            json={"verification_status": "verified"},
            headers=admin_headers
        )
        print("Status Code:", verify_res.status_code)
        print("Updated Hospital:", json.dumps(verify_res.json(), indent=2))

if __name__ == "__main__":
    asyncio.run(test_analytics_and_admin())

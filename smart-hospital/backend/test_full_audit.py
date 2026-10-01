import asyncio
import os
import time
import requests
import json
from datetime import datetime, timezone
from bson import ObjectId
from database import get_database, ping_db
from seed import seed

BASE_URL = "http://localhost:8000"

def log_test(name, result, evidence):
    status = "PASS" if result else "FAIL"
    print(f"[{status}] {name} :: {evidence}")
    return result

async def run_all_tests():
    print("=" * 80)
    print("STARTING FULL AUTOMATED QA & DEVOPS SUITE FOR SMART HOSPITAL")
    print("=" * 80)

    results = {}

    # Reset DB to clean state
    await seed()
    db = get_database()

    # --- SECTION A: BACKEND FUNCTIONAL TESTS ---
    print("\n--- SECTION A: BACKEND FUNCTIONAL TESTS ---")

    # A1: Health & MongoDB
    try:
        r = requests.get(f"{BASE_URL}/health")
        r_json = r.json()
        pass_a1 = r.status_code == 200 and r_json.get("status") == "ok"
        results["A1"] = log_test("A1: Health & Mongo", pass_a1, f"Status={r.status_code}, Body={r_json}")
    except Exception as e:
        results["A1"] = log_test("A1: Health & Mongo", False, str(e))

    # A2: Login for all 4 roles & wrong password 401
    roles_credentials = {
        "admin": ("admin@smarthospital.org", "demo123"),
        "coordinator": ("coordinator@smarthospital.org", "demo123"),
        "patient": ("patient@smarthospital.org", "demo123"),
        "staff": ("staff.qasimabad@smarthospital.org", "demo123")
    }
    tokens = {}
    pass_a2 = True
    a2_evidence = []

    for role, (email, pwd) in roles_credentials.items():
        r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": pwd})
        if r.status_code == 200 and "access_token" in r.json():
            tokens[role] = r.json()["access_token"]
            a2_evidence.append(f"{role}=200 OK")
        else:
            pass_a2 = False
            a2_evidence.append(f"{role}={r.status_code}")

    r_bad = requests.post(f"{BASE_URL}/auth/login", json={"email": "admin@smarthospital.org", "password": "wrongpassword"})
    if r_bad.status_code == 401:
        a2_evidence.append("wrong_pwd=401 Unauthorized")
    else:
        pass_a2 = False
        a2_evidence.append(f"wrong_pwd={r_bad.status_code}")

    results["A2"] = log_test("A2: Role Logins & Invalid Password", pass_a2, ", ".join(a2_evidence))

    # A3: Staff capacity operations & audit log
    headers_staff = {"Authorization": f"Bearer {tokens['staff']}"}
    r_my_cap = requests.get(f"{BASE_URL}/capacity/my-hospital", headers=headers_staff)
    my_caps = r_my_cap.json()
    
    icu_before = next(c for c in my_caps if c["resource_type"] == "icu_bed")
    # Valid update
    r_update = requests.put(
        f"{BASE_URL}/capacity/icu_bed",
        json={"total": 20, "occupied": 10, "temporarily_unavailable": 2},
        headers=headers_staff
    )
    pass_a3_valid = r_update.status_code == 200 and r_update.json()["available"] == 8
    
    # Invalid updates
    r_neg = requests.put(
        f"{BASE_URL}/capacity/icu_bed",
        json={"total": 20, "occupied": -5, "temporarily_unavailable": 2},
        headers=headers_staff
    )
    r_exceed = requests.put(
        f"{BASE_URL}/capacity/icu_bed",
        json={"total": 10, "occupied": 10, "temporarily_unavailable": 5},
        headers=headers_staff
    )
    pass_a3_invalid = (r_neg.status_code in [400, 422]) and r_exceed.status_code == 400

    # Audit log check
    audit_entry = await db.audit_logs.find_one({"resource_type": "icu_bed"})
    pass_a3_audit = audit_entry is not None

    pass_a3 = pass_a3_valid and pass_a3_invalid and pass_a3_audit
    results["A3"] = log_test(
        "A3: Capacity Update & Audit Log",
        pass_a3,
        f"ValidUpdate={r_update.status_code} (Avail={r_update.json().get('available')}), NegInput={r_neg.status_code}, ExceedTotal={r_exceed.status_code}, AuditDoc={pass_a3_audit}"
    )

    # Re-seed to ensure pristine capacity for A4 and onwards
    await seed()
    for role, (email, pwd) in roles_credentials.items():
        r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": pwd})
        tokens[role] = r.json()["access_token"]
    
    headers_patient = {"Authorization": f"Bearer {tokens['patient']}"}
    headers_staff = {"Authorization": f"Bearer {tokens['staff']}"}
    headers_admin = {"Authorization": f"Bearer {tokens['admin']}"}

    # A4: Search from City Centre (25.3960, 68.3578)
    search_payload = {
        "required_resources": ["icu_bed", "ventilator"],
        "latitude": 25.3960,
        "longitude": 68.3578,
        "max_distance_km": 30.0
    }
    r_search = requests.post(f"{BASE_URL}/search", json=search_payload, headers=headers_patient)
    search_res = r_search.json()
    suitable_names = [h["name"] for h in search_res.get("suitable", [])]
    excluded_map = {h["name"]: h["exclusion_reason"] for h in search_res.get("excluded", [])}

    pass_hirabad = "Hirabad Medical Centre" in excluded_map and "ventilator" in excluded_map["Hirabad Medical Centre"]
    pass_saddar = "Saddar City Hospital" in excluded_map and "icu_bed" in excluded_map["Saddar City Hospital"]
    
    # Check sorting of suitable
    matches = [h["match_percent"] for h in search_res.get("suitable", [])]
    pass_sorted = matches == sorted(matches, reverse=True)

    # 1-resource search, 3-resource search, non-qualifying search
    r_single = requests.post(f"{BASE_URL}/search", json={"required_resources": ["ambulance"], "latitude": 25.3960, "longitude": 68.3578}, headers=headers_patient)
    r_triple = requests.post(f"{BASE_URL}/search", json={"required_resources": ["icu_bed", "ventilator", "dialysis"], "latitude": 25.3960, "longitude": 68.3578}, headers=headers_patient)
    r_empty = requests.post(f"{BASE_URL}/search", json={"required_resources": ["icu_bed"], "latitude": 0.0, "longitude": 0.0, "max_distance_km": 1.0}, headers=headers_patient)
    
    pass_search_variations = r_single.status_code == 200 and r_triple.status_code == 200 and r_empty.status_code == 200 and len(r_empty.json()["suitable"]) == 0

    pass_a4 = pass_hirabad and pass_saddar and pass_sorted and pass_search_variations
    results["A4"] = log_test(
        "A4: Hospital Search & Matching Engine",
        pass_a4,
        f"HirabadExcluded={pass_hirabad}, SaddarExcluded={pass_saddar}, Sorted={pass_sorted}, EmptyDistNoCrash={len(r_empty.json()['suitable']) == 0}"
    )

    # A5: Referral Lifecycle
    qasimabad_hosp = await db.hospitals.find_one({"name": "Sindh Care Teaching Hospital"})
    q_id = str(qasimabad_hosp["_id"])

    # Create request
    req_body = {
        "patient_reference": "PAT-QA-001",
        "required_resources": ["icu_bed"],
        "urgency": "critical",
        "latitude": 25.4150,
        "longitude": 68.3100,
        "selected_hospital_id": q_id
    }
    r_create = requests.post(f"{BASE_URL}/requests", json=req_body, headers=headers_patient)
    req_data = r_create.json()
    req_id = req_data["id"]

    cap_after_create = await db.capacities.find_one({"hospital_id": q_id, "resource_type": "icu_bed"})
    pass_reserve = cap_after_create["reserved"] == 1 and cap_after_create["available"] == 4  # Initial was 20 total, 15 occupied, 5 available

    # Accept request
    r_accept = requests.patch(f"{BASE_URL}/requests/{req_id}/accept", headers=headers_staff)
    cap_after_accept = await db.capacities.find_one({"hospital_id": q_id, "resource_type": "icu_bed"})
    pass_accept = cap_after_accept["reserved"] == 0 and cap_after_accept["occupied"] == 16

    # Transfer patient
    r_transfer = requests.patch(f"{BASE_URL}/requests/{req_id}/status", json={"status": "patient_transferred"}, headers=headers_staff)
    pass_transfer = r_transfer.status_code == 200 and r_transfer.json()["status"] == "patient_transferred"

    # Admit patient
    r_admit = requests.patch(f"{BASE_URL}/requests/{req_id}/status", json={"status": "admitted"}, headers=headers_staff)
    pass_admit = r_admit.status_code == 200 and r_admit.json()["status"] == "admitted"

    # Test Reject lifecycle
    r_create2 = requests.post(f"{BASE_URL}/requests", json={**req_body, "patient_reference": "PAT-QA-002"}, headers=headers_patient)
    req_id2 = r_create2.json()["id"]
    r_reject = requests.patch(f"{BASE_URL}/requests/{req_id2}/reject", headers=headers_staff)
    cap_after_reject = await db.capacities.find_one({"hospital_id": q_id, "resource_type": "icu_bed"})
    pass_reject = r_reject.status_code == 200 and cap_after_reject["reserved"] == 0

    # Test Cancel lifecycle
    r_create3 = requests.post(f"{BASE_URL}/requests", json={**req_body, "patient_reference": "PAT-QA-003"}, headers=headers_patient)
    req_id3 = r_create3.json()["id"]
    r_cancel = requests.patch(f"{BASE_URL}/requests/{req_id3}/cancel", headers=headers_patient)
    cap_after_cancel = await db.capacities.find_one({"hospital_id": q_id, "resource_type": "icu_bed"})
    pass_cancel = r_cancel.status_code == 200 and cap_after_cancel["reserved"] == 0

    pass_a5 = pass_reserve and pass_accept and pass_transfer and pass_admit and pass_reject and pass_cancel
    results["A5"] = log_test(
        "A5: Referral Request Lifecycle",
        pass_a5,
        f"Reserve={pass_reserve}, Accept={pass_accept}, Transfer={pass_transfer}, Admit={pass_admit}, Reject={pass_reject}, Cancel={pass_cancel}"
    )

    # A6: Invalid state transitions blocked
    # 1. Try to accept an already rejected request
    r_inv1 = requests.patch(f"{BASE_URL}/requests/{req_id2}/accept", headers=headers_staff)
    # 2. Try to skip directly from accepted to admitted without patient_transferred
    r_create4 = requests.post(f"{BASE_URL}/requests", json={**req_body, "patient_reference": "PAT-QA-004"}, headers=headers_patient)
    req_id4 = r_create4.json()["id"]
    requests.patch(f"{BASE_URL}/requests/{req_id4}/accept", headers=headers_staff)
    r_inv2 = requests.patch(f"{BASE_URL}/requests/{req_id4}/status", json={"status": "admitted"}, headers=headers_staff)

    pass_a6 = r_inv1.status_code == 400 and r_inv2.status_code == 400
    results["A6"] = log_test(
        "A6: Invalid State Machine Transitions Blocked",
        pass_a6,
        f"AcceptRejected={r_inv1.status_code}, SkipToAdmitted={r_inv2.status_code}"
    )

    # A7: Analytics & Admin verification
    headers_admin = {"Authorization": f"Bearer {tokens['admin']}"}
    r_hosp_analytics = requests.get(f"{BASE_URL}/analytics/hospital", headers=headers_staff)
    r_sys_analytics = requests.get(f"{BASE_URL}/analytics/system", headers=headers_admin)
    r_admin_hospitals = requests.get(f"{BASE_URL}/admin/hospitals", headers=headers_admin)

    # Cross-check MongoDB counts
    db_total_hospitals = await db.hospitals.count_documents({})
    admin_hosp_count = len(r_admin_hospitals.json())
    pass_crosscheck_hosp = admin_hosp_count == db_total_hospitals

    db_requests_count = await db.requests.count_documents({})
    sys_requests_count = sum(r_sys_analytics.json()["request_counts_by_status"].values())
    pass_crosscheck_req = sys_requests_count == db_requests_count

    pass_a7 = r_hosp_analytics.status_code == 200 and r_sys_analytics.status_code == 200 and pass_crosscheck_hosp and pass_crosscheck_req
    results["A7"] = log_test(
        "A7: Analytics & Admin Endpoint Numbers",
        pass_a7,
        f"HospAnalytics=200, SystemAnalytics=200, AdminHospCountMatch=({admin_hosp_count}=={db_total_hospitals}), RequestCountMatch=({sys_requests_count}=={db_requests_count})"
    )

    # --- SECTION B: DATA INTEGRITY AND CONCURRENCY ---
    print("\n--- SECTION B: DATA INTEGRITY AND CONCURRENCY ---")

    # B1: Double booking (10 concurrent requests for resource with available=1)
    # Set Hirabad emergency_bed available = 1 (total 10, occupied 9)
    hirabad = await db.hospitals.find_one({"name": "Hirabad Medical Centre"})
    h_id = str(hirabad["_id"])
    await db.capacities.update_one(
        {"hospital_id": h_id, "resource_type": "emergency_bed"},
        {"$set": {"total": 10, "occupied": 9, "reserved": 0, "available": 1, "temporarily_unavailable": 0}}
    )

    async def send_req(i):
        def sync_post():
            return requests.post(
                f"{BASE_URL}/requests",
                json={
                    "patient_reference": f"PAT-CONCUR-{i}",
                    "required_resources": ["emergency_bed"],
                    "urgency": "high",
                    "latitude": 25.3930,
                    "longitude": 68.3590,
                    "selected_hospital_id": h_id
                },
                headers=headers_patient
            )
        return await asyncio.to_thread(sync_post)

    concurrent_responses = await asyncio.gather(*[send_req(i) for i in range(10)])
    status_codes = [r.status_code for r in concurrent_responses]
    count_200 = status_codes.count(200)
    count_409 = status_codes.count(409)

    hirabad_cap = await db.capacities.find_one({"hospital_id": h_id, "resource_type": "emergency_bed"})
    pass_b1 = count_200 == 1 and count_409 == 9 and hirabad_cap["available"] == 0 and hirabad_cap["reserved"] == 1
    results["B1"] = log_test(
        "B1: Double Booking Concurrency Protection",
        pass_b1,
        f"Success={count_200}, Conflict409={count_409}, FinalAvail={hirabad_cap['available']}, FinalReserved={hirabad_cap['reserved']}"
    )

    # B2: Multi-resource request rollback
    # Hirabad ventilator has available = 0, icu_bed has available = 4
    r_multi_fail = requests.post(
        f"{BASE_URL}/requests",
        json={
            "patient_reference": "PAT-MULTIFIALL",
            "required_resources": ["icu_bed", "ventilator"],
            "urgency": "critical",
            "latitude": 25.3930,
            "longitude": 68.3590,
            "selected_hospital_id": h_id
        },
        headers=headers_patient
    )
    hirabad_icu_after = await db.capacities.find_one({"hospital_id": h_id, "resource_type": "icu_bed"})
    # Hirabad icu_bed initial in seed was total 10, occupied 6, available 4, reserved 0
    pass_b2 = r_multi_fail.status_code == 409 and hirabad_icu_after["reserved"] == 0 and hirabad_icu_after["available"] == 4
    results["B2"] = log_test(
        "B2: Multi-Resource Rollback (No Leaked Reserved Count)",
        pass_b2,
        f"ResponseStatus={r_multi_fail.status_code}, ReservedAfterRollback={hirabad_icu_after['reserved']}, AvailAfterRollback={hirabad_icu_after['available']}"
    )

    # B3: Full Capacity Sanity Check across all records
    all_caps = await db.capacities.find({}).to_list(length=1000)
    inconsistent = []
    for c in all_caps:
        tot = c.get("total", 0)
        occ = c.get("occupied", 0)
        resv = c.get("reserved", 0)
        unavail = c.get("temporarily_unavailable", 0)
        avail = c.get("available", 0)

        calc_avail = tot - occ - resv - unavail
        if avail != calc_avail or avail < 0 or occ < 0 or resv < 0 or unavail < 0:
            inconsistent.append((c["hospital_id"], c["resource_type"], avail, calc_avail))

    pass_b3 = len(inconsistent) == 0
    results["B3"] = log_test(
        "B3: Capacity Formula & Non-Negative Invariance",
        pass_b3,
        f"InconsistentRecordsCount={len(inconsistent)}"
    )

    # B4: Atomic Expiry Release
    # Create request with 1-second expiry
    r_exp_create = requests.post(
        f"{BASE_URL}/requests",
        json={
            "patient_reference": "PAT-EXPIRY-TEST",
            "required_resources": ["icu_bed"],
            "urgency": "low",
            "latitude": 25.3930,
            "longitude": 68.3590,
            "selected_hospital_id": h_id
        },
        headers=headers_patient
    )
    req_exp_id = r_exp_create.json()["id"]
    # Manually set reservation_expires_at in past
    await db.requests.update_one(
        {"_id": ObjectId(req_exp_id)},
        {"$set": {"reservation_expires_at": datetime.now(timezone.utc)}}
    )
    # Import and run expiry function twice to test single release
    from services.referral import expire_stale_reservations
    cap_before_exp = await db.capacities.find_one({"hospital_id": h_id, "resource_type": "icu_bed"})
    res1 = await expire_stale_reservations()
    cap_after_exp1 = await db.capacities.find_one({"hospital_id": h_id, "resource_type": "icu_bed"})
    res2 = await expire_stale_reservations()
    cap_after_exp2 = await db.capacities.find_one({"hospital_id": h_id, "resource_type": "icu_bed"})

    pass_b4 = cap_after_exp1["reserved"] == cap_before_exp["reserved"] - 1 and cap_after_exp2["reserved"] == cap_after_exp1["reserved"]
    results["B4"] = log_test(
        "B4: Atomic Expiry Job Single-Release Protection",
        pass_b4,
        f"ReservedBefore={cap_before_exp['reserved']}, AfterExp1={cap_after_exp1['reserved']}, AfterExp2={cap_after_exp2['reserved']}"
    )

    # --- SECTION C: SECURITY REVIEW ---
    print("\n--- SECTION C: SECURITY REVIEW ---")

    # C1: Role Access Matrix
    endpoints = [
        ("GET", "/health", None, [200, 200, 200, 200, 200]),
        ("GET", "/auth/me", None, [[401, 403], 200, 200, 200, 200]),
        ("GET", "/capacity/my-hospital", None, [[401, 403], 403, 403, 403, 200]),
        ("POST", "/requests", {"patient_reference": "PAT-TEST", "required_resources": ["icu_bed"], "urgency": "low", "latitude": 25.39, "longitude": 68.35, "selected_hospital_id": h_id}, [[401, 403], 403, 200, 200, 403]),
        ("GET", "/requests/hospital", None, [[401, 403], 403, 403, 403, 200]),
        ("GET", "/analytics/hospital", None, [[401, 403], 403, 403, 403, 200]),
        ("GET", "/analytics/system", None, [[401, 403], 200, 403, 403, 403]),
        ("GET", "/admin/hospitals", None, [[401, 403], 200, 403, 403, 403]),
    ]

    pass_c1 = True
    c1_details = []

    for method, path, body, expected_codes in endpoints:
        # Test roles: NoToken, Admin, Coordinator, Patient, Staff
        token_list = [None, tokens["admin"], tokens["coordinator"], tokens["patient"], tokens["staff"]]
        actual_codes = []
        for tok in token_list:
            h = {"Authorization": f"Bearer {tok}"} if tok else {}
            if method == "GET":
                res_code = requests.get(f"{BASE_URL}{path}", headers=h).status_code
            else:
                res_code = requests.post(f"{BASE_URL}{path}", json=body, headers=h).status_code
            actual_codes.append(res_code)
        
        match = True
        for act, exp in zip(actual_codes, expected_codes):
            if isinstance(exp, list):
                if act not in exp:
                    match = False
            else:
                if act != exp:
                    match = False

        if not match:
            pass_c1 = False
            c1_details.append(f"{path}: Expected {expected_codes}, got {actual_codes}")
        else:
            c1_details.append(f"{path}: OK")

    results["C1"] = log_test("C1: Role Access Matrix (401/403/200)", pass_c1, "; ".join(c1_details[:3]))

    # C2: Cross-hospital staff isolation
    # Staff for Qasimabad trying to update Hirabad capacity
    r_cross_cap = requests.put(
        f"{BASE_URL}/hospitals/{h_id}/capacity/icu_bed",
        json={"total": 10, "occupied": 5, "temporarily_unavailable": 0},
        headers=headers_staff
    )
    pass_c2 = r_cross_cap.status_code == 403
    results["C2"] = log_test("C2: Cross-Hospital Staff Isolation (403)", pass_c2, f"Status={r_cross_cap.status_code}")

    # C3: User request isolation
    # User B trying to cancel User A's request
    r_user_b_login = requests.post(f"{BASE_URL}/auth/login", json={"email": "coordinator@smarthospital.org", "password": "demo123"})
    token_user_b = r_user_b_login.json()["access_token"]
    headers_user_b = {"Authorization": f"Bearer {token_user_b}"}

    r_cross_cancel = requests.patch(f"{BASE_URL}/requests/{req_id}/cancel", headers=headers_user_b)
    pass_c3 = r_cross_cancel.status_code == 403
    results["C3"] = log_test("C3: Request Ownership Isolation (403)", pass_c3, f"Status={r_cross_cancel.status_code}")

    # C4: password_hash never appears in API responses
    r_me = requests.get(f"{BASE_URL}/auth/me", headers=headers_staff)
    r_login = requests.post(f"{BASE_URL}/auth/login", json={"email": "admin@smarthospital.org", "password": "demo123"})
    pass_c4 = "password_hash" not in json.dumps(r_me.json()) and "password_hash" not in json.dumps(r_login.json())
    results["C4"] = log_test("C4: Password Hash Privacy", pass_c4, f"MeResponseHasHash={'password_hash' in json.dumps(r_me.json())}")

    # C5: JWT Security
    # Tampered token check
    tampered_token = tokens["patient"] + "tampered"
    r_tamper = requests.get(f"{BASE_URL}/auth/me", headers={"Authorization": f"Bearer {tampered_token}"})
    pass_c5 = r_tamper.status_code == 401
    results["C5"] = log_test("C5: Tampered JWT Rejection", pass_c5, f"Status={r_tamper.status_code}")

    # C6: Code secrets audit
    pass_c6 = os.path.exists(".gitignore") and os.path.exists("../.gitignore")
    results["C6"] = log_test("C6: Secret & Environment Configuration Audit", pass_c6, f"GitIgnoreExists={pass_c6}")

    # C7: Request body validation
    r_val1 = requests.post(f"{BASE_URL}/requests", json={"patient_reference": "PAT-X"}, headers=headers_patient) # missing fields
    r_val2 = requests.put(f"{BASE_URL}/capacity/icu_bed", json={"total": "huge_string"}, headers=headers_staff) # wrong type
    pass_c7 = r_val1.status_code == 422 and r_val2.status_code == 422
    results["C7"] = log_test("C7: Request Body Validation (422 Unprocessable)", pass_c7, f"MissingFields={r_val1.status_code}, WrongType={r_val2.status_code}")

    # C8: No stack traces in responses
    r_err = requests.get(f"{BASE_URL}/hospitals/invalid_object_id/capacity", headers=headers_patient)
    pass_c8 = "Traceback" not in r_err.text and "Exception" not in r_err.text
    results["C8"] = log_test("C8: Clean Error Handling (No Stack Traces)", pass_c8, f"Status={r_err.status_code}, BodyContainsTraceback={'Traceback' in r_err.text}")

    print("\n" + "=" * 80)
    print("AUDIT RESULTS SUMMARY:")
    all_passed = all(results.values())
    print(f"OVERALL STATUS: {'ALL TESTS PASSED' if all_passed else 'SOME TESTS FAILED'}")
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(run_all_tests())

import asyncio
import os
import bcrypt
from datetime import datetime, timezone
from database import get_database, ping_db, create_indexes
from models import (
    UserModel, UserRole,
    HospitalModel, GeoJSONPoint,
    CapacityModel, ResourceType
)

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

# Resource types list
RESOURCE_TYPES = [
    ResourceType.GENERAL_BED,
    ResourceType.EMERGENCY_BED,
    ResourceType.ICU_BED,
    ResourceType.NICU_BED,
    ResourceType.VENTILATOR,
    ResourceType.OPERATION_THEATRE,
    ResourceType.ISOLATION_BED,
    ResourceType.DIALYSIS,
    ResourceType.TRAUMA,
    ResourceType.AMBULANCE,
]

# 10 Hospitals in Hyderabad, Sindh, Pakistan
HOSPITALS_DATA = [
    {
        "name": "Sindh Care Teaching Hospital",
        "address": "Qasimabad, Hyderabad, Sindh, Pakistan",
        "contact": "022-2781001",
        "lng": 68.3100,
        "lat": 25.4150,
        "key": "qasimabad"
    },
    {
        "name": "Latifabad Civil Hospital",
        "address": "Latifabad Unit 7, Hyderabad, Sindh, Pakistan",
        "contact": "022-2931002",
        "lng": 68.3780,
        "lat": 25.3980,
        "key": "latifabad"
    },
    {
        "name": "Hirabad Medical Centre",
        "address": "Hirabad, Hyderabad, Sindh, Pakistan",
        "contact": "022-2611003",
        "lng": 68.3590,
        "lat": 25.3930,
        "key": "hirabad"
    },
    {
        "name": "Saddar City Hospital",
        "address": "Saddar, Hyderabad, Sindh, Pakistan",
        "contact": "022-2721004",
        "lng": 68.3650,
        "lat": 25.3920,
        "key": "saddar"
    },
    {
        "name": "Autobahn Road Hospital",
        "address": "Autobahn Road, Hyderabad, Sindh, Pakistan",
        "contact": "022-2761005",
        "lng": 68.3450,
        "lat": 25.3650,
        "key": "autobahn_road"
    },
    {
        "name": "Gulistan-e-Sajjad Hospital",
        "address": "Gulistan-e-Sajjad, Hyderabad, Sindh, Pakistan",
        "contact": "022-2841006",
        "lng": 68.3700,
        "lat": 25.4010,
        "key": "gulistan_e_sajjad"
    },
    {
        "name": "Jamshoro Road Teaching Hospital",
        "address": "Jamshoro Road, Hyderabad, Sindh, Pakistan",
        "contact": "022-2771007",
        "lng": 68.2900,
        "lat": 25.4200,
        "key": "jamshoro_road"
    },
    {
        "name": "Fateh Chowk Emergency Hospital",
        "address": "Fateh Chowk, Hyderabad, Sindh, Pakistan",
        "contact": "022-2631008",
        "lng": 68.3720,
        "lat": 25.3850,
        "key": "fateh_chowk"
    },
    {
        "name": "Kotri Road Medical Centre",
        "address": "Kotri Road, Hyderabad, Sindh, Pakistan",
        "contact": "022-2691009",
        "lng": 68.3080,
        "lat": 25.3640,
        "key": "kotri_road"
    },
    {
        "name": "Pretabad Women & Children Hospital",
        "address": "Pretabad, Hyderabad, Sindh, Pakistan",
        "contact": "022-2711010",
        "lng": 68.3640,
        "lat": 25.3990,
        "key": "pretabad"
    }
]

# Exact capacities map per hospital key & resource type (total, occupied)
CAPACITY_PRESETS = {
    "qasimabad": {
        ResourceType.ICU_BED: (20, 15),
        ResourceType.VENTILATOR: (12, 8),
        ResourceType.EMERGENCY_BED: (30, 22),
        ResourceType.GENERAL_BED: (150, 120),
        ResourceType.NICU_BED: (10, 6),
        ResourceType.OPERATION_THEATRE: (6, 3),
        ResourceType.ISOLATION_BED: (15, 9),
        ResourceType.DIALYSIS: (10, 5),
        ResourceType.TRAUMA: (10, 6),
        ResourceType.AMBULANCE: (6, 2),
    },
    "latifabad": {
        ResourceType.ICU_BED: (15, 12),
        ResourceType.VENTILATOR: (8, 5),
        ResourceType.EMERGENCY_BED: (25, 20),
        ResourceType.GENERAL_BED: (120, 100),
        ResourceType.NICU_BED: (8, 7),
        ResourceType.OPERATION_THEATRE: (5, 3),
        ResourceType.ISOLATION_BED: (12, 8),
        ResourceType.DIALYSIS: (8, 4),
        ResourceType.TRAUMA: (8, 5),
        ResourceType.AMBULANCE: (5, 2),
    },
    "hirabad": {
        # TRAP: ICU available (10/6), but ZERO ventilators available (4/4)!
        ResourceType.ICU_BED: (10, 6),
        ResourceType.VENTILATOR: (4, 4),
        ResourceType.EMERGENCY_BED: (15, 9),
        ResourceType.GENERAL_BED: (60, 40),
        ResourceType.NICU_BED: (4, 2),
        ResourceType.OPERATION_THEATRE: (2, 1),
        ResourceType.ISOLATION_BED: (6, 3),
        ResourceType.DIALYSIS: (4, 2),
        ResourceType.TRAUMA: (4, 2),
        ResourceType.AMBULANCE: (2, 1),
    },
    "saddar": {
        # TRAP: ICU completely full (12/12)!
        ResourceType.ICU_BED: (12, 12),
        ResourceType.VENTILATOR: (6, 6),
        ResourceType.EMERGENCY_BED: (20, 18),
        ResourceType.GENERAL_BED: (80, 78),
        ResourceType.NICU_BED: (6, 6),
        ResourceType.OPERATION_THEATRE: (3, 3),
        ResourceType.ISOLATION_BED: (8, 7),
        ResourceType.DIALYSIS: (5, 4),
        ResourceType.TRAUMA: (5, 4),
        ResourceType.AMBULANCE: (3, 2),
    },
    "autobahn_road": {
        ResourceType.ICU_BED: (18, 10),
        ResourceType.VENTILATOR: (10, 4),
        ResourceType.EMERGENCY_BED: (28, 15),
        ResourceType.GENERAL_BED: (140, 90),
        ResourceType.NICU_BED: (12, 5),
        ResourceType.OPERATION_THEATRE: (6, 2),
        ResourceType.ISOLATION_BED: (14, 7),
        ResourceType.DIALYSIS: (8, 3),
        ResourceType.TRAUMA: (8, 3),
        ResourceType.AMBULANCE: (5, 2),
    },
    "gulistan_e_sajjad": {
        ResourceType.ICU_BED: (8, 5),
        ResourceType.VENTILATOR: (5, 2),
        ResourceType.EMERGENCY_BED: (12, 8),
        ResourceType.GENERAL_BED: (50, 35),
        ResourceType.NICU_BED: (6, 3),
        ResourceType.OPERATION_THEATRE: (3, 1),
        ResourceType.ISOLATION_BED: (6, 3),
        ResourceType.DIALYSIS: (4, 2),
        ResourceType.TRAUMA: (4, 2),
        ResourceType.AMBULANCE: (3, 1),
    },
    "jamshoro_road": {
        ResourceType.ICU_BED: (25, 18),
        ResourceType.VENTILATOR: (15, 9),
        ResourceType.EMERGENCY_BED: (35, 25),
        ResourceType.GENERAL_BED: (200, 160),
        ResourceType.NICU_BED: (14, 9),
        ResourceType.OPERATION_THEATRE: (8, 4),
        ResourceType.ISOLATION_BED: (20, 12),
        ResourceType.DIALYSIS: (12, 6),
        ResourceType.TRAUMA: (12, 7),
        ResourceType.AMBULANCE: (8, 3),
    },
    "fateh_chowk": {
        # High trauma capacity!
        ResourceType.ICU_BED: (6, 5),
        ResourceType.VENTILATOR: (4, 3),
        ResourceType.EMERGENCY_BED: (40, 34),
        ResourceType.GENERAL_BED: (40, 32),
        ResourceType.NICU_BED: (2, 2),
        ResourceType.OPERATION_THEATRE: (3, 2),
        ResourceType.ISOLATION_BED: (6, 4),
        ResourceType.DIALYSIS: (4, 3),
        ResourceType.TRAUMA: (12, 8),
        ResourceType.AMBULANCE: (6, 2),
    },
    "kotri_road": {
        ResourceType.ICU_BED: (10, 4),
        ResourceType.VENTILATOR: (6, 2),
        ResourceType.EMERGENCY_BED: (14, 6),
        ResourceType.GENERAL_BED: (70, 40),
        ResourceType.NICU_BED: (6, 2),
        ResourceType.OPERATION_THEATRE: (3, 1),
        ResourceType.ISOLATION_BED: (8, 4),
        ResourceType.DIALYSIS: (5, 2),
        ResourceType.TRAUMA: (5, 2),
        ResourceType.AMBULANCE: (3, 1),
    },
    "pretabad": {
        # Women & Children: 0 trauma, 0 dialysis! High NICU (20/14)
        ResourceType.ICU_BED: (6, 3),
        ResourceType.VENTILATOR: (3, 1),
        ResourceType.EMERGENCY_BED: (10, 5),
        ResourceType.GENERAL_BED: (60, 35),
        ResourceType.NICU_BED: (20, 14),
        ResourceType.OPERATION_THEATRE: (4, 2),
        ResourceType.ISOLATION_BED: (10, 5),
        ResourceType.DIALYSIS: (0, 0),
        ResourceType.TRAUMA: (0, 0),
        ResourceType.AMBULANCE: (4, 1),
    },
}

async def seed():
    print("Connecting to database...")
    await ping_db()
    db = get_database()
    if db is None:
        print("Error: Could not connect to database. Check MONGODB_URI.")
        return

    print("Clearing existing collections...")
    await db.users.delete_many({})
    await db.hospitals.delete_many({})
    await db.capacities.delete_many({})
    await db.requests.delete_many({})
    await db.audit_logs.delete_many({})
    print("Collections cleared successfully.")

    # Ensure indexes
    await create_indexes()

    demo_password_hash = hash_password("demo123")

    inserted_hospitals = []
    users_to_insert = []
    capacities_to_insert = []

    # Insert 10 Hospitals in Hyderabad, Sindh
    for h_info in HOSPITALS_DATA:
        h_doc = HospitalModel(
            name=h_info["name"],
            address=h_info["address"],
            contact=h_info["contact"],
            location=GeoJSONPoint(type="Point", coordinates=[h_info["lng"], h_info["lat"]]),
            verification_status="verified",
            emergency_available=True,
            account_status="active"
        ).model_dump(by_alias=True, exclude={"id"})

        res = await db.hospitals.insert_one(h_doc)
        h_id = str(res.inserted_id)
        inserted_hospitals.append({"id": h_id, "name": h_info["name"], "key": h_info["key"]})

        # Create Staff User for this Hospital
        staff_email = f"staff.{h_info['key']}@smarthospital.org"
        users_to_insert.append(
            UserModel(
                email=staff_email,
                password_hash=demo_password_hash,
                role=UserRole.STAFF,
                hospital_id=h_id,
                name=f"Staff - {h_info['name']}"
            ).model_dump(by_alias=True, exclude={"id"})
        )

        # Capacity Records for every resource type
        hosp_presets = CAPACITY_PRESETS.get(h_info["key"], {})
        for r_type in RESOURCE_TYPES:
            tot, occ = hosp_presets.get(r_type, (10, 5))
            resv = 0
            temp_unavail = 0

            cap_doc = CapacityModel(
                hospital_id=h_id,
                resource_type=r_type,
                total=tot,
                occupied=occ,
                reserved=resv,
                temporarily_unavailable=temp_unavail,
                last_updated=datetime.now(timezone.utc)
            ).model_dump(by_alias=True, exclude={"id"})

            capacities_to_insert.append(cap_doc)

    # Global Admin, Coordinator, Patient Users
    users_to_insert.append(
        UserModel(
            email="admin@smarthospital.org",
            password_hash=demo_password_hash,
            role=UserRole.ADMIN,
            name="System Admin"
        ).model_dump(by_alias=True, exclude={"id"})
    )

    users_to_insert.append(
        UserModel(
            email="coordinator@smarthospital.org",
            password_hash=demo_password_hash,
            role=UserRole.COORDINATOR,
            name="Emergency Dispatch Coordinator"
        ).model_dump(by_alias=True, exclude={"id"})
    )

    users_to_insert.append(
        UserModel(
            email="patient@smarthospital.org",
            password_hash=demo_password_hash,
            role=UserRole.PATIENT,
            name="Demo Patient"
        ).model_dump(by_alias=True, exclude={"id"})
    )

    # Insert Users and Capacities
    print(f"Inserting {len(users_to_insert)} users...")
    await db.users.insert_many(users_to_insert)

    print(f"Inserting {len(capacities_to_insert)} capacity records...")
    await db.capacities.insert_many(capacities_to_insert)

    print("Seed data inserted successfully!\n")

    # Print Table of Demo Accounts
    print("=" * 80)
    print(f"{'Email':<45} | {'Role':<15} | {'Hospital / Note'}")
    print("=" * 80)
    print(f"{'admin@smarthospital.org':<45} | {'admin':<15} | Global Admin")
    print(f"{'coordinator@smarthospital.org':<45} | {'coordinator':<15} | Dispatch Coordinator")
    print(f"{'patient@smarthospital.org':<45} | {'patient':<15} | Demo Patient")
    print("-" * 80)
    for h in inserted_hospitals:
        email = f"staff.{h['key']}@smarthospital.org"
        print(f"{email:<45} | {'staff':<15} | {h['name']}")
    print("=" * 80)
    print("All demo accounts have password: demo123")
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(seed())

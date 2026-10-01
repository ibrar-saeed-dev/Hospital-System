# Smart Hospital Bed System

A real-time hospital bed & resource allocation system, emergency referral matching engine, dispatch coordination portal, and analytics platform built for **Hyderabad, Sindh, Pakistan**.

---

## 🚀 Features

1. **Hospital Resource Search & Matching**: Multi-resource filter (ICU, Ventilators, Emergency, NICU, Dialysis, Trauma, etc.), distance scoring, travel time estimation, and hospital matching engine.
2. **Referral Request Workflow**: Patient/Coordinator referral creation, 15-minute atomic bed reservations, staff review (Accept/Reject), patient transfer & admission state machine.
3. **Hospital Staff Portal**: Real-time capacity management (Total, Occupied, Unavailable), incoming referral request queue, and hospital-level analytics dashboard.
4. **Emergency Dispatch Coordinator Portal**: Compare hospital availability and manage high-urgency patient dispatches across the region.
5. **System Admin Control Center**: System-wide analytics (Top hospitals by occupancy, demand trends, stale data detection) and hospital verification control.

---

## 🛠 Tech Stack

- **Backend**: Python 3.12, FastAPI, MongoDB (Motor async driver), Pydantic v2, PyJWT, Bcrypt
- **Frontend**: Flutter Web, Dart 3, Provider, Dio, `fl_chart`
- **Location Context**: Hyderabad, Sindh, Pakistan (Qasimabad, Latifabad, Hirabad, Saddar, Autobahn Road, Gulistan-e-Sajjad, Jamshoro Road, Fateh Chowk, Kotri Road, Pretabad)

---

## 📂 Project Structure

```text
smart-hospital/
├── backend/
│   ├── database.py             # MongoDB connection & index configuration
│   ├── main.py                 # FastAPI application entry point
│   ├── models/                 # Pydantic data schemas
│   ├── routes/                 # API endpoints (auth, search, capacity, requests, analytics, admin)
│   ├── services/               # Business logic & database operations
│   ├── seed.py                 # Initial database seeding script
│   ├── seed_requests.py        # Demo historical requests generator
│   └── reset_demo.py           # Single-command demo reset script
└── frontend/
    ├── lib/
    │   ├── main.dart           # Flutter application root
    │   ├── config/             # Base URLs and theme setup
    │   ├── models/             # Dart data models
    │   ├── providers/          # AuthProvider state management
    │   ├── services/           # ApiClient and service endpoints
    │   └── screens/
    │       ├── auth/           # Login screen
    │       ├── patient/        # Patient & Coordinator portal (Find Hospital, My Requests)
    │       ├── staff/          # Staff portal (Capacity, Requests, Analytics Dashboard)
    │       └── admin/          # Admin portal (System Analytics, Hospital Management)
    └── web/                    # Web HTML & PWA manifest setup
```

---

## 🏃 Getting Started

### 1. Backend Setup & Reset

```bash
cd backend

# Create virtual environment and install dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Reset demo database to clean state (seeds 10 Sindh hospitals and demo users)
python reset_demo.py

# Start FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 2. Frontend Setup & Run

```bash
cd frontend

# Install Flutter packages
flutter pub get

# Run in Chrome / Web Server
flutter run -d chrome

# Build static production release
flutter build web --release
```

---

## 🔐 Demo Accounts by Role

All demo accounts use the password: **`demo123`**

| Role | Email | Hospital / Scope | Notes |
| :--- | :--- | :--- | :--- |
| **System Admin** | `admin@smarthospital.org` | System-Wide | System Analytics & Hospital Verification |
| **Coordinator** | `coordinator@smarthospital.org` | Regional Dispatch | Emergency Referral & Compare Hospitals |
| **Patient** | `patient@smarthospital.org` | Patient Portal | Find Hospitals & Submit Requests |
| **Staff** | `staff.qasimabad@smarthospital.org` | Sindh Care Teaching Hospital | Qasimabad |
| **Staff** | `staff.latifabad@smarthospital.org` | Latifabad Civil Hospital | Latifabad Unit 7 |
| **Staff** | `staff.hirabad@smarthospital.org` | Hirabad Medical Centre | Hirabad (Trap: ICU available, 0 Ventilators) |
| **Staff** | `staff.saddar@smarthospital.org` | Saddar City Hospital | Saddar (Trap: ICU Full) |
| **Staff** | `staff.autobahn_road@smarthospital.org` | Autobahn Road Hospital | Autobahn Road |
| **Staff** | `staff.gulistan_e_sajjad@smarthospital.org` | Gulistan-e-Sajjad Hospital | Gulistan-e-Sajjad |
| **Staff** | `staff.jamshoro_road@smarthospital.org` | Jamshoro Road Teaching Hospital | Jamshoro Road |
| **Staff** | `staff.fateh_chowk@smarthospital.org` | Fateh Chowk Emergency Hospital | Fateh Chowk (High Trauma) |
| **Staff** | `staff.kotri_road@smarthospital.org` | Kotri Road Medical Centre | Kotri Road |
| **Staff** | `staff.pretabad@smarthospital.org` | Pretabad Women & Children Hospital | Pretabad (0 Trauma/Dialysis) |

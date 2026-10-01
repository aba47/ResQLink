# 🚨 DisasterReady (ResQLink)

[![Download Android APK](https://img.shields.io/badge/⬇%20Download%20Android%20APK-Latest%20Release-2ea44f?style=for-the-badge&logo=android&logoColor=white)](https://github.com/aba47/ResQLink/releases/latest/download/app-debug.apk)
[![GitHub Releases](https://img.shields.io/badge/📦%20GitHub%20Releases-Browse%20All-24292e?style=for-the-badge&logo=github&logoColor=white)](https://github.com/aba47/ResQLink/releases)
[![Build and Release APK](https://github.com/aba47/ResQLink/actions/workflows/release_apk.yml/badge.svg)](https://github.com/aba47/ResQLink/actions/workflows/release_apk.yml)
[![Tests Passing](https://img.shields.io/badge/Tests-36%2F36%20Passing-brightgreen?style=for-the-badge)](https://github.com/aba47/ResQLink)

---

### 📥 Direct APK Download

| Option | Link | Description |
| :--- | :--- | :--- |
| **Direct APK** | [**⬇️ Download `app-debug.apk`**](https://github.com/aba47/ResQLink/releases/latest/download/app-debug.apk) | Direct download link for the latest compiled Android APK |
| **All Releases** | [**📦 Browse GitHub Releases**](https://github.com/aba47/ResQLink/releases) | View release notes, changelogs, and previous versions |

#### 📲 How to Install on Android
1. Download **`app-debug.apk`** from the button above on your Android phone or copy it from your PC.
2. Tap the downloaded `.apk` file in your Android notifications or file manager.
3. If prompted with *"Install unknown apps"*, tap **Settings** and enable **"Allow from this source"**.
4. Tap **Install** and open **DisasterReady**!

---

Offline-First Natural Disaster Emergency Assistance and Coordination Android Application.

Designed to operate in disconnected, disaster-affected environments with zero cellular network or internet access, synchronizing with peers over Bluetooth RFCOMM and syncing with emergency central servers whenever internet connectivity is restored.

---

## Key Features

1. **Offline Core & Persistence**:
   - Built on pure SQLite (`sqflite`) across 15 normalized tables.
   - All core emergency services, disaster reports, requests, shelters, hospitals, contacts, and resources function completely offline.
   - Survives process death, restarts, and flight mode.
2. **Disaster Dashboard & Management**:
   - Live disaster feeds with severity and status filtering (Earthquake, Flood, Cyclone, Wildfire, Landslide).
   - Emergency assistance requests with PRD-specified fields (request type, priority, GPS coordinates, people count, description).
   - Responder workflow pipeline: `Requested → Accepted → Team Assigned → In Progress → Completed`.
   - Disaster damage and hazard reporting with offline staging.
   - Facilities catalog: Shelters (with capacity tracking), Hospitals, Helplines, Safe Zones, and Emergency Resources.
3. **2-Way Push/Pull Internet Synchronization**:
   - Resilient background and manual sync engine (`SyncRepository`).
   - Local FastAPI backend with SQLite persistence (`backend/`).
   - Idempotent push/pull with deduplication and conflict resolution.
4. **Peer-to-Peer (P2P) Bluetooth Emergency Sync**:
   - Device A $\leftrightarrow$ Device B direct synchronization over standard protocol envelope.
   - Strict security validation: untrusted remote admin and role escalation claims are stripped, priority claims clamped, responder status changes protected.
   - Staging queue: incoming records are staged and validated before touching primary SQLite tables.
   - Transfer acknowledgements (`ACCEPTED`, `DUPLICATE`, `REJECTED`).
5. **Sync Center**:
   - Real-time queue inspector (Pending, Syncing, Synced, Conflict, Failed).
   - Configurable backend URL.
   - P2P Bluetooth launcher.

---

## Repository Structure

```
d:\APP\ResQLink\
├── android\                    # Android native host project (Manifest, Kotlin bridge)
├── backend\                    # Real local FastAPI sync server
│   ├── database.py             # SQLite backend database schema
│   ├── main.py                 # FastAPI push/pull REST API
│   ├── test_backend.py         # Python unit & integration test suite
│   └── requirements.txt        # Backend dependencies
├── lib\
│   ├── app\                    # Theme and navigation routes
│   ├── core\
│   │   ├── bluetooth\          # P2P Envelope, Validator, Staging, Transport, Service
│   │   ├── connectivity\       # Network status detection & offline mode
│   │   ├── constants\          # App constants, sync statuses, priority levels
│   │   ├── database\           # SQLite DatabaseHelper & 15 table migrations
│   │   ├── network\            # ApiClient for push/pull sync
│   │   └── utils\              # Date and coordinate formatting utilities
│   ├── data\
│   │   ├── local\dao\          # 12 Data Access Objects
│   │   ├── local\models\       # 12 Data Models
│   │   └── repositories\       # Emergency, Disaster, Facilities, and Sync repositories
│   ├── features\
│   │   ├── auth\               # Offline PIN & emergency responder auth
│   │   ├── bluetooth_sync\     # Bluetooth P2P Sync screen & live transfer logs
│   │   ├── dashboard\          # Emergency dashboard
│   │   ├── disasters\          # Disaster feed & details
│   │   ├── emergency_requests\ # Creation, listing, and responder workflow
│   │   ├── facilities\         # Shelters, Hospitals, Helplines, Safe Zones, Resources
│   │   ├── offline_mode\       # Sync Center & offline status banner
│   │   └── reports\            # Disaster damage & hazard reports
│   └── shared\widgets\         # Reusable emergency UI components
├── test\unit\                  # Comprehensive unit & integration test suites (36 tests)
│   ├── bluetooth_p2p_test.dart # Phase 4 P2P protocol, validation, staging & dual-device tests
│   ├── database_helper_test.dart# Phase 1 SQLite schema & migration tests
│   ├── model_test.dart         # Model serialization tests
│   ├── offline_core_test.dart  # Offline lifecycle & restart persistence tests
│   ├── phase2_features_test.dart# Disaster features & responder workflow tests
│   └── sync_integration_test.dart# Phase 3 Internet sync tests (Tests A through G)
├── APK_BUILD.md                # APK build guide & SDK prerequisite documentation
├── BLUETOOTH_TESTING.md        # Physical device dual-phone test protocol
├── KNOWN_LIMITATIONS.md        # Architecture constraints & hardware limitations
└── SETUP.md                    # Environment and server startup instructions
```

---

## Verification Summary

| Suite / Check | Command | Result |
| :--- | :--- | :--- |
| Static Analysis | `flutter analyze` | **PASS (0 issues)** |
| Flutter Test Suite | `flutter test` | **PASS (36/36 tests)** |
| Python Backend Test | `python backend/test_backend.py` | **PASS (4/4 tests)** |
| APK Build | `flutter build apk --debug` | **PASS (`app-debug.apk` built)** |
| Physical Bluetooth Test | 2 Physical Android Phones | **NOT TESTED (Requires 2 physical devices)** |

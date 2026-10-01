# DisasterReady --- Detailed System Architecture

# 1. System Context

``` text
                         ┌──────────────────────────┐
                         │       DISASTERREADY      │
                         │      Android Mobile      │
                         └────────────┬─────────────┘
                                      │
               ┌──────────────────────┼──────────────────────┐
               │                      │                      │
               ▼                      ▼                      ▼
          Local SQLite          Internet API           Bluetooth
               │                      │                      │
               │                      ▼                      ▼
               │                  FastAPI              Nearby Android
               │                      │
               │                      ▼
               │                Server Database
               │
               ▼
          Sync Queue
```

------------------------------------------------------------------------

# 2. Fundamental Design

The application is **offline-first**.

The local database is not merely a cache.

It is the operational data source that allows the application to
function during connectivity loss.

``` text
User
 ↓
UI
 ↓
Use Case
 ↓
Repository
 ↓
SQLite
 ↓
Immediate UI update

Parallel:
Connectivity
 ↓
Sync Engine
 ↓
Internet / Bluetooth
```

------------------------------------------------------------------------

# 3. Three Operating Modes

## Mode A --- Online

``` text
User
 ↓
Android App
 ↓
SQLite
 ↓
Sync Engine
 ↓
FastAPI
 ↓
Server Database
```

## Mode B --- Offline

``` text
User
 ↓
Android App
 ↓
SQLite
 ↓
Local Emergency Data
```

## Mode C --- Offline + Bluetooth

``` text
Phone A
 ↓
SQLite
 ↓
Sync Queue
 ↓
Bluetooth
 ↓
Phone B
 ↓
Validation
 ↓
SQLite
```

------------------------------------------------------------------------

# 4. Layer Architecture

``` text
┌─────────────────────────────────────────┐
│ Presentation                            │
│ Screens / Widgets / State               │
├─────────────────────────────────────────┤
│ Application                             │
│ Use Cases / Business Workflows          │
├─────────────────────────────────────────┤
│ Domain                                  │
│ Models / Rules / Validation             │
├─────────────────────────────────────────┤
│ Data                                    │
│ Repository / SQLite / API / Bluetooth   │
├─────────────────────────────────────────┤
│ Platform                                │
│ Android SDK / Permissions / Storage     │
└─────────────────────────────────────────┘
```

------------------------------------------------------------------------

# 5. Main Components

## 5.1 Presentation

Responsible for:

-   dashboard;
-   forms;
-   lists;
-   status indicators;
-   error states;
-   navigation.

It should not directly execute raw SQL or Bluetooth protocol logic.

------------------------------------------------------------------------

## 5.2 Use Cases

Examples:

``` text
CreateEmergencyRequest
ReportDisaster
GetNearbyShelters
GetEmergencyContacts
SyncPendingData
SendBluetoothData
ReceiveBluetoothData
AcceptEmergencyRequest
UpdateRequestStatus
```

------------------------------------------------------------------------

## 5.3 Repository

Repositories abstract the data source.

Example:

``` text
EmergencyRequestRepository
       │
       ├── Local DAO
       ├── Remote API
       └── Bluetooth Sync
```

The UI should not need to know where the record came from.

------------------------------------------------------------------------

# 6. Local Database

``` text
SQLite
│
├── users
├── disasters
├── emergency_requests
├── disaster_reports
├── shelters
├── hospitals
├── emergency_services
├── resources
├── emergency_contacts
├── safe_zones
├── notifications
├── sync_queue
├── sync_conflicts
├── bluetooth_peers
├── audit_logs
└── app_metadata
```

------------------------------------------------------------------------

# 7. Data Ownership

For offline operation:

``` text
SQLite = local operational state
```

For synchronization:

``` text
Backend = shared/server state
```

For Bluetooth:

``` text
Bluetooth = transport
```

Bluetooth itself must never become the database.

------------------------------------------------------------------------

# 8. Sync Engine

``` text
              ┌─────────────┐
              │ Sync Engine │
              └──────┬──────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
      SQLite       Internet    Bluetooth
```

Responsibilities:

-   detect pending changes;
-   serialize;
-   validate;
-   send;
-   receive;
-   acknowledge;
-   retry;
-   detect duplicates;
-   record conflicts;
-   update sync status.

------------------------------------------------------------------------

# 9. Emergency Request Lifecycle

``` text
Citizen
 ↓
Request Form
 ↓
Local Validation
 ↓
SQLite
 ↓
PENDING
 ↓
 ┌───────────────┐
 │               │
Internet       Bluetooth
 │               │
 ↓               ↓
Backend        Nearby Device
 │               │
 └───────┬───────┘
         ↓
      SYNCED
```

------------------------------------------------------------------------

# 10. Bluetooth Protocol

``` text
DEVICE A                         DEVICE B

Discovery --------------------->

<-------------------- Discovery Response

Connect ----------------------->

<-------------------------- Connect ACK

Handshake --------------------->

<------------------------- Handshake ACK

Record ------------------------>

<-------------------------- Record ACK

Next Record ------------------->

<-------------------------- Record ACK

Complete ---------------------->

<---------------------- Complete ACK
```

------------------------------------------------------------------------

# 11. Bluetooth Data Staging

Never directly insert untrusted Bluetooth data into the primary tables.

Required:

``` text
Bluetooth Packet
      ↓
Parse
      ↓
Validate
      ↓
Check Duplicate
      ↓
Staging / Sync Queue
      ↓
Business Validation
      ↓
SQLite
```

------------------------------------------------------------------------

# 12. Bluetooth MVP Boundary

MVP:

``` text
A ↔ B
```

Future:

``` text
A ↔ B ↔ C ↔ D
```

Do not implement multi-hop mesh until direct synchronization is
reliable.

------------------------------------------------------------------------

# 13. Connectivity State Machine

``` text
              ┌─────────┐
              │ ONLINE  │
              └────┬────┘
                   │
              network lost
                   ↓
              ┌─────────┐
              │ OFFLINE │
              └────┬────┘
                   │
             Bluetooth ready
                   ↓
        ┌─────────────────────┐
        │ OFFLINE + BLUETOOTH │
        └──────────┬──────────┘
                   │
             network restored
                   ↓
              ┌─────────┐
              │ SYNCING │
              └────┬────┘
                   ↓
                ONLINE
```

------------------------------------------------------------------------

# 14. Screen Architecture

``` text
Splash
 ↓
Authentication
 ↓
Dashboard
 ├── Disaster
 ├── Request Help
 ├── Report Incident
 ├── Shelters
 ├── Hospitals
 ├── Emergency Contacts
 ├── Resources
 ├── Safe Zones
 └── Sync Center

Responder
 ├── Requests
 ├── Request Detail
 ├── Assign
 └── Status

Admin
 ├── Disasters
 ├── Shelters
 ├── Resources
 ├── Services
 └── Audit/Sync
```

------------------------------------------------------------------------

# 15. Offline UX

Persistent status should communicate:

``` text
🟢 ONLINE
🟠 OFFLINE
🔵 BLUETOOTH READY
🟣 SYNCING
🔴 SYNC ERROR
```

When offline, the UI must not show a generic "server unavailable"
experience for screens that can work locally.

------------------------------------------------------------------------

# 16. Failure Architecture

## Internet unavailable

Use SQLite.

## Backend unavailable

Keep queue.

## Bluetooth unavailable

Keep queue.

## Bluetooth interrupted

Retry.

## Duplicate packet

Ignore safely.

## Invalid packet

Reject.

## App restart

Reload SQLite.

## Partial sync

Preserve remaining queue entries.

------------------------------------------------------------------------

# 17. Deployment

## Development

``` text
Laptop
 ├── Flutter
 └── Optional FastAPI

Android Device
 └── DisasterReady APK
```

## Disaster Demonstration

``` text
Phone A ──Bluetooth── Phone B
   │                     │
 SQLite                SQLite
```

## Final APK

``` text
Flutter Source
     ↓
Release Build
     ↓
DisasterReady.apk
```

------------------------------------------------------------------------

# 18. Future Architecture

Only after MVP stability:

-   multi-hop Bluetooth relay;
-   mesh discovery;
-   advanced maps;
-   public alert integration;
-   richer analytics;
-   optional cloud deployment;
-   advanced conflict resolution.

These are explicitly outside the first implementation.

# DisasterReady --- Technical Requirements Document (TRD)

# 1. Technical Objective

Build a real Android application using an offline-first architecture.

Recommended stack:

-   Flutter
-   Dart
-   Android SDK
-   Kotlin native bridge where Bluetooth/native Android capabilities
    require it
-   SQLite local database
-   FastAPI optional local backend
-   REST/JSON
-   Git/GitHub
-   Android APK build

The application must not depend on a cloud service for core offline
functionality.

------------------------------------------------------------------------

# 2. Architecture Principles

## 2.1 Local First

The UI should primarily read from local data.

Bad:

``` text
Open screen
 ↓
Wait for internet
 ↓
API
 ↓
Show screen
```

Required:

``` text
Open screen
 ↓
SQLite
 ↓
Show available data
 ↓
Synchronize in background when possible
```

------------------------------------------------------------------------

# 3. Layered Architecture

``` text
Presentation Layer
       ↓
Application / Use Cases
       ↓
Repository Layer
       ↓
Data Sources
 ┌─────┼─────┐
 ↓     ↓     ↓
SQLite API Bluetooth
```

The repository must hide data-source complexity from UI components.

------------------------------------------------------------------------

# 4. Flutter Project Structure

Recommended:

``` text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── connectivity/
│   ├── security/
│   ├── bluetooth/
│   ├── database/
│   └── utils/
│
├── data/
│   ├── local/
│   │   ├── database/
│   │   ├── dao/
│   │   └── models/
│   ├── remote/
│   │   ├── api_client.dart
│   │   └── dto/
│   └── repositories/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── disasters/
│   ├── emergency_requests/
│   ├── reports/
│   ├── shelters/
│   ├── hospitals/
│   ├── resources/
│   ├── emergency_contacts/
│   ├── safe_zones/
│   ├── offline_mode/
│   ├── bluetooth_sync/
│   └── admin/
│
└── shared/
    ├── widgets/
    ├── models/
    └── extensions/
```

Do not create every directory automatically if it is not required.

------------------------------------------------------------------------

# 5. Local Database

SQLite tables:

``` text
users
disasters
emergency_requests
disaster_reports
shelters
hospitals
emergency_services
resources
emergency_contacts
safe_zones
notifications
sync_queue
sync_conflicts
bluetooth_peers
audit_logs
app_metadata
```

------------------------------------------------------------------------

# 6. Common Synchronization Fields

Sync-enabled tables should normally contain:

``` text
id
created_at
updated_at
version
source_device_id
sync_status
is_deleted
```

Do not blindly add fields to an existing database without inspecting the
current schema.

------------------------------------------------------------------------

# 7. Sync Queue

Schema concept:

``` text
sync_queue
---------------------------
id
entity_type
entity_id
operation
payload
version
source_device_id
created_at
retry_count
last_error
status
```

Statuses:

``` text
PENDING
SYNCING
SYNCED
FAILED
CONFLICT
```

------------------------------------------------------------------------

# 8. Sync Operations

Supported operations:

``` text
CREATE
UPDATE
DELETE
```

Every local write that needs future synchronization should create an
appropriate queue record.

------------------------------------------------------------------------

# 9. Sync Algorithm

Pseudo-flow:

``` text
Start Sync
    ↓
Read PENDING queue records
    ↓
Validate record
    ↓
Send to backend / Bluetooth
    ↓
Receive acknowledgement
    ↓
Mark SYNCED
```

If failed:

``` text
FAILED
 ↓
increment retry_count
 ↓
store last_error
 ↓
remain retryable
```

Never delete a failed operation merely because synchronization failed.

------------------------------------------------------------------------

# 10. Conflict Handling

MVP strategy:

1.  Compare entity ID.
2.  Compare version.
3.  Compare updated timestamp.
4.  Select the newer valid version according to documented rules.
5.  Record conflict metadata when both sides changed.
6.  Do not silently discard important emergency information.

Emergency requests should receive special treatment where status changes
conflict.

------------------------------------------------------------------------

# 11. Internet Connectivity

Implement a centralized connectivity service.

States:

``` text
ONLINE
OFFLINE
SYNCING
SYNC_ERROR
BLUETOOTH_AVAILABLE
```

Do not scatter connectivity checks throughout the UI.

------------------------------------------------------------------------

# 12. Backend

If an existing backend is present:

-   inspect it first;
-   use existing routes/models;
-   do not replace it;
-   do not invent endpoints.

If no backend exists:

Recommended:

``` text
FastAPI
   ↓
SQLite for local development
```

PostgreSQL can be an optional later deployment database.

------------------------------------------------------------------------

# 13. API

Potential endpoints:

``` text
POST /auth/register
POST /auth/login

GET /disasters
POST /disasters
PATCH /disasters/{id}

GET /emergency-requests
POST /emergency-requests
PATCH /emergency-requests/{id}

GET /shelters
POST /shelters
PATCH /shelters/{id}

GET /hospitals

GET /resources
POST /resources
PATCH /resources/{id}

GET /emergency-contacts

POST /sync/push
POST /sync/pull
```

These are architectural examples, NOT permission to assume these
endpoints exist.

------------------------------------------------------------------------

# 14. API Configuration

Never hardcode an environment-specific server address throughout the
application.

Use configuration:

``` text
Development
Local Backend
Test
Production
```

Android emulator and physical-device networking may require different
host configuration.

Document the exact configuration.

------------------------------------------------------------------------

# 15. Bluetooth Architecture

MVP:

``` text
Device A
   ↕
Bluetooth
   ↕
Device B
```

No mesh.

------------------------------------------------------------------------

# 16. Bluetooth Application Protocol

Example envelope:

``` json
{
  "protocolVersion": 1,
  "messageId": "uuid",
  "deviceId": "device-id",
  "timestamp": "ISO-8601",
  "entityType": "emergency_request",
  "operation": "upsert",
  "version": 3,
  "payload": {}
}
```

The exact serialization may be JSON or another appropriate format, but
it must be versioned and validated.

------------------------------------------------------------------------

# 17. Bluetooth Handshake

Expected flow:

``` text
Discover
 ↓
Connect
 ↓
Handshake
 ↓
Validate protocol version
 ↓
Exchange device/session information
 ↓
Transfer records
 ↓
Validate records
 ↓
ACK
 ↓
Commit
```

Received data should be staged before final database insertion.

------------------------------------------------------------------------

# 18. Bluetooth Security

Treat every received packet as untrusted.

Validate:

-   protocol version;
-   message ID;
-   entity type;
-   operation;
-   ID;
-   timestamps;
-   payload structure;
-   version;
-   allowed record types;
-   payload size.

Never trust remote claims such as:

``` text
role = ADMIN
priority = CRITICAL
status = APPROVED
```

without local/server validation rules.

------------------------------------------------------------------------

# 19. Bluetooth Duplicate Prevention

Use:

-   message ID;
-   entity ID;
-   version;
-   source device ID.

A repeated message must not create another copy of the same logical
record.

------------------------------------------------------------------------

# 20. Bluetooth Failure Handling

Cases:

-   Bluetooth disabled;
-   permission denied;
-   device unavailable;
-   connection lost;
-   malformed packet;
-   duplicate packet;
-   transfer interrupted;
-   receiver rejects data;
-   sender times out.

The application must show an understandable status and preserve
retryable data.

------------------------------------------------------------------------

# 21. Native Android Integration

If Flutter packages cannot provide the required Bluetooth behavior:

-   inspect Android SDK capabilities;
-   use Kotlin/native Android integration;
-   expose only the required bridge to Flutter;
-   keep Bluetooth logic isolated.

Do not create an invented API.

------------------------------------------------------------------------

# 22. Permissions

Request only permissions required by the actual implementation and
target Android version.

Permission flow must:

-   explain the reason;
-   handle denial;
-   handle permanent denial;
-   provide retry/settings guidance where appropriate;
-   never crash when permission is unavailable.

------------------------------------------------------------------------

# 23. Security

## Authentication

-   server-side password hashing;
-   secure token storage;
-   token expiration;
-   role checks.

## Local

-   minimize sensitive data;
-   avoid plaintext credentials;
-   avoid sensitive logging.

## Network

-   HTTPS outside local development;
-   validate responses;
-   handle expired sessions.

------------------------------------------------------------------------

# 24. Error Handling

Every feature should have:

-   loading;
-   success;
-   empty;
-   error;
-   retry.

Offline error example:

``` text
Internet is unavailable.
Your emergency request has been saved locally.
It will be synchronized when a connection becomes available.
```

------------------------------------------------------------------------

# 25. Testing Strategy

## Unit

Test:

-   models;
-   validators;
-   repositories;
-   database;
-   sync queue;
-   conflict logic.

## Widget

Test:

-   dashboard;
-   request form;
-   offline indicator;
-   sync center;
-   Bluetooth screen.

## Integration

Test:

-   offline create;
-   restart persistence;
-   API synchronization;
-   duplicate prevention;
-   Bluetooth transfer;
-   interrupted transfer.

## Physical Device

Bluetooth MUST be tested on at least two physical Android devices before
being declared complete.

------------------------------------------------------------------------

# 26. Build Verification

Run:

``` bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

A release build must be installed on a physical Android device.

------------------------------------------------------------------------

# 27. Definition of Done

A task is not DONE because:

-   code was generated;
-   a screen exists;
-   a button exists;
-   a mock response works;
-   an emulator screenshot looks correct.

A task is DONE only when:

``` text
Requirement
    ↓
Implementation
    ↓
Build
    ↓
Test
    ↓
Failure Test
    ↓
Fix
    ↓
Retest
    ↓
Requirement Verification
    ↓
DONE
```

------------------------------------------------------------------------

# 28. Engineering Constraints

-   Inspect before modifying.
-   Reuse existing work.
-   Do not hallucinate missing APIs.
-   Do not silently invent requirements.
-   Do not delete unrelated work.
-   Do not introduce unnecessary dependencies.
-   Keep changes focused.
-   Keep project buildable after each phase.
-   Document assumptions.
-   Never claim testing that was not performed.

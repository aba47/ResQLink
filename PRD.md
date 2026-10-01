# DisasterReady --- Product Requirements Document (PRD)

## Document Control

  -----------------------------------------------------------------------
  Item                                Value
  ----------------------------------- -----------------------------------
  Product                             DisasterReady

  Type                                Native Android Mobile Application

  Primary Platform                    Android

  Architecture                        Offline-First

  Core Database                       Local SQLite

  Optional Backend                    Local FastAPI

  Alternative Transport               Bluetooth Device-to-Device

  Deployment                          APK

  Primary Goal                        Natural-disaster emergency
                                      information, assistance and
                                      resource coordination

  Cloud Dependency                    Not required for core operation
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 1. Product Vision

DisasterReady is an offline-first Android application designed to help
people and emergency response teams operate during natural disasters
when normal internet connectivity may be unreliable or unavailable.

The application must continue to provide useful emergency functionality
using data stored locally on the Android device.

When internet connectivity is available, the application can synchronize
local changes with a backend.

When internet connectivity is unavailable but nearby Android devices are
available, the application can transfer selected emergency data directly
between devices using Bluetooth.

The application is therefore designed around three operating conditions:

1.  Normal online operation.
2.  Offline local operation.
3.  Offline + Bluetooth emergency data exchange.

The project must be a real Android application and must not be
implemented as a website, PWA, browser application, or WebView wrapper.

------------------------------------------------------------------------

# 2. Real-World Problem

Natural disasters such as floods, earthquakes, cyclones, landslides,
forest fires and extreme rainfall can disrupt communication,
transportation, healthcare and essential services.

During such situations:

-   people may not know where shelters are located;
-   people may not know where hospitals or emergency services are
    available;
-   rescue requests may be difficult to coordinate;
-   emergency resources may not be visible centrally;
-   communication infrastructure may fail;
-   previously available online information may become inaccessible;
-   responders may receive incomplete or duplicated information;
-   local emergency information may become stale.

DisasterReady addresses these problems through local-first storage,
emergency workflows, resource/shelter information, synchronization and
nearby-device data exchange.

------------------------------------------------------------------------

# 3. Product Goals

## 3.1 Primary Goals

The system shall:

1.  Run as an Android application.
2.  Work without internet for core emergency features.
3.  Store critical information locally.
4.  Allow users to create emergency requests offline.
5.  Allow users to report disaster incidents offline.
6.  Provide offline access to emergency contacts.
7.  Provide offline access to shelters.
8.  Provide offline access to hospitals/emergency services.
9.  Provide offline access to safe-zone information.
10. Provide offline access to previously synchronized disaster
    information.
11. Maintain a synchronization queue for unsynchronized changes.
12. Synchronize data when connectivity becomes available.
13. Transfer selected emergency information between nearby Android
    devices using Bluetooth.
14. Validate received Bluetooth data before storing it.
15. Prevent duplicate records.
16. Preserve pending data across application restarts.
17. Provide responder/admin workflows.
18. Produce a working APK.
19. Be demonstrable locally without permanent cloud infrastructure.

------------------------------------------------------------------------

# 4. Secondary Goals

The system should:

-   clearly show whether it is online or offline;
-   show the freshness of stored information;
-   show last synchronization time;
-   provide retry controls;
-   provide transfer status;
-   record synchronization errors;
-   make critical actions accessible with minimal navigation;
-   use a consistent emergency-oriented UI;
-   remain understandable for a college project demonstration.

------------------------------------------------------------------------

# 5. Non-Goals

The MVP will NOT attempt to:

-   replace official government disaster warning systems;
-   guarantee physical rescue;
-   provide satellite communication;
-   automatically control rescue vehicles;
-   provide autonomous emergency decisions;
-   guarantee that every Bluetooth device can communicate with every
    other device;
-   implement a nationwide emergency network;
-   implement advanced AI disaster prediction;
-   implement automatic multi-hop Bluetooth mesh routing;
-   depend on a permanent cloud server;
-   become a web application.

Multi-hop Bluetooth mesh may be considered a future enhancement after
direct Bluetooth synchronization is stable.

------------------------------------------------------------------------

# 6. Target Users

## 6.1 Citizen

A person affected by a disaster.

Capabilities:

-   view disaster alerts;
-   view disaster information;
-   request rescue/help;
-   report affected locations;
-   find shelters;
-   find hospitals;
-   find emergency services;
-   view emergency contacts;
-   view safe zones;
-   view resource information;
-   use offline mode.

## 6.2 Responder

A member of an emergency response team.

Capabilities:

-   view emergency requests;
-   inspect request details;
-   accept requests;
-   assign response teams;
-   update status;
-   view affected areas;
-   coordinate resources;
-   complete requests.

## 6.3 Administrator

Responsible for managing system information.

Capabilities:

-   manage disaster incidents;
-   manage shelters;
-   manage hospitals/services;
-   manage emergency resources;
-   manage emergency contacts;
-   publish/update critical information;
-   monitor synchronization;
-   review audit records.

------------------------------------------------------------------------

# 7. Core Functional Requirements

## FR-001 Application Startup

The application shall:

-   launch on Android;
-   initialize local storage;
-   determine current connectivity;
-   load locally available critical data;
-   display the dashboard without requiring internet.

If the network is unavailable, startup must not fail solely because an
API cannot be reached.

------------------------------------------------------------------------

## FR-002 Authentication/Profile

The system shall support:

-   registration;
-   login;
-   user profile;
-   role information;
-   session handling.

Previously authenticated local information may be retained according to
the security design.

Authentication must not be implemented by storing plaintext passwords
locally.

------------------------------------------------------------------------

# 8. Dashboard

The dashboard shall display:

-   active disaster;
-   disaster type;
-   severity;
-   affected area;
-   last update;
-   online/offline status;
-   Bluetooth availability;
-   pending synchronization count.

Primary actions:

-   Request Help;
-   Report Incident;
-   Find Shelter;
-   Find Hospital;
-   Emergency Contacts;
-   Resources;
-   Safe Zones;
-   Offline/Sync Center.

------------------------------------------------------------------------

# 9. Disaster Management

A disaster record shall contain:

-   disaster ID;
-   type;
-   location;
-   affected area;
-   severity;
-   start time;
-   end time if known;
-   description;
-   instructions;
-   status;
-   created time;
-   updated time.

Supported disaster categories may include:

-   Flood;
-   Earthquake;
-   Cyclone;
-   Landslide;
-   Forest Fire;
-   Heavy Rainfall;
-   Tsunami;
-   Extreme Weather;
-   Other.

------------------------------------------------------------------------

# 10. Emergency Request

The user shall be able to create a request containing:

-   request ID;
-   requester;
-   location;
-   disaster type;
-   people affected;
-   children count;
-   elderly count;
-   medical emergency;
-   assistance type;
-   description;
-   priority;
-   timestamp.

Priority:

-   Low;
-   Medium;
-   High;
-   Critical.

Workflow:

``` text
Requested
   ↓
Accepted
   ↓
Team Assigned
   ↓
In Progress
   ↓
Completed
```

A request created while offline must be saved locally immediately.

The user must receive clear confirmation that the request is stored
locally and waiting for synchronization/transfer.

------------------------------------------------------------------------

# 11. Disaster Report

Users shall be able to report:

-   flooding;
-   fire;
-   landslide;
-   damaged road;
-   infrastructure damage;
-   blocked route;
-   medical emergency;
-   other disaster observation.

The report shall be stored locally first.

------------------------------------------------------------------------

# 12. Shelter Management

Shelter fields:

-   name;
-   location;
-   capacity;
-   occupied;
-   available capacity;
-   food availability;
-   water availability;
-   medical availability;
-   contact;
-   last updated.

The application shall clearly distinguish current information from stale
information.

------------------------------------------------------------------------

# 13. Hospital and Emergency Services

Store:

-   hospital name;
-   location;
-   contact;
-   services;
-   availability where known.

Also support:

-   police stations;
-   fire stations;
-   relief centers;
-   emergency services.

------------------------------------------------------------------------

# 14. Emergency Resources

Supported resources:

-   food;
-   water;
-   medicines;
-   blankets;
-   clothing;
-   rescue equipment;
-   medical kits;
-   vehicles;
-   boats;
-   other emergency resources.

Each resource should support:

-   available quantity;
-   required quantity;
-   reserved quantity;
-   unit;
-   location;
-   last updated.

------------------------------------------------------------------------

# 15. Emergency Contacts

The application shall provide emergency contacts that remain accessible
offline.

The data should be locally cached/synchronized before the disaster where
possible.

------------------------------------------------------------------------

# 16. Safe Zones

The application shall display locally available safe-zone information.

A safe-zone record may contain:

-   name;
-   location;
-   description;
-   capacity if applicable;
-   last updated.

------------------------------------------------------------------------

# 17. Offline Mode

Offline mode is not a separate application.

It is the same application operating primarily from local storage.

When internet is unavailable:

-   dashboard remains usable;
-   cached disaster information remains accessible;
-   shelters remain accessible;
-   hospitals remain accessible;
-   emergency contacts remain accessible;
-   safe zones remain accessible;
-   local emergency requests can be created;
-   local disaster reports can be created;
-   synchronization queue continues storing pending operations;
-   Bluetooth synchronization may be used when available.

------------------------------------------------------------------------

# 18. Bluetooth Emergency Transfer

The MVP shall support direct:

``` text
Android Device A
       ↕
   Bluetooth
       ↕
Android Device B
```

The system shall exchange only supported emergency data.

Supported initial records:

-   emergency requests;
-   disaster reports;
-   critical alerts;
-   shelter information;
-   emergency contacts;
-   safe zones;
-   resource summaries.

The system shall not blindly copy the complete database.

Each transferred record must have enough metadata to identify:

-   message;
-   record;
-   type;
-   version;
-   source device;
-   timestamp;
-   operation.

------------------------------------------------------------------------

# 19. Bluetooth Requirements

The system shall:

-   detect Bluetooth availability;
-   handle Android permissions;
-   detect Bluetooth disabled state;
-   discover nearby compatible devices;
-   establish a connection;
-   perform a protocol handshake;
-   transfer data;
-   acknowledge successful transfer;
-   detect duplicate messages;
-   validate incoming data;
-   store received data safely;
-   retry interrupted transfers where practical;
-   show transfer progress;
-   show transfer errors.

The system must not claim Bluetooth support without physical-device
testing.

------------------------------------------------------------------------

# 20. Synchronization

There are two synchronization paths.

## Internet

``` text
SQLite
  ↓
Sync Queue
  ↓
REST API
  ↓
Backend
```

## Bluetooth

``` text
Device A SQLite
  ↓
Sync Queue
  ↓
Bluetooth
  ↓
Device B staging queue
  ↓
Validation
  ↓
Device B SQLite
```

------------------------------------------------------------------------

# 21. Data Freshness

The UI should show:

-   Last updated;
-   Last synchronized;
-   Pending synchronization;
-   Stale/offline indication where applicable.

The application must never present old information as definitely
current.

------------------------------------------------------------------------

# 22. Local Backup

Critical local application information shall be protected from normal
app restarts.

The MVP should preserve:

-   pending emergency requests;
-   disaster reports;
-   cached critical information;
-   sync queue;
-   synchronization metadata.

A local backup/restore mechanism can be included where practical.

------------------------------------------------------------------------

# 23. Notifications

The system may display:

-   new disaster information;
-   important local alerts;
-   synchronization completion;
-   synchronization failure;
-   Bluetooth transfer completion.

Notification functionality must not become a dependency for core offline
operation.

------------------------------------------------------------------------

# 24. Security Requirements

The system shall:

-   avoid plaintext passwords;
-   protect authentication tokens;
-   validate all input;
-   validate Bluetooth data;
-   prevent unauthorized admin operations;
-   avoid sensitive debug logs;
-   use HTTPS for remote API communication;
-   reject malformed synchronization payloads;
-   prevent duplicate imports.

Bluetooth is an untrusted transport.

------------------------------------------------------------------------

# 25. Reliability Requirements

The system shall:

-   survive normal app restarts;
-   preserve offline-created data;
-   retry failed synchronization;
-   avoid duplicate records;
-   handle interrupted Bluetooth transfers;
-   handle backend unavailability;
-   handle Bluetooth being disabled;
-   handle permissions being denied;
-   show useful errors instead of crashing.

------------------------------------------------------------------------

# 26. APK Requirements

Required outputs:

-   debug APK;
-   release APK;
-   installation instructions.

The final APK must be installable on a compatible physical Android
device.

------------------------------------------------------------------------

# 27. MVP Definition

MVP is complete only when all of the following work:

-   Android app launches;
-   SQLite works;
-   dashboard works offline;
-   emergency request works offline;
-   disaster report works offline;
-   shelter/hospital/contact data can be viewed offline;
-   sync queue works;
-   local data survives restart;
-   local backend sync works if backend is implemented;
-   direct Bluetooth transfer works on physical Android devices;
-   duplicate prevention works;
-   release APK builds.

------------------------------------------------------------------------

# 28. Acceptance Criteria

A feature is NOT considered complete because code exists.

A feature is complete only when:

1.  It matches the documented requirement.
2.  It builds.
3.  It has no known blocking error.
4.  It has been tested.
5.  Failure conditions are handled.
6.  Data persists correctly.
7.  UI reflects the actual state.
8.  No fake/mock behavior remains where real functionality is required.
9.  The implementation is documented.
10. The final result can be demonstrated.

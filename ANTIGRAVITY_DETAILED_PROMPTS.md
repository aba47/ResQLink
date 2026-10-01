# DisasterReady --- Antigravity Detailed Implementation Prompt Pack

# 0. HOW TO USE THIS DOCUMENT

These prompts are designed for Antigravity/AI coding agents.

DO NOT paste all phases at once.

Execute:

``` text
PHASE 0 → PHASE 1 → PHASE 2 → PHASE 3 → PHASE 4 → PHASE 5
```

After each phase:

1.  Run the requested checks.
2.  Inspect errors.
3.  Fix errors.
4.  Run the checks again.
5.  Verify the actual requirement.
6.  Only then move to the next phase.

The agent must NOT treat generated code as proof that a feature works.

------------------------------------------------------------------------

# 1. GLOBAL ANTI-HALLUCINATION RULES

These rules apply to EVERY phase.

``` text
CRITICAL RULE — DO NOT HALLUCINATE

Never invent:
- files
- folders
- APIs
- backend routes
- database tables
- dependencies
- credentials
- environment variables
- existing features
- test results
- device capabilities
- successful integrations

If something is unknown:
1. Inspect the repository.
2. Search the codebase.
3. Inspect configuration.
4. Inspect dependency files.
5. Inspect backend routes if a backend exists.
6. Only then make a decision.

If information is still unavailable:
- state the assumption;
- keep the assumption minimal;
- do not pretend it already exists.

Never say "implemented successfully" merely because code was generated.
```

------------------------------------------------------------------------

# 2. GLOBAL "DO NOT BREAK EXISTING WORK" RULE

Before changing anything:

``` text
1. Inspect repository tree.
2. Identify application entry point.
3. Identify existing modules.
4. Identify existing database.
5. Identify existing backend.
6. Identify current dependencies.
7. Identify current build configuration.
8. Identify existing tests.
```

Then create a change plan.

Do NOT:

-   delete unrelated code;
-   rewrite working modules;
-   replace the project architecture without evidence;
-   change another contributor's work;
-   remove dependencies that existing modules need;
-   rename large groups of files without necessity.

If a file must be changed, explain why internally before changing it.

------------------------------------------------------------------------

# 3. GLOBAL REQUIREMENT TRACEABILITY

Every phase must maintain this loop:

``` text
Requirement
   ↓
Implementation
   ↓
Build
   ↓
Automated Test
   ↓
Manual/Device Test where required
   ↓
Failure Test
   ↓
Fix
   ↓
Retest
   ↓
Requirement Verification
   ↓
PASS
```

A requirement is NOT complete until it reaches PASS.

------------------------------------------------------------------------

# 4. GLOBAL VERIFICATION LOOP

Use this exact mental/engineering loop for each task:

``` text
WHILE requirement_is_not_verified:

    inspect current state

    implement smallest required change

    run analyzer/build/tests

    IF failure:
        identify root cause
        fix root cause
        run same test again

    IF test passes:
        run relevant failure/edge-case test

    IF edge-case fails:
        fix
        repeat

    compare implementation against PRD/TRD

    IF requirement is satisfied:
        mark PASS
    ELSE:
        continue loop
```

DO NOT stop after the first successful compilation.

Compilation != requirement completion.

------------------------------------------------------------------------

# 5. GLOBAL STOP CONDITIONS

STOP the current phase and report the blocker if:

-   repository access is missing;
-   a required external credential is unavailable;
-   physical-device testing is required but impossible;
-   an existing backend contract is ambiguous;
-   an API is unavailable and cannot be verified;
-   a dependency is incompatible;
-   continuing would require inventing information.

When stopped:

``` text
Do not fake the result.
Do not mark the task complete.
Clearly report:
- blocker
- evidence
- what was attempted
- what information/device/access is required
```

------------------------------------------------------------------------

# 6. GLOBAL TESTING RULE

Never claim:

``` text
Bluetooth tested
API integrated
offline sync verified
APK tested
```

unless the actual test was performed.

Use:

``` text
NOT TESTED
```

when it has not been tested.

------------------------------------------------------------------------

# 7. GLOBAL DEPENDENCY RULE

Before adding a package:

1.  Check whether an existing dependency already provides the feature.
2.  Check compatibility with current Flutter/Android configuration.
3.  Add only if necessary.
4.  Explain why it is necessary in the final report.
5.  Run dependency/build tests afterward.

Avoid dependency bloat.

------------------------------------------------------------------------

# 8. GLOBAL UI RULE

Do not create fake buttons.

A button must either:

-   perform the actual implemented action;
-   or be explicitly marked as unavailable/not implemented.

Do not create placeholder functionality and call it complete.

------------------------------------------------------------------------

# 9. GLOBAL DATA RULE

Never use fake/mock data as proof of backend integration.

Mock data may be used only for:

-   UI development;
-   isolated testing;
-   clearly labelled demo mode.

Production feature flows must use the actual configured data source.

------------------------------------------------------------------------

# PHASE 0 --- REPOSITORY AUDIT

## Prompt

``` text
You are starting work on DisasterReady.

DO NOT MODIFY CODE YET.

Your first task is repository discovery.

Inspect:
- complete directory tree;
- Flutter configuration;
- Android configuration;
- pubspec.yaml;
- existing Dart source;
- existing Kotlin source;
- existing backend;
- database files;
- environment files;
- README;
- tests;
- build scripts;
- Git status.

Determine:
1. Is this already a Flutter project?
2. Is Android configured?
3. Is a backend present?
4. Is a database present?
5. What modules already exist?
6. What dependencies are already installed?
7. What parts of DisasterReady already exist?
8. What must be preserved?
9. What is missing?

DO NOT:
- create files;
- install packages;
- rewrite architecture;
- modify source code.

OUTPUT:
Create a concise audit report containing:
- current architecture;
- existing files;
- existing features;
- missing features;
- risks;
- recommended implementation order.

If something cannot be verified, write UNKNOWN rather than guessing.

STOP after the audit.
```

------------------------------------------------------------------------

# PHASE 1 --- ANDROID FOUNDATION + SQLITE + OFFLINE CORE

## Prompt

``` text
Continue DisasterReady after completing the repository audit.

Read:
- PRD.md
- TRD.md
- ARCHITECTURE.md
- repository audit.

GOAL:
Create/complete the real Android application foundation.

PRIMARY REQUIREMENT:
The app must run without internet for core functionality.

IMPLEMENT:

1. Flutter Android application foundation.
2. DisasterReady branding.
3. Application theme.
4. Navigation.
5. Splash.
6. Authentication shell if not already present.
7. Dashboard shell.
8. SQLite local database.
9. Database version/migration mechanism.
10. Repository layer.
11. Connectivity service.
12. Online/offline indicator.
13. Basic local models.

Models:
- user
- disaster
- emergency request
- disaster report
- shelter
- hospital
- emergency service
- resource
- emergency contact
- safe zone
- sync queue

CRITICAL:
Do not implement models differently from the existing repository unless necessary.
Do not destroy an existing schema.

OFFLINE TEST:
1. Disable internet.
2. Start app.
3. Dashboard must open.
4. Local database must initialize.
5. Create local test data.
6. Restart app.
7. Data must remain available.

VERIFICATION LOOP:
If any test fails:
- inspect error;
- identify root cause;
- fix;
- rerun;
- repeat until PASS.

Run:
flutter analyze
flutter test
flutter build apk --debug

Do not proceed if build fails.

FINAL REPORT:
- changed files;
- packages added;
- tests;
- failures fixed;
- final build result;
- unverified items.
```

------------------------------------------------------------------------

# PHASE 2 --- COMPLETE DISASTER FEATURES

## Prompt

``` text
Continue DisasterReady.

Read:
- PRD.md
- TRD.md
- ARCHITECTURE.md
- existing implementation.

GOAL:
Implement actual emergency-management features on top of the working offline foundation.

IMPLEMENT:

1. Disaster dashboard.
2. Disaster detail.
3. Emergency request.
4. Disaster report.
5. Shelter management/view.
6. Hospital information.
7. Emergency services.
8. Emergency contacts.
9. Safe zones.
10. Resource management.
11. Responder request workflow.
12. Offline/Sync Center.

EMERGENCY REQUEST:
Fields required by PRD.

Workflow:
Requested
→ Accepted
→ Team Assigned
→ In Progress
→ Completed

OFFLINE RULE:
When internet is unavailable:
Create Request
→ Validate
→ SQLite
→ Sync Queue
→ UI confirmation

The request must survive:
- screen navigation;
- app restart;
- temporary connectivity loss.

DISASTER REPORT:
Must also work offline.

SHELTER:
Display capacity and availability.

RESOURCE:
Display available/required/reserved.

SYNC CENTER:
Display:
- pending;
- synced;
- failed;
- retry;
- last sync.

DO NOT:
- fake synchronization;
- create dead buttons;
- invent backend endpoints;
- mark features complete without tests.

TEST EACH FEATURE.

MANDATORY TEST LOOP:
For each feature:

1. Normal case.
2. Empty case.
3. Invalid input.
4. Offline case.
5. Restart persistence where applicable.
6. Error case.
7. Verify against PRD.

Repeat fixes until all relevant tests PASS.

Then run:
flutter analyze
flutter test
flutter build apk --debug

STOP if any blocking issue remains.
```

------------------------------------------------------------------------

# PHASE 3 --- REAL LOCAL BACKEND + INTERNET SYNC

## Prompt

``` text
Continue DisasterReady.

IMPORTANT:
First inspect whether a backend already exists.

IF BACKEND EXISTS:
- inspect its actual routes;
- inspect schemas;
- inspect authentication;
- inspect database;
- use the existing contract.

IF BACKEND DOES NOT EXIST:
- create the minimum FastAPI backend described in TRD;
- do not create unnecessary services.

NEVER INVENT AN API.

GOAL:
Implement real synchronization between:
Flutter SQLite ↔ Backend.

IMPLEMENT:

1. API client.
2. Configurable base URL.
3. Authentication integration if supported.
4. Push sync.
5. Pull sync.
6. Sync acknowledgements.
7. Retry.
8. Failure storage.
9. Duplicate prevention.
10. Basic conflict handling.
11. Sync Center integration.

TEST:

TEST A:
Online:
Create emergency request
→ API
→ backend
→ confirmation.

TEST B:
Offline:
Create request
→ SQLite
→ PENDING.

TEST C:
Restart:
Request still exists.

TEST D:
Backend unavailable:
App remains usable.

TEST E:
Connection restored:
PENDING
→ API
→ SYNCED.

TEST F:
Repeat sync:
No duplicate record.

TEST G:
Conflict:
Verify documented conflict behavior.

VERIFICATION LOOP:
Do not stop at HTTP 200.
Verify the database state before and after synchronization.

If test fails:
- inspect logs;
- identify root cause;
- fix;
- repeat exact test.

Only mark sync COMPLETE after end-to-end verification.

Run:
flutter analyze
flutter test
flutter build apk --debug

Also run backend tests where applicable.

DOCUMENT:
- local backend startup;
- Android device API URL configuration;
- emulator configuration;
- physical-device configuration.
```

------------------------------------------------------------------------

# PHASE 4 --- BLUETOOTH OFFLINE EMERGENCY SYNC

## Prompt

``` text
THIS PHASE IS HIGH RISK.

DO NOT FAKE BLUETOOTH.

GOAL:
Allow two physical Android devices to exchange selected DisasterReady emergency data without internet.

MVP ONLY:
Device A ↔ Device B.

DO NOT implement mesh networking.

FIRST:
Inspect:
- current Flutter dependencies;
- Android target SDK;
- Android permissions;
- existing native code;
- whether a Bluetooth library already exists.

Choose the smallest reliable implementation.

If Flutter support is insufficient:
Use a controlled Kotlin/native Android bridge.

IMPLEMENT:

1. Bluetooth capability detection.
2. Permission handling.
3. Bluetooth enabled check.
4. Nearby-device discovery.
5. Connection.
6. Handshake.
7. Protocol version.
8. Data envelope.
9. Serialization.
10. Validation.
11. Duplicate detection.
12. Transfer acknowledgement.
13. Retry.
14. Interrupted transfer handling.
15. Staging queue.
16. SQLite commit.
17. Bluetooth Sync screen.

SUPPORTED DATA:
- emergency requests;
- disaster reports;
- critical alerts;
- shelters;
- emergency contacts;
- safe zones;
- resource summaries.

PROTOCOL:

{
 protocolVersion,
 messageId,
 deviceId,
 timestamp,
 entityType,
 operation,
 version,
 payload
}

VALIDATE EVERYTHING.

NEVER TRUST:
- remote role;
- admin claim;
- priority claim;
- status claim;
- resource quantity.

BLUETOOTH FLOW:

Discover
→ Connect
→ Handshake
→ Validate
→ Transfer
→ Validate
→ Stage
→ Commit
→ ACK

DO NOT insert directly into primary database tables before validation.

PHYSICAL TEST REQUIRED:

Device A:
- internet OFF;
- Bluetooth ON;
- create emergency request.

Device B:
- internet OFF;
- Bluetooth ON.

Transfer A → B.

Verify:
1. Device B receives it.
2. Correct fields exist.
3. SQLite contains the record.
4. Duplicate transfer does not create duplicate.
5. Interrupted transfer can recover.
6. Invalid payload is rejected.
7. Transfer status is shown.

THEN TEST:
Device B creates a record.
Transfer B → A.

IMPORTANT:
An emulator test does NOT prove Bluetooth works.

If physical testing is unavailable:
mark Bluetooth as NOT VERIFIED.
Do not claim completion.

VERIFICATION LOOP:
Repeat failed Bluetooth tests until PASS or until a real external blocker is reached.

Do not move to Phase 5 with an unverified Bluetooth feature unless clearly reported as blocked.
```

------------------------------------------------------------------------

# PHASE 5 --- FINAL QA + SECURITY + APK

## Prompt

``` text
This is the final integration and release phase.

DO NOT add major new features.

Read:
- PRD.md
- TRD.md
- ARCHITECTURE.md
- all source code.

GOAL:
Make DisasterReady actually satisfy the documented requirements and produce a usable APK.

RUN COMPLETE REQUIREMENT AUDIT.

CHECK:

A. APP
- launches;
- navigation works;
- no core dead buttons;
- no crash on startup.

B. OFFLINE
- internet disabled;
- dashboard works;
- cached information works;
- emergency request works;
- disaster report works;
- local data survives restart.

C. INTERNET SYNC
- pending records upload;
- records are acknowledged;
- duplicates are prevented;
- failed operations remain retryable.

D. BLUETOOTH
- permissions;
- discovery;
- connection;
- transfer;
- validation;
- duplicate prevention;
- retry;
- physical-device test.

E. RESPONDER
- request list;
- detail;
- accept;
- assign;
- progress;
- complete.

F. RESOURCES
- availability;
- required;
- reserved;
- local persistence;
- synchronization.

G. SECURITY
- no plaintext password;
- no hardcoded secrets;
- no sensitive logs;
- Bluetooth payload validation;
- permission handling;
- role validation.

H. ERROR HANDLING
- offline;
- API unavailable;
- Bluetooth unavailable;
- permission denied;
- malformed data;
- empty database;
- failed sync.

I. BUILD

Run:

flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release

INSTALL RELEASE APK ON PHYSICAL ANDROID DEVICE.

TEST CORE FLOWS AGAIN.

CRITICAL LOOP:

IF ANY REQUIREMENT FAILS:

1. Do not mark complete.
2. Find root cause.
3. Fix it.
4. Run the failing test.
5. Run regression tests.
6. Compare against PRD.
7. Repeat until PASS.

Continue this loop until:
- all feasible requirements PASS;
OR
- a real external blocker prevents verification.

Do not stop merely because the code compiles.

CREATE/UPDATE:

README.md
SETUP.md
BLUETOOTH_TESTING.md
APK_BUILD.md
KNOWN_LIMITATIONS.md

FINAL REPORT MUST INCLUDE:

1. Requirement status.
2. Features verified.
3. Features not verified.
4. Tests executed.
5. Physical-device tests.
6. Build result.
7. APK location.
8. Dependencies.
9. Known limitations.
10. Any assumptions.
11. Any external blockers.

NEVER CLAIM A TEST WAS PASSED IF IT WAS NOT ACTUALLY RUN.
```

------------------------------------------------------------------------

# 10. FINAL ANTIGRAVITY RULE --- NEVER EXIT THE LOOP EARLY

Add this instruction to the end of EVERY major Antigravity prompt:

``` text
FINAL EXECUTION RULE:

Do not stop at "implementation complete".

For every assigned requirement:

IMPLEMENT
→ BUILD
→ TEST
→ BREAK/FAILURE TEST
→ FIX
→ RETEST
→ REGRESSION TEST
→ COMPARE WITH REQUIREMENT
→ ONLY THEN MARK PASS.

If the requirement does not behave as specified, continue fixing it.

If you cannot verify it, mark it NOT VERIFIED.

Never convert an unverified implementation into a "completed" feature.

Never hallucinate successful testing.
Never invent missing infrastructure.
Never hide blockers.
Never claim success without evidence.
```

------------------------------------------------------------------------

# 11. Definition of Done for the Entire Project

The complete DisasterReady project is ready only when:

``` text
┌─────────────────────────────────────────┐
│ Android APK builds                      │
├─────────────────────────────────────────┤
│ Core app works offline                  │
├─────────────────────────────────────────┤
│ SQLite persistence works                │
├─────────────────────────────────────────┤
│ Emergency request works offline         │
├─────────────────────────────────────────┤
│ Disaster report works offline           │
├─────────────────────────────────────────┤
│ Shelter/hospital/contact data works     │
├─────────────────────────────────────────┤
│ Sync queue works                        │
├─────────────────────────────────────────┤
│ Backend sync works                      │
├─────────────────────────────────────────┤
│ Duplicate prevention works              │
├─────────────────────────────────────────┤
│ Bluetooth A ↔ B works physically        │
├─────────────────────────────────────────┤
│ Bluetooth data is validated              │
├─────────────────────────────────────────┤
│ Failed transfers are retryable          │
├─────────────────────────────────────────┤
│ App survives restart                    │
├─────────────────────────────────────────┤
│ Release APK installs                    │
├─────────────────────────────────────────┤
│ Documentation is updated                │
└─────────────────────────────────────────┘

                    ↓

              PROJECT PASS
```

If one critical row fails:

``` text
PROJECT = NOT READY
```

Do not hide it.

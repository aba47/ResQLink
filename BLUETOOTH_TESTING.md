# DisasterReady Bluetooth Offline P2P Testing Guide

This document describes the testing protocol for offline Bluetooth synchronization between two physical Android devices.

---

## Hardware Testing Status

> **PHYSICAL BLUETOOTH TEST: NOT TESTED / REQUIRES 2 PHYSICAL PHONES**  
> Physical Bluetooth RFCOMM cannot be simulated or proven by an Android emulator. In the development host environment, the protocol envelope, validation rules, duplicate prevention, and staging queue are verified via automated dual-node tests (`test/unit/bluetooth_p2p_test.dart`).

---

## 1. Physical Device Test Protocol

To execute physical dual-device verification:

### Prerequisites:
- **Device A**: Physical Android phone (Android 8.0+ / API 26+)
- **Device B**: Physical Android phone (Android 8.0+ / API 26+)
- DisasterReady installed on both devices.

### Step-by-Step Procedure:

#### Phase 1: Disconnect Internet & Enable Bluetooth
1. On **both** Device A and Device B:
   - Turn **OFF** Wi-Fi.
   - Turn **OFF** Mobile Data (Airplane mode with Bluetooth turned back on).
   - Ensure **Bluetooth** is enabled.
2. Launch DisasterReady on both phones.
3. Verify that the red **"OFFLINE MODE — ALL DATA SAVED LOCALLY IN SQLITE"** banner appears on both screens.

#### Phase 2: Create Emergency Request on Device A
1. On Device A, tap **"Request Emergency Help"**.
2. Fill out the request:
   - Name: `Offline Citizen Phone A`
   - Phone: `9112233445`
   - Request Type: `Rescue`
   - Priority: `CRITICAL`
   - People Count: `4`
   - Description: `Trapped on high ground by rising water`
   - Location: `Sector 9, Riverbank`
3. Tap **"Submit Emergency Request"**.
4. Confirm request appears in Device A's local list with status `Requested` and sync status `PENDING`.

#### Phase 3: P2P Discovery & Transfer A $\rightarrow$ B
1. On both phones, navigate to **Sync Center** $\rightarrow$ tap the **Bluetooth icon** in the top bar.
2. On Device A, tap **"Scan Nearby"**.
3. When Device B appears in the list, tap **"Connect"**.
4. Once connected:
   - Device A displays `Connected: [Device B Name]`.
   - Device B displays `Connected: [Device A Name]`.
5. Under **"Share"**, select **"Emergency Request"**.
6. Tap **"Transmit P2P"**.

#### Phase 4: Verification on Device B
1. On Device B, switch to the **"Transfer Logs"** tab:
   - Verify `INBOUND • emergency_request [STAGED]`.
   - Verify `INBOUND • emergency_request [COMMITTED]`.
   - Verify ACK returned to Device A.
2. Navigate to **Emergency Requests** on Device B:
   - Confirm `Offline Citizen Phone A` is now visible in Device B's local SQLite database.
   - Confirm details (Rescue, CRITICAL, 4 people) match exactly.

#### Phase 5: Duplicate Prevention Test
1. On Device A, tap **"Transmit P2P"** again for the exact same entity.
2. On Device B's Transfer Logs:
   - Verify status `DUPLICATE` is recorded.
   - Verify no duplicate entry is inserted into Device B's request list.

#### Phase 6: Reverse Transfer B $\rightarrow$ A
1. On Device B, submit a new **Disaster Report** (`Bridge Damaged`).
2. In Bluetooth Sync on Device B, select **Disaster Report** and tap **"Transmit P2P"**.
3. Verify Device A receives, stages, validates, and commits the report to SQLite.

---

## 2. Security Validation Rules Enforced

During Bluetooth P2P reception, the `BluetoothValidator` enforces strict anti-tampering rules:
1. **Never Trust Remote Role**: Remote peers cannot claim admin privileges; `is_admin` is stripped and role is capped at `CITIZEN`.
2. **Never Trust Priority**: Unrecognized priority strings are clamped to safe default `MEDIUM`.
3. **Never Trust Status Overrides**: Untrusted peer updates cannot mark emergency tickets `Completed` or assign responder teams remotely; remote status changes default to `Requested`.
4. **Never Trust Resource Quantities**: Out-of-bounds or negative quantities are rejected.
5. **Staging Queue Isolation**: All incoming envelopes enter `sync_staging` first; invalid envelopes are marked `REJECTED` and never touch primary SQLite tables.

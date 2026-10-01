# DisasterReady Known Limitations & Architectural Boundaries

This document outlines known limitations, external boundaries, and hardware constraints in DisasterReady (ResQLink).

---

## 1. Bluetooth P2P Limitations

1. **Topology (Point-to-Point Only)**:
   - Per MVP specifications (Phase 4), DisasterReady implements direct `Device A ↔ Device B` single-hop Bluetooth RFCOMM pairing.
   - It does **not** implement multi-hop mesh networking (e.g. BLE Mesh or B.A.T.M.A.N.).
2. **Physical Device Requirement**:
   - Bluetooth RFCOMM data streaming cannot be verified inside Android emulators because emulators lack virtualized Bluetooth controller abstraction.
   - Dual-device testing requires two physical Android devices with Bluetooth enabled.
3. **Range**:
   - Standard Bluetooth Class 2 devices have an effective range of 10 to 30 meters line-of-sight. Physical barriers (concrete, debris, floodwaters) will attenuate signal range.

---

## 2. Sync & Conflict Resolution

1. **Sync Model**:
   - The application uses a local SQLite sync queue with version-based optimistic concurrency control.
   - When conflicting edits occur between two disconnected devices (e.g., responder updates status offline while backend receives an update), the newer version is preserved and the older version is flagged with `CONFLICT` status in the sync queue rather than silently discarded.
2. **Media Attachments**:
   - Disaster damage reports support text descriptions, GPS coordinates, severity ratings, and local media paths. Large video or high-resolution photo file binary sync is deferred until high-bandwidth Wi-Fi/cellular connection is restored.

---

## 3. Platform & Host Toolchain

1. **Host Android SDK Availability**:
   - The development environment lacks Android SDK Command-Line Tools (`ANDROID_HOME` unset). While all Dart, Kotlin native bridge code, Gradle build configurations, and Android manifests are validated, binary `.apk` generation is blocked until Android Studio/SDK is installed on the host.
2. **Location Services in Flight Mode**:
   - If the user turns on Airplane Mode, Android devices may disable GPS in some manufacturer power-saving profiles. Users should ensure Location remains enabled for accurate coordinate capture during offline emergency requests.

# DisasterReady Environment & Local Backend Setup

This guide details how to start the local FastAPI backend server, configure network addresses for emulators and physical devices, and run the test suites.

---

## 1. Local Backend Startup

The backend is located in `backend/` and runs on Python 3 with FastAPI and Uvicorn.

### Step 1: Install Python Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### Step 2: Start the FastAPI Server
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
The server will initialize the SQLite database `backend/disaster_server.db` on first run.

### Step 3: Verify Backend Health
Open `http://localhost:8000/health` in your browser. Expected response:
```json
{
  "status": "healthy",
  "service": "DisasterReady Emergency Sync Backend",
  "version": "1.0.0"
}
```

---

## 2. Network Configuration for Client App

In DisasterReady, the backend API URL is configurable directly from the UI without recompilation:
1. Open the app.
2. Navigate to **Offline & Sync Center** (or tap the network indicator).
3. Tap the **Ethernet / Server settings** icon in the App Bar (`Configure Backend URL`).
4. Enter the appropriate URL according to your deployment:

### Scenario A: Android Emulator
- **URL**: `http://10.0.2.2:8000`
- *Explanation*: Android emulators use `10.0.2.2` as an alias to the development computer's loopback interface (`127.0.0.1`).

### Scenario B: Physical Android Device (over Wi-Fi)
- Find your host PC's Local Area Network IP address:
  - On Windows: Run `ipconfig` (e.g. `192.168.1.45`)
  - On macOS/Linux: Run `ifconfig` or `ip a`
- Ensure your phone and development PC are connected to the same Wi-Fi network.
- Ensure Windows Firewall allows inbound connections on TCP port `8000`.
- **URL**: `http://192.168.1.45:8000`

### Scenario C: Desktop / Automated Test Harness
- **URL**: `http://localhost:8000`

---

## 3. Running Verification & Test Suites

### Flutter Code Analysis
```bash
flutter analyze
```

### Flutter Test Suites (Offline, Disaster Features, Internet Sync, Bluetooth P2P)
```bash
flutter test
```

### Python Backend Unit & Integration Tests
```bash
python backend/test_backend.py
```

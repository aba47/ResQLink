from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import json
import sqlite3

from database import init_server_db, get_db

app = FastAPI(
    title="DisasterReady Emergency Sync Backend",
    version="1.0.0",
    description="Local FastAPI synchronization backend for DisasterReady Android mobile app."
)

@app.on_event("startup")
def startup_event():
    init_server_db()

# Models
class PushItem(BaseModel):
    id: str
    entity_type: str
    entity_id: str
    operation: str # CREATE, UPDATE, DELETE
    payload: str   # JSON string
    version: int = 1
    source_device_id: Optional[str] = None
    created_at: str

class PushRequest(BaseModel):
    device_id: str
    items: List[PushItem]

class SyncAck(BaseModel):
    queue_id: str
    entity_id: str
    status: str # SYNCED, CONFLICT, ERROR
    error: Optional[str] = None

class PushResponse(BaseModel):
    synced_count: int
    acknowledgements: List[SyncAck]

class PullRequest(BaseModel):
    device_id: str
    since_timestamp: Optional[str] = None

class PullResponse(BaseModel):
    server_time: str
    disasters: List[Dict[str, Any]]
    emergency_requests: List[Dict[str, Any]]
    disaster_reports: List[Dict[str, Any]]
    shelters: List[Dict[str, Any]]
    hospitals: List[Dict[str, Any]]
    emergency_contacts: List[Dict[str, Any]]
    safe_zones: List[Dict[str, Any]]
    resources: List[Dict[str, Any]]

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "DisasterReady Backend",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@app.post("/sync/push", response_model=PushResponse)
def push_sync(request: PushRequest):
    conn = get_db()
    cursor = conn.cursor()
    acks = []
    synced_count = 0

    for item in request.items:
        try:
            payload_data = json.loads(item.payload)
            table_name = _map_table(item.entity_type)
            
            if not table_name:
                acks.append(SyncAck(
                    queue_id=item.id,
                    entity_id=item.entity_id,
                    status="ERROR",
                    error=f"Unknown entity type: {item.entity_type}"
                ))
                continue

            # Check if record already exists on server for conflict / deduplication
            cursor.execute(f"SELECT * FROM {table_name} WHERE id = ?", (item.entity_id,))
            existing = cursor.fetchone()

            if existing:
                # Conflict resolution: compare updated_at and version
                existing_dict = dict(existing)
                existing_updated = existing_dict.get("updated_at", "")
                incoming_updated = payload_data.get("updated_at", item.created_at)
                existing_version = existing_dict.get("version", 1)

                if incoming_updated >= existing_updated or item.version > existing_version:
                    # Incoming is newer -> update
                    _upsert_record(cursor, table_name, payload_data, item.version, request.device_id)
                    synced_count += 1
                    acks.append(SyncAck(queue_id=item.id, entity_id=item.entity_id, status="SYNCED"))
                else:
                    # Server is newer -> record conflict but ack
                    acks.append(SyncAck(
                        queue_id=item.id,
                        entity_id=item.entity_id,
                        status="CONFLICT",
                        error="Server contains newer version"
                    ))
            else:
                # Insert brand new record
                _upsert_record(cursor, table_name, payload_data, item.version, request.device_id)
                synced_count += 1
                acks.append(SyncAck(queue_id=item.id, entity_id=item.entity_id, status="SYNCED"))

        except Exception as e:
            acks.append(SyncAck(
                queue_id=item.id,
                entity_id=item.entity_id,
                status="ERROR",
                error=str(e)
            ))

    conn.commit()
    conn.close()

    return PushResponse(synced_count=synced_count, acknowledgements=acks)

@app.post("/sync/pull", response_model=PullResponse)
def pull_sync(request: PullRequest):
    conn = get_db()
    cursor = conn.cursor()
    server_time = datetime.now(timezone.utc).isoformat()
    since = request.since_timestamp or "1970-01-01T00:00:00Z"

    def fetch_entities(table: str):
        cursor.execute(
            f"SELECT * FROM {table} WHERE updated_at > ? AND is_deleted = 0 ORDER BY updated_at ASC",
            (since,)
        )
        return [dict(row) for row in cursor.fetchall()]

    response = PullResponse(
        server_time=server_time,
        disasters=fetch_entities("disasters"),
        emergency_requests=fetch_entities("emergency_requests"),
        disaster_reports=fetch_entities("disaster_reports"),
        shelters=fetch_entities("shelters"),
        hospitals=fetch_entities("hospitals"),
        emergency_contacts=fetch_entities("emergency_contacts"),
        safe_zones=fetch_entities("safe_zones"),
        resources=fetch_entities("resources"),
    )
    conn.close()
    return response

# Standard REST Endpoints
@app.get("/disasters")
def get_disasters():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM disasters WHERE is_deleted = 0 ORDER BY reported_at DESC")
    res = [dict(r) for r in cursor.fetchall()]
    conn.close()
    return res

@app.post("/disasters")
def create_disaster(disaster: Dict[str, Any]):
    conn = get_db()
    cursor = conn.cursor()
    _upsert_record(cursor, "disasters", disaster, 1, "api")
    conn.commit()
    conn.close()
    return {"status": "created", "id": disaster["id"]}

@app.get("/emergency-requests")
def get_emergency_requests():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM emergency_requests WHERE is_deleted = 0 ORDER BY created_at DESC")
    res = [dict(r) for r in cursor.fetchall()]
    conn.close()
    return res

@app.patch("/emergency-requests/{id}")
def update_emergency_request(id: str, updates: Dict[str, Any]):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM emergency_requests WHERE id = ?", (id,))
    existing = cursor.fetchone()
    if not existing:
        conn.close()
        raise HTTPException(status_code=404, detail="Request not found")

    data = dict(existing)
    data.update(updates)
    data["updated_at"] = datetime.now(timezone.utc).isoformat()
    _upsert_record(cursor, "emergency_requests", data, data.get("version", 1) + 1, "api")
    conn.commit()
    conn.close()
    return {"status": "updated", "id": id}

def _map_table(entity_type: str) -> Optional[str]:
    mapping = {
        "emergency_request": "emergency_requests",
        "emergency_requests": "emergency_requests",
        "disaster_report": "disaster_reports",
        "disaster_reports": "disaster_reports",
        "disaster": "disasters",
        "disasters": "disasters",
        "shelter": "shelters",
        "shelters": "shelters",
        "hospital": "hospitals",
        "hospitals": "hospitals",
        "emergency_contact": "emergency_contacts",
        "emergency_contacts": "emergency_contacts",
        "safe_zone": "safe_zones",
        "safe_zones": "safe_zones",
        "resource": "resources",
        "resources": "resources",
    }
    return mapping.get(entity_type.lower())

def _upsert_record(cursor, table: str, data: Dict[str, Any], version: int, device_id: str):
    # Ensure standard sync columns exist in data
    record = dict(data)
    record["version"] = version
    if "source_device_id" not in record or not record["source_device_id"]:
        record["source_device_id"] = device_id
    if "sync_status" in record:
        del record["sync_status"] # Server does not track local sync_status

    # Filter columns to those in table
    cursor.execute(f"PRAGMA table_info({table})")
    columns = [row["name"] for row in cursor.fetchall()]

    filtered_record = {k: v for k, v in record.items() if k in columns}
    col_names = ", ".join(filtered_record.keys())
    placeholders = ", ".join(["?" for _ in filtered_record])
    updates = ", ".join([f"{k} = excluded.{k}" for k in filtered_record if k != "id"])

    sql = f"""
      INSERT INTO {table} ({col_names})
      VALUES ({placeholders})
      ON CONFLICT(id) DO UPDATE SET {updates}
    """
    cursor.execute(sql, list(filtered_record.values()))

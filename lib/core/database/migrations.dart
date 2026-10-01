import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static Future<void> onCreate(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'citizen',
        email TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 2. Disasters Table
    await db.execute('''
      CREATE TABLE disasters (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        severity TEXT NOT NULL,
        status TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        radius_km REAL DEFAULT 0.0,
        affected_population INTEGER DEFAULT 0,
        reported_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        source TEXT DEFAULT 'local',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 3. Emergency Requests Table
    await db.execute('''
      CREATE TABLE emergency_requests (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        disaster_id TEXT,
        request_type TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Requested',
        description TEXT NOT NULL,
        people_count INTEGER DEFAULT 1,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        assigned_team TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 4. Disaster Reports Table
    await db.execute('''
      CREATE TABLE disaster_reports (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT NOT NULL,
        disaster_type TEXT NOT NULL,
        description TEXT NOT NULL,
        severity TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        casualties_count INTEGER DEFAULT 0,
        injured_count INTEGER DEFAULT 0,
        media_path TEXT,
        status TEXT DEFAULT 'submitted',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'PENDING',
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 5. Shelters Table
    await db.execute('''
      CREATE TABLE shelters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        capacity INTEGER NOT NULL DEFAULT 0,
        current_occupancy INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'open',
        contact_person TEXT,
        contact_phone TEXT,
        facilities TEXT,
        supplies_status TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 6. Hospitals Table
    await db.execute('''
      CREATE TABLE hospitals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        emergency_contact TEXT NOT NULL,
        total_beds INTEGER DEFAULT 0,
        available_beds INTEGER DEFAULT 0,
        icu_beds_available INTEGER DEFAULT 0,
        blood_units_available INTEGER DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'operational',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 7. Emergency Services Table
    await db.execute('''
      CREATE TABLE emergency_services (
        id TEXT PRIMARY KEY,
        service_type TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        alternate_phone TEXT,
        coverage_area TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 8. Resources Table
    await db.execute('''
      CREATE TABLE resources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL,
        location TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'available',
        shelter_id TEXT,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 9. Emergency Contacts Table
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        is_primary INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 10. Safe Zones Table
    await db.execute('''
      CREATE TABLE safe_zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL DEFAULT 100.0,
        safety_level TEXT NOT NULL,
        guidelines TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 11. Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        source_device_id TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');

    // 12. Sync Conflicts Table
    await db.execute('''
      CREATE TABLE sync_conflicts (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_payload TEXT NOT NULL,
        remote_payload TEXT NOT NULL,
        resolution_status TEXT DEFAULT 'UNRESOLVED',
        resolved_payload TEXT,
        created_at TEXT NOT NULL,
        resolved_at TEXT
      )
    ''');

    // 13. Bluetooth Peers Table
    await db.execute('''
      CREATE TABLE bluetooth_peers (
        id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        device_address TEXT NOT NULL,
        last_seen TEXT NOT NULL,
        sync_status TEXT DEFAULT 'IDLE'
      )
    ''');

    // 14. Audit Logs Table
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        details TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // 15. App Metadata Table
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Prepopulate initial core disaster seed data so offline users immediately have essential emergency contacts & shelters
    await _seedInitialData(db);
  }

  static Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();

    // Default National/State Emergency Services
    await db.rawInsert('''
      INSERT INTO emergency_services (id, service_type, name, phone, coverage_area, status, created_at, updated_at)
      VALUES 
        ('es-1', 'police', 'National Police Control', '100', 'National', 'active', '$now', '$now'),
        ('es-2', 'fire', 'Fire & Rescue Services', '101', 'National', 'active', '$now', '$now'),
        ('es-3', 'ambulance', 'Medical Emergency Ambulance', '102', 'National', 'active', '$now', '$now'),
        ('es-4', 'disaster_management', 'National Disaster Response Force (NDRF)', '1078', 'National', 'active', '$now', '$now'),
        ('es-5', 'disaster_management', 'State Emergency Operations Center', '1070', 'Statewide', 'active', '$now', '$now')
    ''');

    // Initial safe emergency contacts
    await db.rawInsert('''
      INSERT INTO emergency_contacts (id, name, relationship, phone, is_primary, created_at, updated_at)
      VALUES 
        ('ec-1', 'National Disaster Helpline', 'Official Authority', '1078', 1, '$now', '$now'),
        ('ec-2', 'Central Medical Helpline', 'Medical Response', '108', 0, '$now', '$now')
    ''');

    // Metadata
    await db.rawInsert('''
      INSERT INTO app_metadata (key, value)
      VALUES 
        ('db_initialized', 'true'),
        ('initial_seed_version', '1'),
        ('last_sync_time', '')
    ''');
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future database schema upgrades
  }
}

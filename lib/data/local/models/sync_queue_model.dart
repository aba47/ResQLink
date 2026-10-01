class SyncQueueModel {
  final String id;
  final String entityType; // emergency_request, disaster_report, etc.
  final String entityId;
  final String operation; // CREATE, UPDATE, DELETE
  final String payload; // JSON serialized string
  final int version;
  final String? sourceDeviceId;
  final String createdAt;
  final int retryCount;
  final String? lastError;
  final String status; // PENDING, SYNCING, SYNCED, FAILED, CONFLICT

  const SyncQueueModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.version = 1,
    this.sourceDeviceId,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = 'PENDING',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'version': version,
      'source_device_id': sourceDeviceId,
      'created_at': createdAt,
      'retry_count': retryCount,
      'last_error': lastError,
      'status': status,
    };
  }

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: map['operation'] as String,
      payload: map['payload'] as String,
      version: (map['version'] as int?) ?? 1,
      sourceDeviceId: map['source_device_id'] as String?,
      createdAt: map['created_at'] as String,
      retryCount: (map['retry_count'] as int?) ?? 0,
      lastError: map['last_error'] as String?,
      status: (map['status'] as String?) ?? 'PENDING',
    );
  }

  SyncQueueModel copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    int? version,
    String? sourceDeviceId,
    String? createdAt,
    int? retryCount,
    String? lastError,
    String? status,
  }) {
    return SyncQueueModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      version: version ?? this.version,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
    );
  }
}

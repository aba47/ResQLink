class EmergencyRequestModel {
  final String id;
  final String? userId;
  final String userName;
  final String phone;
  final String? disasterId;
  final String requestType; // medical, evacuation, food_water, rescue, shelter, other
  final String priority; // LOW, MEDIUM, HIGH, CRITICAL
  final String status; // Requested, Accepted, Team Assigned, In Progress, Completed, Cancelled
  final String description;
  final int peopleCount;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? assignedTeam;
  final String createdAt;
  final String updatedAt;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED
  final bool isDeleted;

  const EmergencyRequestModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.phone,
    this.disasterId,
    required this.requestType,
    required this.priority,
    this.status = 'Requested',
    required this.description,
    this.peopleCount = 1,
    required this.location,
    this.latitude,
    this.longitude,
    this.assignedTeam,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'PENDING',
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'phone': phone,
      'disaster_id': disasterId,
      'request_type': requestType,
      'priority': priority,
      'status': status,
      'description': description,
      'people_count': peopleCount,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'assigned_team': assignedTeam,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory EmergencyRequestModel.fromMap(Map<String, dynamic> map) {
    return EmergencyRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      userName: map['user_name'] as String,
      phone: map['phone'] as String,
      disasterId: map['disaster_id'] as String?,
      requestType: map['request_type'] as String,
      priority: map['priority'] as String,
      status: (map['status'] as String?) ?? 'Requested',
      description: map['description'] as String,
      peopleCount: (map['people_count'] as int?) ?? 1,
      location: map['location'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      assignedTeam: map['assigned_team'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  EmergencyRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? phone,
    String? disasterId,
    String? requestType,
    String? priority,
    String? status,
    String? description,
    int? peopleCount,
    String? location,
    double? latitude,
    double? longitude,
    String? assignedTeam,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
    bool? isDeleted,
  }) {
    return EmergencyRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phone: phone ?? this.phone,
      disasterId: disasterId ?? this.disasterId,
      requestType: requestType ?? this.requestType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      description: description ?? this.description,
      peopleCount: peopleCount ?? this.peopleCount,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

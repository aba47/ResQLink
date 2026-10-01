class DisasterReportModel {
  final String id;
  final String? userId;
  final String title;
  final String disasterType;
  final String description;
  final String severity;
  final String location;
  final double? latitude;
  final double? longitude;
  final int casualtiesCount;
  final int injuredCount;
  final String? mediaPath;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String syncStatus;
  final bool isDeleted;

  const DisasterReportModel({
    required this.id,
    this.userId,
    required this.title,
    required this.disasterType,
    required this.description,
    required this.severity,
    required this.location,
    this.latitude,
    this.longitude,
    this.casualtiesCount = 0,
    this.injuredCount = 0,
    this.mediaPath,
    this.status = 'submitted',
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'PENDING',
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'disaster_type': disasterType,
      'description': description,
      'severity': severity,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'casualties_count': casualtiesCount,
      'injured_count': injuredCount,
      'media_path': mediaPath,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory DisasterReportModel.fromMap(Map<String, dynamic> map) {
    return DisasterReportModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      disasterType: map['disaster_type'] as String,
      description: map['description'] as String,
      severity: map['severity'] as String,
      location: map['location'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      casualtiesCount: (map['casualties_count'] as int?) ?? 0,
      injuredCount: (map['injured_count'] as int?) ?? 0,
      mediaPath: map['media_path'] as String?,
      status: (map['status'] as String?) ?? 'submitted',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  DisasterReportModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? disasterType,
    String? description,
    String? severity,
    String? location,
    double? latitude,
    double? longitude,
    int? casualtiesCount,
    int? injuredCount,
    String? mediaPath,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
    bool? isDeleted,
  }) {
    return DisasterReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      disasterType: disasterType ?? this.disasterType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      casualtiesCount: casualtiesCount ?? this.casualtiesCount,
      injuredCount: injuredCount ?? this.injuredCount,
      mediaPath: mediaPath ?? this.mediaPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

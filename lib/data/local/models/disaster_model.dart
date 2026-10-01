class DisasterModel {
  final String id;
  final String title;
  final String type; // flood, earthquake, cyclone, fire, landslide, etc.
  final String? description;
  final String severity; // low, medium, high, critical
  final String status; // active, monitoring, resolved
  final String location;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final int affectedPopulation;
  final String reportedAt;
  final String updatedAt;
  final String source;
  final bool isDeleted;

  const DisasterModel({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    required this.severity,
    required this.status,
    required this.location,
    this.latitude,
    this.longitude,
    this.radiusKm = 0.0,
    this.affectedPopulation = 0,
    required this.reportedAt,
    required this.updatedAt,
    this.source = 'local',
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'description': description,
      'severity': severity,
      'status': status,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'affected_population': affectedPopulation,
      'reported_at': reportedAt,
      'updated_at': updatedAt,
      'source': source,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory DisasterModel.fromMap(Map<String, dynamic> map) {
    return DisasterModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      description: map['description'] as String?,
      severity: map['severity'] as String,
      status: map['status'] as String,
      location: map['location'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      radiusKm: (map['radius_km'] as num?)?.toDouble() ?? 0.0,
      affectedPopulation: (map['affected_population'] as int?) ?? 0,
      reportedAt: map['reported_at'] as String,
      updatedAt: map['updated_at'] as String,
      source: (map['source'] as String?) ?? 'local',
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  DisasterModel copyWith({
    String? id,
    String? title,
    String? type,
    String? description,
    String? severity,
    String? status,
    String? location,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? affectedPopulation,
    String? reportedAt,
    String? updatedAt,
    String? source,
    bool? isDeleted,
  }) {
    return DisasterModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      affectedPopulation: affectedPopulation ?? this.affectedPopulation,
      reportedAt: reportedAt ?? this.reportedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

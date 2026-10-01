class SafeZoneModel {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String safetyLevel; // high, medium
  final String? guidelines;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  const SafeZoneModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
    required this.safetyLevel,
    this.guidelines,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'safety_level': safetyLevel,
      'guidelines': guidelines,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory SafeZoneModel.fromMap(Map<String, dynamic> map) {
    return SafeZoneModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radius_meters'] as num?)?.toDouble() ?? 100.0,
      safetyLevel: map['safety_level'] as String,
      guidelines: map['guidelines'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

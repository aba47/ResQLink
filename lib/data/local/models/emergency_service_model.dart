class EmergencyServiceModel {
  final String id;
  final String serviceType; // police, fire, ambulance, disaster_management, coast_guard
  final String name;
  final String phone;
  final String? alternatePhone;
  final String? coverageArea;
  final String status;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  const EmergencyServiceModel({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.phone,
    this.alternatePhone,
    this.coverageArea,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_type': serviceType,
      'name': name,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'coverage_area': coverageArea,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory EmergencyServiceModel.fromMap(Map<String, dynamic> map) {
    return EmergencyServiceModel(
      id: map['id'] as String,
      serviceType: map['service_type'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      alternatePhone: map['alternate_phone'] as String?,
      coverageArea: map['coverage_area'] as String?,
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

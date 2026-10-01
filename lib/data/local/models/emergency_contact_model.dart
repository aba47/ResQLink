class EmergencyContactModel {
  final String id;
  final String name;
  final String relationship;
  final String phone;
  final String? email;
  final bool isPrimary;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
      'is_primary': isPrimary ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      id: map['id'] as String,
      name: map['name'] as String,
      relationship: map['relationship'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      isPrimary: (map['is_primary'] as int?) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

class ResourceModel {
  final String id;
  final String name;
  final String category; // food, water, medicine, equipment, blankets
  final int quantity;
  final String unit;
  final String location;
  final String status; // available, depleted, requested
  final String? shelterId;
  final String updatedAt;
  final bool isDeleted;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.location,
    this.status = 'available',
    this.shelterId,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'status': status,
      'shelter_id': shelterId,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: (map['quantity'] as int?) ?? 0,
      unit: map['unit'] as String,
      location: map['location'] as String,
      status: (map['status'] as String?) ?? 'available',
      shelterId: map['shelter_id'] as String?,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

class ShelterModel {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final int currentOccupancy;
  final String status; // open, full, closed
  final String? contactPerson;
  final String? contactPhone;
  final String? facilities;
  final String? suppliesStatus;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  const ShelterModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.capacity,
    this.currentOccupancy = 0,
    this.status = 'open',
    this.contactPerson,
    this.contactPhone,
    this.facilities,
    this.suppliesStatus,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  int get availableCapacity => (capacity - currentOccupancy) > 0 ? (capacity - currentOccupancy) : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'status': status,
      'contact_person': contactPerson,
      'contact_phone': contactPhone,
      'facilities': facilities,
      'supplies_status': suppliesStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory ShelterModel.fromMap(Map<String, dynamic> map) {
    return ShelterModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      capacity: (map['capacity'] as int?) ?? 0,
      currentOccupancy: (map['current_occupancy'] as int?) ?? 0,
      status: (map['status'] as String?) ?? 'open',
      contactPerson: map['contact_person'] as String?,
      contactPhone: map['contact_phone'] as String?,
      facilities: map['facilities'] as String?,
      suppliesStatus: map['supplies_status'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

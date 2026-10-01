class HospitalModel {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String emergencyContact;
  final int totalBeds;
  final int availableBeds;
  final int icuBedsAvailable;
  final int bloodUnitsAvailable;
  final String status; // operational, overwhelmed, closed
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.emergencyContact,
    this.totalBeds = 0,
    this.availableBeds = 0,
    this.icuBedsAvailable = 0,
    this.bloodUnitsAvailable = 0,
    this.status = 'operational',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'emergency_contact': emergencyContact,
      'total_beds': totalBeds,
      'available_beds': availableBeds,
      'icu_beds_available': icuBedsAvailable,
      'blood_units_available': bloodUnitsAvailable,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      emergencyContact: (map['emergency_contact'] as String?) ?? '',
      totalBeds: (map['total_beds'] as int?) ?? 0,
      availableBeds: (map['available_beds'] as int?) ?? 0,
      icuBedsAvailable: (map['icu_beds_available'] as int?) ?? 0,
      bloodUnitsAvailable: (map['blood_units_available'] as int?) ?? 0,
      status: (map['status'] as String?) ?? 'operational',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

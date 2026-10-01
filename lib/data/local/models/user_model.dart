class UserModel {
  final String id;
  final String name;
  final String? phone;
  final String role; // 'citizen', 'responder', 'admin'
  final String? email;
  final String status;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  const UserModel({
    required this.id,
    required this.name,
    this.phone,
    this.role = 'citizen',
    this.email,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'email': email,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      role: (map['role'] as String?) ?? 'citizen',
      email: map['email'] as String?,
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? email,
    String? status,
    String? createdAt,
    String? updatedAt,
    bool? isDeleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

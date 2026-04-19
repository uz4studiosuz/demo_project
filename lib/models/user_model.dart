// user_model.dart
import 'user_role.dart';

class UserModel {
  final int id;
  final int? branchId;
  final int? districtId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? phone;
  final String username; 
  final UserRole role; // Bu enum DB dagiga mos bo'lishi kerak 
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.branchId,
    this.districtId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phone,
    required this.username,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      branchId: json['branch_id'],
      districtId: json['district_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      phone: json['phone'],
      username: json['username'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['role'] as String?)?.toUpperCase(),
        orElse: () => UserRole.surveyor,
      ),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (districtId != null) 'district_id': districtId,
      'first_name': firstName,
      'last_name': lastName,
      if (middleName != null) 'middle_name': middleName,
      if (phone != null) 'phone': phone,
      'username': username,
      'role': role.name.toUpperCase(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName =>
      '$lastName $firstName${middleName != null ? ' $middleName' : ''}';
}

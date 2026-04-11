// resident_model.dart
class ResidentModel {
  final int id;
  final int householdId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? fullName;
  final String? phonePrimary;
  final String? phoneSecondary;
  final DateTime? birthDate;
  final String gender; // MALE, FEMALE, UNKNOWN
  final String? role; // Oila boshlig'i, Bobosi, Buvisi, etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Hozirgi flutter UI uchun yordamchi maydon (mock uchun)
  final bool isHighRiskMock;

  ResidentModel({
    required this.id,
    required this.householdId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.fullName,
    this.phonePrimary,
    this.phoneSecondary,
    this.birthDate,
    this.gender = 'UNKNOWN',
    this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isHighRiskMock = false, // Mock
  });

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      householdId: json['household_id'] is int ? json['household_id'] : int.tryParse(json['household_id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      fullName: json['full_name'],
      phonePrimary: json['phone_primary'],
      phoneSecondary: json['phone_secondary'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      gender: json['gender'] ?? 'UNKNOWN',
      role: json['role'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      isHighRiskMock: json['isHighRiskMock'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'first_name': firstName,
      'last_name': lastName,
      if (middleName != null) 'middle_name': middleName,
      if (fullName != null) 'full_name': fullName,
      if (phonePrimary != null) 'phone_primary': phonePrimary,
      if (phoneSecondary != null) 'phone_secondary': phoneSecondary,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T')[0],
      'gender': gender,
      if (role != null) 'role': role,
      'is_active': isActive,
    };
  }

  String get displayFullName => fullName ?? '$lastName $firstName${middleName != null ? ' $middleName' : ''}';
}

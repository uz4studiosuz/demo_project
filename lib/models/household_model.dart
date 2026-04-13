import 'resident_model.dart';

class HouseholdModel {
  final int id; // Changed from BigInt since Dart standard int handles 64-bit natively usually, but for parsing we can just use int
  final int regionId;
  final int districtId;
  final int? branchId;
  final int createdByAgentId;
  final String? cadastralNumber;
  final String officialAddress;
  final String? houseNumber;
  final String? apartment;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final String? tumanName;
  final String? qfyName;
  final String? mfyName;
  final String? streetName;
  
  // Relations
  List<ResidentModel> residents;

  HouseholdModel({
    required this.id,
    required this.regionId,
    required this.districtId,
    this.branchId,
    required this.createdByAgentId,
    this.cadastralNumber,
    required this.officialAddress,
    this.houseNumber,
    this.apartment,
    this.landmark,
    required this.latitude,
    required this.longitude,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.residents = const [],
    this.tumanName,
    this.qfyName,
    this.mfyName,
    this.streetName,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      regionId: json['region_id'] ?? 0,
      districtId: json['district_id'] ?? 0,
      branchId: json['branch_id'],
      createdByAgentId: json['created_by_agent_id'] ?? 0,
      cadastralNumber: json['cadastral_number'],
      officialAddress: json['official_address'] ?? '',
      houseNumber: json['house_number'],
      apartment: json['apartment'],
      landmark: json['landmark'],
      latitude: json['latitude'] is double ? json['latitude'] : double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: json['longitude'] is double ? json['longitude'] : double.tryParse(json['longitude'].toString()) ?? 0.0,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      residents: json['residents'] != null 
          ? (json['residents'] as List).map((x) => ResidentModel.fromJson(x)).toList()
          : [],
      tumanName: json['tuman_name'],
      qfyName: json['qfy_name'],
      mfyName: json['mfy_name'],
      streetName: json['street_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region_id': regionId,
      'district_id': districtId,
      if (branchId != null) 'branch_id': branchId,
      'created_by_agent_id': createdByAgentId,
      if (cadastralNumber != null) 'cadastral_number': cadastralNumber,
      'official_address': officialAddress,
      if (houseNumber != null) 'house_number': houseNumber,
      if (apartment != null) 'apartment': apartment,
      if (landmark != null) 'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'residents': residents.map((r) => r.toJson()).toList(),
      if (tumanName != null) 'tuman_name': tumanName,
      if (qfyName != null) 'qfy_name': qfyName,
      if (mfyName != null) 'mfy_name': mfyName,
      if (streetName != null) 'street_name': streetName,
    };
  }
}

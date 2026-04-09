class Patient {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final int familyMembersCount;
  final bool isHighRisk;
  final double lat;
  final double lng;

  Patient({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.familyMembersCount,
    required this.isHighRisk,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'familyMembersCount': familyMembersCount,
      'isHighRisk': isHighRisk,
      'lat': lat,
      'lng': lng,
    };
  }
}

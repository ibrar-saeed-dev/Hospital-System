class AdminHospitalItem {
  final String id;
  final String name;
  final String address;
  final String contact;
  final Map<String, dynamic>? location;
  final String verificationStatus; // verified, pending, rejected
  final String accountStatus;
  final String? lastCapacityUpdate;

  AdminHospitalItem({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    this.location,
    required this.verificationStatus,
    required this.accountStatus,
    this.lastCapacityUpdate,
  });

  factory AdminHospitalItem.fromJson(Map<String, dynamic> json) {
    return AdminHospitalItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Hospital',
      address: json['address']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      location: json['location'] as Map<String, dynamic>?,
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      accountStatus: json['account_status']?.toString() ?? 'active',
      lastCapacityUpdate: json['last_capacity_update']?.toString(),
    );
  }
}

class AdminHospitalItem {
  final String id;
  final String name;
  final String address;
  final String contact;
  final Map<String, dynamic>? location;
  final double? latitude;
  final double? longitude;
  final double overallOccupancyPercent;
  final double icuOccupancyPercent;
  final int totalCapacity;
  final int totalOccupied;
  final String verificationStatus; // verified, pending, rejected
  final String accountStatus;
  final String? lastCapacityUpdate;

  AdminHospitalItem({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    this.location,
    this.latitude,
    this.longitude,
    this.overallOccupancyPercent = 0.0,
    this.icuOccupancyPercent = 0.0,
    this.totalCapacity = 0,
    this.totalOccupied = 0,
    required this.verificationStatus,
    required this.accountStatus,
    this.lastCapacityUpdate,
  });

  factory AdminHospitalItem.fromJson(Map<String, dynamic> json) {
    double? lat = (json['latitude'] as num?)?.toDouble();
    double? lng = (json['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      final loc = json['location'];
      if (loc is Map<String, dynamic> &&
          loc['coordinates'] is List &&
          (loc['coordinates'] as List).length >= 2) {
        lng = (loc['coordinates'][0] as num?)?.toDouble();
        lat = (loc['coordinates'][1] as num?)?.toDouble();
      }
    }

    return AdminHospitalItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Hospital',
      address: json['address']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      location: json['location'] as Map<String, dynamic>?,
      latitude: lat,
      longitude: lng,
      overallOccupancyPercent:
          (json['overall_occupancy_percent'] as num?)?.toDouble() ?? 0.0,
      icuOccupancyPercent:
          (json['icu_occupancy_percent'] as num?)?.toDouble() ?? 0.0,
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 0,
      totalOccupied: (json['total_occupied'] as num?)?.toInt() ?? 0,
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      accountStatus: json['account_status']?.toString() ?? 'active',
      lastCapacityUpdate: json['last_capacity_update']?.toString(),
    );
  }
}

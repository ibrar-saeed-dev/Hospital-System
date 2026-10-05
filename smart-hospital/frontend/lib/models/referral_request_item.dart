class ReferralRequestItem {
  final String id;
  final String patientReference;
  final String requesterId;
  final List<String> requiredResources;
  final String urgency;
  final Map<String, dynamic>? location;
  final double? latitude;
  final double? longitude;
  final String selectedHospitalId;
  final String? hospitalName;
  final String? hospitalAddress;
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final String status;
  final String? createdAt;
  final String? acceptedAt;
  final String? reservationExpiresAt;
  final double minutesLeft;

  ReferralRequestItem({
    required this.id,
    required this.patientReference,
    required this.requesterId,
    required this.requiredResources,
    required this.urgency,
    this.location,
    this.latitude,
    this.longitude,
    required this.selectedHospitalId,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalLatitude,
    this.hospitalLongitude,
    required this.status,
    this.createdAt,
    this.acceptedAt,
    this.reservationExpiresAt,
    required this.minutesLeft,
  });

  factory ReferralRequestItem.fromJson(Map<String, dynamic> json) {
    var rawRes = json['required_resources'];
    List<String> resList = [];
    if (rawRes is List) {
      resList = rawRes.map((e) => e.toString()).toList();
    }

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

    double? hLat = (json['hospital_latitude'] as num?)?.toDouble();
    double? hLng = (json['hospital_longitude'] as num?)?.toDouble();

    return ReferralRequestItem(
      id: json['id']?.toString() ?? '',
      patientReference: json['patient_reference']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      requiredResources: resList,
      urgency: json['urgency']?.toString() ?? 'low',
      location: json['location'] as Map<String, dynamic>?,
      latitude: lat,
      longitude: lng,
      selectedHospitalId: json['selected_hospital_id']?.toString() ?? '',
      hospitalName: json['hospital_name']?.toString(),
      hospitalAddress: json['hospital_address']?.toString(),
      hospitalLatitude: hLat,
      hospitalLongitude: hLng,
      status: json['status']?.toString() ?? 'request_sent',
      createdAt: json['created_at']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      reservationExpiresAt: json['reservation_expires_at']?.toString(),
      minutesLeft: (json['minutes_left'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isPending => status == 'request_sent' || status == 'hospital_reviewing';
}

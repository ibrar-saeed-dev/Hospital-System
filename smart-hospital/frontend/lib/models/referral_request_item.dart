class ReferralRequestItem {
  final String id;
  final String patientReference;
  final String requesterId;
  final List<String> requiredResources;
  final String urgency;
  final Map<String, dynamic>? location;
  final String selectedHospitalId;
  final String? hospitalName;
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
    required this.selectedHospitalId,
    this.hospitalName,
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

    return ReferralRequestItem(
      id: json['id']?.toString() ?? '',
      patientReference: json['patient_reference']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      requiredResources: resList,
      urgency: json['urgency']?.toString() ?? 'low',
      location: json['location'] as Map<String, dynamic>?,
      selectedHospitalId: json['selected_hospital_id']?.toString() ?? '',
      hospitalName: json['hospital_name']?.toString(),
      status: json['status']?.toString() ?? 'request_sent',
      createdAt: json['created_at']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      reservationExpiresAt: json['reservation_expires_at']?.toString(),
      minutesLeft: (json['minutes_left'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isPending => status == 'request_sent' || status == 'hospital_reviewing';
}

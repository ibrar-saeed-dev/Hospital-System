class CapacityItem {
  final String id;
  final String hospitalId;
  final String resourceType;
  final int total;
  final int occupied;
  final int reserved;
  final int temporarilyUnavailable;
  final int available;
  final String? lastUpdated;
  final double minutesSinceUpdate;
  final bool stale;

  CapacityItem({
    required this.id,
    required this.hospitalId,
    required this.resourceType,
    required this.total,
    required this.occupied,
    required this.reserved,
    required this.temporarilyUnavailable,
    required this.available,
    this.lastUpdated,
    required this.minutesSinceUpdate,
    required this.stale,
  });

  factory CapacityItem.fromJson(Map<String, dynamic> json) {
    return CapacityItem(
      id: json['id']?.toString() ?? '',
      hospitalId: json['hospital_id']?.toString() ?? '',
      resourceType: json['resource_type']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      occupied: (json['occupied'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      temporarilyUnavailable: (json['temporarily_unavailable'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      lastUpdated: json['last_updated']?.toString(),
      minutesSinceUpdate: (json['minutes_since_update'] as num?)?.toDouble() ?? 0.0,
      stale: json['stale'] as bool? ?? false,
    );
  }

  double get occupancyPercent {
    if (total == 0) return 0.0;
    return (occupied / total) * 100.0;
  }
}

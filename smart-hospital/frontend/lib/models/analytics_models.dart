class HospitalAnalytics {
  final int totalBeds;
  final int occupiedBeds;
  final int reservedBeds;
  final int availableBeds;
  final double overallOccupancyPercent;
  final double icuOccupancyPercent;
  final double avgResponseTimeMinutes;
  final List<ResourceOccupancyItem> resourceOccupancy;
  final Map<String, int> requestCountsByStatus;
  final List<DailyRequestItem> dailyRequests;

  HospitalAnalytics({
    required this.totalBeds,
    required this.occupiedBeds,
    required this.reservedBeds,
    required this.availableBeds,
    required this.overallOccupancyPercent,
    required this.icuOccupancyPercent,
    required this.avgResponseTimeMinutes,
    required this.resourceOccupancy,
    required this.requestCountsByStatus,
    required this.dailyRequests,
  });

  factory HospitalAnalytics.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final rawRes = json['resource_occupancy'] as List? ?? [];
    final rawStatus = json['request_counts_by_status'] as Map<String, dynamic>? ?? {};
    final rawDaily = json['daily_requests'] as List? ?? [];

    final statusMap = <String, int>{};
    rawStatus.forEach((key, val) {
      statusMap[key] = (val as num?)?.toInt() ?? 0;
    });

    return HospitalAnalytics(
      totalBeds: (totals['total'] as num?)?.toInt() ?? 0,
      occupiedBeds: (totals['occupied'] as num?)?.toInt() ?? 0,
      reservedBeds: (totals['reserved'] as num?)?.toInt() ?? 0,
      availableBeds: (totals['available'] as num?)?.toInt() ?? 0,
      overallOccupancyPercent: (totals['overall_occupancy_percent'] as num?)?.toDouble() ?? 0.0,
      icuOccupancyPercent: (json['icu_occupancy_percent'] as num?)?.toDouble() ?? 0.0,
      avgResponseTimeMinutes: (json['avg_response_time_minutes'] as num?)?.toDouble() ?? 0.0,
      resourceOccupancy: rawRes.map((e) => ResourceOccupancyItem.fromJson(e as Map<String, dynamic>)).toList(),
      requestCountsByStatus: statusMap,
      dailyRequests: rawDaily.map((e) => DailyRequestItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ResourceOccupancyItem {
  final String resourceType;
  final int total;
  final int occupied;
  final int reserved;
  final int available;
  final double occupancyPercent;

  ResourceOccupancyItem({
    required this.resourceType,
    required this.total,
    required this.occupied,
    required this.reserved,
    required this.available,
    required this.occupancyPercent,
  });

  factory ResourceOccupancyItem.fromJson(Map<String, dynamic> json) {
    return ResourceOccupancyItem(
      resourceType: json['resource_type']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      occupied: (json['occupied'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyRequestItem {
  final String date;
  final int count;

  DailyRequestItem({required this.date, required this.count});

  factory DailyRequestItem.fromJson(Map<String, dynamic> json) {
    return DailyRequestItem(
      date: json['date']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SystemAnalytics {
  final List<TopHospitalOccupancy> topHospitalsByOccupancy;
  final List<MostRequestedResource> mostRequestedResources;
  final Map<String, int> requestCountsByStatus;
  final Map<String, int> requestCountsByUrgency;
  final double avgResponseTimeMinutes;
  final List<DailyRequestItem> dailyRequests;
  final List<StaleHospitalItem> staleHospitals;

  SystemAnalytics({
    required this.topHospitalsByOccupancy,
    required this.mostRequestedResources,
    required this.requestCountsByStatus,
    required this.requestCountsByUrgency,
    required this.avgResponseTimeMinutes,
    required this.dailyRequests,
    required this.staleHospitals,
  });

  factory SystemAnalytics.fromJson(Map<String, dynamic> json) {
    final rawTop = json['top_hospitals_by_occupancy'] as List? ?? [];
    final rawRes = json['most_requested_resources'] as List? ?? [];
    final rawStatus = json['request_counts_by_status'] as Map<String, dynamic>? ?? {};
    final rawUrgency = json['request_counts_by_urgency'] as Map<String, dynamic>? ?? {};
    final rawDaily = json['daily_requests'] as List? ?? [];
    final rawStale = json['stale_hospitals'] as List? ?? [];

    final statusMap = <String, int>{};
    rawStatus.forEach((key, val) => statusMap[key] = (val as num?)?.toInt() ?? 0);

    final urgencyMap = <String, int>{};
    rawUrgency.forEach((key, val) => urgencyMap[key] = (val as num?)?.toInt() ?? 0);

    return SystemAnalytics(
      topHospitalsByOccupancy: rawTop.map((e) => TopHospitalOccupancy.fromJson(e as Map<String, dynamic>)).toList(),
      mostRequestedResources: rawRes.map((e) => MostRequestedResource.fromJson(e as Map<String, dynamic>)).toList(),
      requestCountsByStatus: statusMap,
      requestCountsByUrgency: urgencyMap,
      avgResponseTimeMinutes: (json['avg_response_time_minutes'] as num?)?.toDouble() ?? 0.0,
      dailyRequests: rawDaily.map((e) => DailyRequestItem.fromJson(e as Map<String, dynamic>)).toList(),
      staleHospitals: rawStale.map((e) => StaleHospitalItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  int get totalRequests {
    int sum = 0;
    requestCountsByStatus.forEach((_, count) => sum += count);
    return sum;
  }
}

class TopHospitalOccupancy {
  final String hospitalId;
  final String name;
  final int totalCapacity;
  final int totalOccupied;
  final double occupancyPercent;

  TopHospitalOccupancy({
    required this.hospitalId,
    required this.name,
    required this.totalCapacity,
    required this.totalOccupied,
    required this.occupancyPercent,
  });

  factory TopHospitalOccupancy.fromJson(Map<String, dynamic> json) {
    return TopHospitalOccupancy(
      hospitalId: json['hospital_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 0,
      totalOccupied: (json['total_occupied'] as num?)?.toInt() ?? 0,
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MostRequestedResource {
  final String resourceType;
  final int count;

  MostRequestedResource({required this.resourceType, required this.count});

  factory MostRequestedResource.fromJson(Map<String, dynamic> json) {
    return MostRequestedResource(
      resourceType: json['resource_type']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class StaleHospitalItem {
  final String hospitalId;
  final String name;
  final String? lastUpdated;
  final double? minutesSinceUpdate;

  StaleHospitalItem({
    required this.hospitalId,
    required this.name,
    this.lastUpdated,
    this.minutesSinceUpdate,
  });

  factory StaleHospitalItem.fromJson(Map<String, dynamic> json) {
    return StaleHospitalItem(
      hospitalId: json['hospital_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      lastUpdated: json['last_updated']?.toString(),
      minutesSinceUpdate: (json['minutes_since_update'] as num?)?.toDouble(),
    );
  }
}

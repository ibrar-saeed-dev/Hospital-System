class CapacityDetail {
  final int total;
  final int occupied;
  final int reserved;
  final int temporarilyUnavailable;
  final int available;

  CapacityDetail({
    required this.total,
    required this.occupied,
    required this.reserved,
    required this.temporarilyUnavailable,
    required this.available,
  });

  factory CapacityDetail.fromJson(Map<String, dynamic> json) {
    return CapacityDetail(
      total: (json['total'] as num?)?.toInt() ?? 0,
      occupied: (json['occupied'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      temporarilyUnavailable: (json['temporarily_unavailable'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
    );
  }
}

class HospitalMatchItem {
  final String hospitalId;
  final String name;
  final String address;
  final String contact;
  final Map<String, dynamic>? location;
  final double? latitude;
  final double? longitude;
  final double distanceKm;
  final double estimatedTravelMinutes;
  final double matchPercent;
  final Map<String, CapacityDetail> capacities;
  final String? lastUpdated;
  final bool stale;

  HospitalMatchItem({
    required this.hospitalId,
    required this.name,
    required this.address,
    required this.contact,
    this.location,
    this.latitude,
    this.longitude,
    required this.distanceKm,
    required this.estimatedTravelMinutes,
    required this.matchPercent,
    required this.capacities,
    this.lastUpdated,
    required this.stale,
  });

  factory HospitalMatchItem.fromJson(Map<String, dynamic> json) {
    final rawCaps = json['capacities'] as Map<String, dynamic>? ?? {};
    final capsMap = <String, CapacityDetail>{};
    rawCaps.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        capsMap[key] = CapacityDetail.fromJson(val);
      }
    });

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

    return HospitalMatchItem(
      hospitalId: json['hospital_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      location: json['location'] as Map<String, dynamic>?,
      latitude: lat,
      longitude: lng,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedTravelMinutes: (json['estimated_travel_minutes'] as num?)?.toDouble() ?? 0.0,
      matchPercent: (json['match_percent'] as num?)?.toDouble() ?? 0.0,
      capacities: capsMap,
      lastUpdated: json['last_updated']?.toString(),
      stale: json['stale'] == true,
    );
  }
}

class HospitalExcludedItem {
  final String hospitalId;
  final String name;
  final String address;
  final String contact;
  final Map<String, dynamic>? location;
  final double? latitude;
  final double? longitude;
  final double distanceKm;
  final double estimatedTravelMinutes;
  final String exclusionReason;
  final Map<String, CapacityDetail> capacities;
  final String? lastUpdated;
  final bool stale;

  HospitalExcludedItem({
    required this.hospitalId,
    required this.name,
    required this.address,
    required this.contact,
    this.location,
    this.latitude,
    this.longitude,
    required this.distanceKm,
    required this.estimatedTravelMinutes,
    required this.exclusionReason,
    required this.capacities,
    this.lastUpdated,
    required this.stale,
  });

  factory HospitalExcludedItem.fromJson(Map<String, dynamic> json) {
    final rawCaps = json['capacities'] as Map<String, dynamic>? ?? {};
    final capsMap = <String, CapacityDetail>{};
    rawCaps.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        capsMap[key] = CapacityDetail.fromJson(val);
      }
    });

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

    return HospitalExcludedItem(
      hospitalId: json['hospital_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      location: json['location'] as Map<String, dynamic>?,
      latitude: lat,
      longitude: lng,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedTravelMinutes: (json['estimated_travel_minutes'] as num?)?.toDouble() ?? 0.0,
      exclusionReason: json['exclusion_reason']?.toString() ?? 'Not suitable',
      capacities: capsMap,
      lastUpdated: json['last_updated']?.toString(),
      stale: json['stale'] == true,
    );
  }
}

class SearchResponseModel {
  final List<HospitalMatchItem> suitable;
  final List<HospitalExcludedItem> excluded;

  SearchResponseModel({
    required this.suitable,
    required this.excluded,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawSuitable = json['suitable'] as List? ?? [];
    final rawExcluded = json['excluded'] as List? ?? [];

    return SearchResponseModel(
      suitable: rawSuitable
          .map((item) => HospitalMatchItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      excluded: rawExcluded
          .map((item) => HospitalExcludedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

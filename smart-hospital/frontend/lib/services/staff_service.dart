import '../models/capacity_item.dart';
import '../models/referral_request_item.dart';
import 'api_client.dart';

class StaffService {
  final ApiClient _apiClient;

  StaffService(this._apiClient);

  Future<List<CapacityItem>> getMyHospitalCapacity() async {
    final response = await _apiClient.dio.get('/capacity/my-hospital');
    final List list = response.data;
    return list.map((item) => CapacityItem.fromJson(item)).toList();
  }

  Future<CapacityItem> updateCapacity(
    String resourceType, {
    required int total,
    required int occupied,
    required int temporarilyUnavailable,
  }) async {
    final response = await _apiClient.dio.put(
      '/capacity/$resourceType',
      data: {
        'total': total,
        'occupied': occupied,
        'temporarily_unavailable': temporarilyUnavailable,
      },
    );
    return CapacityItem.fromJson(response.data);
  }

  Future<List<ReferralRequestItem>> getHospitalRequests() async {
    final response = await _apiClient.dio.get('/requests/hospital');
    final List list = response.data;
    return list.map((item) => ReferralRequestItem.fromJson(item)).toList();
  }

  Future<ReferralRequestItem> acceptRequest(String id) async {
    final response = await _apiClient.dio.patch('/requests/$id/accept');
    return ReferralRequestItem.fromJson(response.data);
  }

  Future<ReferralRequestItem> rejectRequest(String id) async {
    final response = await _apiClient.dio.patch('/requests/$id/reject');
    return ReferralRequestItem.fromJson(response.data);
  }

  Future<ReferralRequestItem> updateRequestStatus(String id, String newStatus) async {
    final response = await _apiClient.dio.patch(
      '/requests/$id/status',
      data: {'status': newStatus},
    );
    return ReferralRequestItem.fromJson(response.data);
  }
}

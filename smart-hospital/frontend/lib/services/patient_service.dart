import 'package:dio/dio.dart';
import '../models/hospital_search_result.dart';
import '../models/referral_request_item.dart';
import 'api_client.dart';

class PatientService {
  final ApiClient apiClient;

  PatientService({required this.apiClient});

  Future<SearchResponseModel> searchHospitals({
    required List<String> requiredResources,
    required double latitude,
    required double longitude,
    double maxDistanceKm = 30.0,
  }) async {
    final response = await apiClient.dio.post(
      '/search',
      data: {
        'required_resources': requiredResources,
        'latitude': latitude,
        'longitude': longitude,
        'max_distance_km': maxDistanceKm,
      },
    );

    return SearchResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createReferralRequest({
    required String patientReference,
    required List<String> requiredResources,
    required String urgency,
    required double latitude,
    required double longitude,
    required String selectedHospitalId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/requests',
        data: {
          'patient_reference': patientReference.trim(),
          'required_resources': requiredResources,
          'urgency': urgency.toLowerCase(),
          'latitude': latitude,
          'longitude': longitude,
          'selected_hospital_id': selectedHospitalId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: "Bed was just taken, please search again",
        );
      }
      rethrow;
    }
  }

  Future<List<ReferralRequestItem>> getMyRequests() async {
    final response = await apiClient.dio.get('/requests/mine');
    final list = response.data as List;
    return list
        .map((item) => ReferralRequestItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelRequest(String requestId) async {
    await apiClient.dio.patch('/requests/$requestId/cancel');
  }
}

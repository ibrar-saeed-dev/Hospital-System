import '../models/analytics_models.dart';
import 'api_client.dart';

class AnalyticsService {
  final ApiClient apiClient;

  AnalyticsService(this.apiClient);

  Future<HospitalAnalytics> getHospitalAnalytics() async {
    final response = await apiClient.dio.get('/analytics/hospital');
    return HospitalAnalytics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SystemAnalytics> getSystemAnalytics() async {
    final response = await apiClient.dio.get('/analytics/system');
    return SystemAnalytics.fromJson(response.data as Map<String, dynamic>);
  }
}

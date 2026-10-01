import '../models/admin_hospital_item.dart';
import 'api_client.dart';

class AdminService {
  final ApiClient apiClient;

  AdminService(this.apiClient);

  Future<List<AdminHospitalItem>> getAllHospitals() async {
    final response = await apiClient.dio.get('/admin/hospitals');
    final list = response.data as List;
    return list.map((item) => AdminHospitalItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> verifyHospital(String hospitalId, String status) async {
    await apiClient.dio.patch(
      '/admin/hospitals/$hospitalId/verify',
      data: {'verification_status': status},
    );
  }
}

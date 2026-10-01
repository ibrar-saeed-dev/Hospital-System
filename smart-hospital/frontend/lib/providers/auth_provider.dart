import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  String? _token;
  String? _role;
  String? _name;
  String? _hospitalId;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  String? get token => _token;
  String? get role => _role;
  String? get name => _name;
  String? get hospitalId => _hospitalId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get errorMessage => _errorMessage;

  ApiClient get apiClient => _apiClient;

  AuthProvider() {
    ApiClient.onUnauthorized = logout;
    restoreSession();
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _role = prefs.getString('role');
      _name = prefs.getString('name');
      _hospitalId = prefs.getString('hospital_id');
    } catch (e) {
      _token = null;
      _role = null;
      _name = null;
      _hospitalId = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password.trim(),
      });

      final data = response.data;
      _token = data['access_token'];
      _role = data['role'];
      _name = data['name'];
      _hospitalId = data['hospital_id'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('role', _role!);
      await prefs.setString('name', _name ?? '');
      if (_hospitalId != null) {
        await prefs.setString('hospital_id', _hospitalId!);
      } else {
        await prefs.remove('hospital_id');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.error?.toString() ?? "Login failed. Please check credentials.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred during login.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _name = null;
    _hospitalId = null;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('hospital_id');

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

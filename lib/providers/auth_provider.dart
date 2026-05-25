import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(username, password);
      if (result.containsKey('error')) {
        _isLoading = false;
        notifyListeners();
        return result['error'];
      }
      ApiService.setToken(result['token']);
      final userData = result['user'];
      _currentUser = UserModel(
        id: userData['id'],
        username: userData['username'],
        password: '',
        fullName: userData['fullName'],
        role: userData['role'],
        email: userData['email'],
        phone: userData['phone'],
        salary: (userData['salary'] as num?)?.toDouble(),
        department: userData['department'],
        position: userData['position'],
        joinDate: userData['joinDate'],
        isActive: userData['isActive'] ?? true,
      );
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Login failed: ${e.toString()}';
    }
  }

  Future<String?> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String? phone,
    String? department,
    String? position,
  }) async {
    try {
      final result = await ApiService.register(
        username: username,
        password: password,
        fullName: fullName,
        email: email,
        phone: phone,
        department: department,
        position: position,
      );
      if (result.containsKey('token')) {
        ApiService.setToken(result['token']);
        return null;
      }
      return result['error'] ?? 'Registration failed';
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  void logout() {
    _currentUser = null;
    ApiService.setToken(null);
    notifyListeners();
  }
}

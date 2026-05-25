import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  final DatabaseService _db = DatabaseService.instance;

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.login(username, password);
      _currentUser = await _db.getUserByUsername(username);
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

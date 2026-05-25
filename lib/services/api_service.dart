import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Android emulator use 10.0.2.2, for web/iOS simulator use localhost
  static const String baseUrl = 'http://localhost:3000/api';
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'error':
            'Backend server not reachable.\nStart the API: cd backend && npm run dev',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String? phone,
    String? department,
    String? position,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'department': department,
        'position': position,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ==================== USERS ====================

  static Future<List<dynamic>> getEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createEmployee({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String? phone,
    double? salary,
    String? department,
    String? position,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'salary': salary,
        'department': department,
        'position': position,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<void> deleteEmployee(int id) async {
    await http.delete(Uri.parse('$baseUrl/users/$id'), headers: _headers);
  }

  // ==================== ATTENDANCE ====================

  static Future<List<dynamic>> getAttendance({
    int? userId,
    String? month,
  }) async {
    final params = <String, String>{};
    if (userId != null) params['userId'] = userId.toString();
    if (month != null) params['month'] = month;

    final uri = Uri.parse(
      '$baseUrl/attendance',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> clockIn() async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/clockin'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> clockOut() async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/clockout'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateAttendanceStatus(
    int id,
    String status, {
    String? remarks,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/attendance/$id'),
      headers: _headers,
      body: jsonEncode({'status': status, 'remarks': remarks}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAttendanceStats(
    int userId,
    String month,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/stats/$userId/$month'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ==================== PAYROLL ====================

  static Future<List<dynamic>> getPayroll({int? userId, String? period}) async {
    final params = <String, String>{};
    if (userId != null) params['userId'] = userId.toString();
    if (period != null) params['period'] = period;

    final uri = Uri.parse('$baseUrl/payroll').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> generatePayroll(String period) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payroll/generate'),
      headers: _headers,
      body: jsonEncode({'period': period}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markPayrollAsPaid(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/payroll/$id/pay'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }
}

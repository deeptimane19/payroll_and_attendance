// Database wrapper - delegates to ApiService for Node.js + PostgreSQL backend
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/payroll_model.dart';
import 'api_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  // ==================== USER OPERATIONS ====================

  Future<UserModel> login(String username, String password) async {
    final result = await ApiService.login(username, password);
    final userData = result['user'];
    return UserModel(
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
  }

  Future<int> insertUser(UserModel user) async {
    final result = await ApiService.createEmployee(
      username: user.username,
      password: user.password,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      salary: user.salary,
      department: user.department,
      position: user.position,
    );
    return result['id'] as int? ?? 0;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final users = await ApiService.getEmployees();
    for (final u in users) {
      if (u['username'] == username) {
        return _parseUser(u);
      }
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    try {
      final result = await ApiService.getMe();
      if (result['id'] == id) return _parseUser(result);
    } catch (_) {}
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final data = await ApiService.getEmployees();
    return data.map((u) => _parseUser(u)).toList();
  }

  Future<List<UserModel>> getEmployees() async {
    final data = await ApiService.getEmployees();
    return data.map((u) => _parseUser(u)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    await ApiService.updateEmployee(user.id!, {
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'salary': user.salary,
      'department': user.department,
      'position': user.position,
    });
    return 1;
  }

  Future<int> deleteUser(int id) async {
    await ApiService.deleteEmployee(id);
    return 1;
  }

  Future<bool> authenticate(String username, String password) async {
    try {
      await ApiService.login(username, password);
      return true;
    } catch (_) {
      return false;
    }
  }

  UserModel _parseUser(Map<String, dynamic> u) {
    return UserModel(
      id: u['id'],
      username: u['username'] ?? '',
      password: '',
      fullName: u['fullName'] ?? '',
      role: u['role'] ?? 'employee',
      email: u['email'],
      phone: u['phone'],
      salary: (u['salary'] as num?)?.toDouble(),
      department: u['department'],
      position: u['position'],
      joinDate: u['joinDate'] ?? u['join_date'],
      isActive: u['isActive'] ?? u['is_active'] ?? true,
    );
  }

  // ==================== ATTENDANCE OPERATIONS ====================

  Future<int> insertAttendance(AttendanceModel attendance) async {
    if (attendance.clockIn != null && attendance.clockOut == null) {
      await ApiService.clockIn();
    }
    return 0;
  }

  Future<List<AttendanceModel>> getAttendanceByUser(int userId) async {
    final data = await ApiService.getAttendance(userId: userId);
    return data.map((a) => _parseAttendance(a)).toList();
  }

  Future<List<AttendanceModel>> getAttendanceByUserAndMonth(
    int userId,
    String month,
  ) async {
    final data = await ApiService.getAttendance(userId: userId, month: month);
    return data.map((a) => _parseAttendance(a)).toList();
  }

  Future<AttendanceModel?> getAttendanceByUserAndDate(
    int userId,
    String date,
  ) async {
    final data = await ApiService.getAttendance(userId: userId);
    final matches = data.where((a) => a['date'] == date).toList();
    if (matches.isEmpty) return null;
    return _parseAttendance(matches.first);
  }

  Future<List<AttendanceModel>> getAllAttendanceByDate(String date) async {
    final data = await ApiService.getAttendance();
    return data
        .where((a) => a['date'] == date)
        .map((a) => _parseAttendance(a))
        .toList();
  }

  Future<List<AttendanceModel>> getAllAttendanceByMonth(String month) async {
    final data = await ApiService.getAttendance(month: month);
    return data.map((a) => _parseAttendance(a)).toList();
  }

  Future<int> updateAttendance(AttendanceModel attendance) async {
    if (attendance.clockOut != null && attendance.id != null) {
      await ApiService.clockOut();
    }
    if (attendance.status != null && attendance.id != null) {
      try {
        await ApiService.updateAttendanceStatus(
          attendance.id!,
          attendance.status!,
        );
      } catch (_) {}
    }
    return 1;
  }

  AttendanceModel _parseAttendance(Map<String, dynamic> a) {
    return AttendanceModel(
      id: a['id'],
      userId: a['userId'] ?? a['user_id'],
      date: a['date'] ?? '',
      clockIn: a['clockIn'] ?? a['clock_in'],
      clockOut: a['clockOut'] ?? a['clock_out'],
      status: a['status'],
      remarks: a['remarks'],
    );
  }

  // ==================== PAYROLL OPERATIONS ====================

  Future<int> insertPayroll(PayrollModel payroll) async {
    await ApiService.generatePayroll(payroll.period);
    return 0;
  }

  Future<List<PayrollModel>> getPayrollByUser(int userId) async {
    final data = await ApiService.getPayroll(userId: userId);
    return data.map((p) => _parsePayroll(p)).toList();
  }

  Future<List<PayrollModel>> getAllPayroll() async {
    final data = await ApiService.getPayroll();
    return data.map((p) => _parsePayroll(p)).toList();
  }

  Future<List<PayrollModel>> getPayrollByPeriod(String period) async {
    final data = await ApiService.getPayroll(period: period);
    return data.map((p) => _parsePayroll(p)).toList();
  }

  Future<PayrollModel?> getPayrollByUserAndPeriod(
    int userId,
    String period,
  ) async {
    final data = await ApiService.getPayroll(userId: userId, period: period);
    if (data.isEmpty) return null;
    return _parsePayroll(data.first);
  }

  Future<int> updatePayroll(PayrollModel payroll) async {
    if (payroll.status == 'paid' && payroll.id != null) {
      await ApiService.markPayrollAsPaid(payroll.id!);
    }
    return 1;
  }

  PayrollModel _parsePayroll(Map<String, dynamic> p) {
    return PayrollModel(
      id: p['id'],
      userId: p['userId'] ?? p['user_id'],
      period: p['period'] ?? '',
      basicSalary: (p['basicSalary'] ?? p['basic_salary'] ?? 0).toDouble(),
      allowances: (p['allowances'] ?? 0).toDouble(),
      deductions: (p['deductions'] ?? 0).toDouble(),
      totalSalary: (p['totalSalary'] ?? p['total_salary'] ?? 0).toDouble(),
      paymentDate: p['paymentDate'] ?? p['payment_date'],
      status: p['status'] ?? 'pending',
      totalWorkingDays: p['totalWorkingDays'] ?? p['total_working_days'],
      totalPresent: p['totalPresent'] ?? p['total_present'],
      totalAbsent: p['totalAbsent'] ?? p['total_absent'],
      totalLate: p['totalLate'] ?? p['total_late'],
      totalHalfDays: p['totalHalfDays'] ?? p['total_half_days'],
      remarks: p['remarks'],
    );
  }

  // ==================== REPORTING ====================

  Future<int> getPresentCount(int userId, String month) async {
    final stats = await ApiService.getAttendanceStats(userId, month);
    return stats['present'] as int? ?? 0;
  }

  Future<int> getAbsentCount(int userId, String month) async {
    final stats = await ApiService.getAttendanceStats(userId, month);
    return stats['absent'] as int? ?? 0;
  }

  Future<double> getTotalPayrollByPeriod(String period) async {
    return 0;
  }
}

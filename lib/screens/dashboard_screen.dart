import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/payroll_model.dart';
import 'login_screen.dart';
import 'employee_screen.dart';
import 'attendance_screen.dart';
import 'payroll_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<AttendanceModel> _todayAttendance = [];
  List<PayrollModel> _recentPayroll = [];
  List<UserModel> _employees = [];
  int _presentCount = 0;
  int _totalEmployees = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

      if (auth.isAdmin) {
        _todayAttendance = await _db.getAllAttendanceByDate(today);
        _recentPayroll = await _db.getAllPayroll();
        _employees = await _db.getEmployees();
        _presentCount = _todayAttendance
            .where((a) => a.status == 'present')
            .length;
        _totalEmployees = _employees.length;
      } else {
        final userId = auth.currentUser!.id!;
        final userAttendance = await _db.getAttendanceByUserAndMonth(
          userId,
          currentMonth,
        );
        _todayAttendance = userAttendance
            .where((a) => a.date == today)
            .toList();
        _recentPayroll = await _db.getPayrollByUser(userId);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${user.fullName}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.role.toUpperCase()} | ${user.department ?? "N/A"}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (auth.isAdmin) ...[
                      // Admin stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Employees',
                              '$_totalEmployees',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Present Today',
                              '$_presentCount',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Absent Today',
                              '${_todayAttendance.length - _presentCount}',
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Payroll Records',
                              '${_recentPayroll.length}',
                              Icons.payments,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Employee stats
                      _buildAttendanceStatusCard(user),
                    ],

                    const SizedBox(height: 20),

                    // Today's Attendance Section
                    const Text(
                      "Today's Attendance",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTodayAttendanceList(),

                    const SizedBox(height: 20),

                    // Recent Payroll Section
                    const Text(
                      'Recent Payroll',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRecentPayrollList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Color(0xFF1565C0)),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.currentUser?.fullName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  auth.currentUser?.role ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.dashboard,
            'Dashboard',
            () => Navigator.pop(context),
          ),
          _buildDrawerItem(Icons.people, 'Employees', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeScreen()),
            );
          }),
          _buildDrawerItem(Icons.fingerprint, 'Attendance', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
            );
          }),
          _buildDrawerItem(Icons.payments, 'Payroll', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PayrollScreen()),
            );
          }),
          _buildDrawerItem(Icons.assessment, 'Reports', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            );
          }),
          const Divider(),
          _buildDrawerItem(Icons.logout, 'Logout', () {
            Navigator.pop(context);
            auth.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusCard(UserModel user) {
    final isClockedIn = _todayAttendance.any(
      (a) => a.clockIn != null && a.clockOut == null,
    );
    final isClockedOut = _todayAttendance.any((a) => a.clockOut != null);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isClockedOut
                  ? Icons.check_circle
                  : isClockedIn
                  ? Icons.access_time
                  : Icons.cancel,
              size: 48,
              color: isClockedOut
                  ? Colors.green
                  : isClockedIn
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClockedOut
                      ? 'Clocked Out'
                      : isClockedIn
                      ? 'Clocked In'
                      : 'Not Clocked In',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isClockedIn) ...[
                  Text(
                    'Clock In: ${_todayAttendance.firstWhere((a) => a.clockIn != null).clockIn}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceList() {
    if (_todayAttendance.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No attendance records for today',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _todayAttendance.length,
        itemBuilder: (context, index) {
          final attendance = _todayAttendance[index];
          final statusColor = attendance.status == 'present'
              ? Colors.green
              : attendance.status == 'late'
              ? Colors.orange
              : attendance.status == 'half-day'
              ? Colors.purple
              : Colors.red;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(
                attendance.status == 'present' ? Icons.check : Icons.close,
                color: statusColor,
              ),
            ),
            title: Text(attendance.clockIn ?? 'Not clocked in'),
            subtitle: Text('Status: ${attendance.status ?? "N/A"}'),
            trailing: Text(attendance.clockOut ?? ''),
          );
        },
      ),
    );
  }

  Widget _buildRecentPayrollList() {
    if (_recentPayload.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No payroll records found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentPayroll.length > 5 ? 5 : _recentPayroll.length,
        itemBuilder: (context, index) {
          final payroll = _recentPayroll[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.payments, color: Color(0xFF1565C0)),
            ),
            title: Text('Period: ${payroll.period}'),
            subtitle: Text(
              'Salary: \$${payroll.totalSalary.toStringAsFixed(2)}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: payroll.status == 'paid'
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payroll.status.toUpperCase(),
                style: TextStyle(
                  color: payroll.status == 'paid'
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Fix typo in property name
  List<PayrollModel> get _recentPayload => _recentPayroll;
}

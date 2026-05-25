import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/payroll_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<UserModel> _employees = [];
  List<AttendanceModel> _allAttendance = [];
  List<PayrollModel> _allPayroll = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  bool _showAttendanceReport = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _employees = await _db.getEmployees();
    _allAttendance = await _db.getAllAttendanceByMonth(_selectedMonth);
    _allPayroll = await _db.getPayrollByPeriod(_selectedMonth);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month selector
                  _buildMonthSelector(),
                  const SizedBox(height: 16),

                  // Report type toggle
                  Row(
                    children: [
                      Expanded(
                        child: _buildReportTypeButton(
                          'Attendance Report',
                          Icons.fingerprint,
                          _showAttendanceReport,
                          () => setState(() => _showAttendanceReport = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildReportTypeButton(
                          'Payroll Report',
                          Icons.payments,
                          !_showAttendanceReport,
                          () => setState(() => _showAttendanceReport = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary cards
                  _buildSummaryCards(),
                  const SizedBox(height: 16),

                  // Detailed report
                  _showAttendanceReport
                      ? _buildAttendanceReport()
                      : _buildPayrollReport(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: () async {
        // Month picker dialog
        final now = DateTime.now();
        final currentYear = now.year;
        final months = List.generate(
          12,
          (i) => DateFormat('MMMM').format(DateTime(2020, i + 1)),
        );

        final result = await showDialog<Map<String, int>>(
          context: context,
          builder: (ctx) {
            int selectedYear = currentYear;
            int selectedMonth = int.parse(_selectedMonth.split('-')[1]);
            return StatefulBuilder(
              builder: (ctx, setDialogState) {
                return AlertDialog(
                  title: const Text('Select Month'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () =>
                                setDialogState(() => selectedYear--),
                          ),
                          Text(
                            '$selectedYear',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () =>
                                setDialogState(() => selectedYear++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(12, (i) {
                          final isSelected = selectedMonth == i + 1;
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, {
                              'year': selectedYear,
                              'month': i + 1,
                            }),
                            child: Container(
                              width: 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey,
                                ),
                              ),
                              child: Text(
                                months[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );

        if (result != null) {
          _selectedMonth =
              '${result['year']}-${result['month']!.toString().padLeft(2, '0')}';
          _loadData();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFF1565C0)),
            const SizedBox(width: 12),
            Text(
              'Period: $_selectedMonth',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeButton(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_showAttendanceReport) {
      final totalPresent = _allAttendance
          .where((a) => a.status == 'present')
          .length;
      final totalAbsent = _allAttendance
          .where((a) => a.status == 'absent')
          .length;
      final totalLate = _allAttendance.where((a) => a.status == 'late').length;
      final totalLeaves = _allAttendance
          .where((a) => a.status == 'leave')
          .length;

      return Row(
        children: [
          Expanded(
            child: _buildMiniCard('Present', '$totalPresent', Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildMiniCard('Absent', '$totalAbsent', Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildMiniCard('Late', '$totalLate', Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildMiniCard('Leave', '$totalLeaves', Colors.blue)),
        ],
      );
    } else {
      double totalBasic = 0;
      double totalDeductions = 0;
      double totalPaid = 0;
      double totalPending = 0;

      for (final p in _allPayroll) {
        totalBasic += p.basicSalary;
        totalDeductions += p.deductions;
        if (p.status == 'paid') {
          totalPaid += p.totalSalary;
        } else {
          totalPending += p.totalSalary;
        }
      }

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  'Total Basic',
                  '\$${totalBasic.toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniCard(
                  'Deductions',
                  '\$${totalDeductions.toStringAsFixed(0)}',
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  'Paid',
                  '\$${totalPaid.toStringAsFixed(0)}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniCard(
                  'Pending',
                  '\$${totalPending.toStringAsFixed(0)}',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceReport() {
    if (_employees.isEmpty) {
      return const Center(child: Text('No employees found'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee Attendance Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._employees.map((emp) {
          final empAttendance = _allAttendance
              .where((a) => a.userId == emp.id)
              .toList();
          final present = empAttendance
              .where((a) => a.status == 'present')
              .length;
          final absent = empAttendance
              .where((a) => a.status == 'absent')
              .length;
          final late = empAttendance.where((a) => a.status == 'late').length;
          final leave = empAttendance.where((a) => a.status == 'leave').length;
          final total = present + absent + late + leave;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildAttendanceDot('P', present, Colors.green),
                      const SizedBox(width: 4),
                      _buildAttendanceDot('A', absent, Colors.red),
                      const SizedBox(width: 4),
                      _buildAttendanceDot('L', late, Colors.orange),
                      const SizedBox(width: 4),
                      _buildAttendanceDot('LV', leave, Colors.blue),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: present / (total > 0 ? total : 1),
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attendance rate: ${(present / (total > 0 ? total : 1) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttendanceDot(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPayrollReport() {
    if (_allPayroll.isEmpty) {
      return const Center(child: Text('No payroll records for this period'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payroll Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._allPayroll.map((payroll) {
          final emp = _employees.firstWhere(
            (e) => e.id == payroll.userId,
            orElse: () => UserModel(
              id: 0,
              username: 'unknown',
              password: '',
              fullName: 'Unknown',
              role: 'employee',
            ),
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(
                  emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(emp.fullName),
              subtitle: Text(
                'Net: \$${payroll.totalSalary.toStringAsFixed(2)} | '
                'Deductions: \$${payroll.deductions.toStringAsFixed(2)}',
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
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

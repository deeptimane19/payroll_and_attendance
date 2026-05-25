import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<AttendanceModel> _attendanceRecords = [];
  List<UserModel> _employees = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    if (auth.isAdmin) {
      _employees = await _db.getEmployees();
      if (_selectedUserId != null) {
        _attendanceRecords = await _db.getAttendanceByUserAndMonth(
          _selectedUserId!,
          _selectedMonth,
        );
      } else {
        _attendanceRecords = await _db.getAllAttendanceByMonth(_selectedMonth);
      }
    } else {
      _attendanceRecords = await _db.getAttendanceByUserAndMonth(
        auth.currentUser!.id!,
        _selectedMonth,
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _clockIn() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id!;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateFormat('HH:mm:ss').format(DateTime.now());

    final existing = await _db.getAttendanceByUserAndDate(userId, today);
    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already clocked in today'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final attendance = AttendanceModel(
      userId: userId,
      date: today,
      clockIn: now,
      status: 'present',
    );
    await _db.insertAttendance(attendance);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clocked in successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clockOut() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id!;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateFormat('HH:mm:ss').format(DateTime.now());

    final existing = await _db.getAttendanceByUserAndDate(userId, today);
    if (existing == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please clock in first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (existing.clockOut != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already clocked out today'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final updated = AttendanceModel(
      id: existing.id,
      userId: userId,
      date: today,
      clockIn: existing.clockIn,
      clockOut: now,
      status: existing.status,
      remarks: existing.remarks,
    );
    await _db.updateAttendance(updated);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clocked out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateStatus(AttendanceModel attendance) async {
    final statuses = ['present', 'absent', 'late', 'half-day', 'leave'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Status'),
        children: statuses.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, status),
            child: Text(status.toUpperCase()),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      final updated = AttendanceModel(
        id: attendance.id,
        userId: attendance.userId,
        date: attendance.date,
        clockIn: attendance.clockIn,
        clockOut: attendance.clockOut,
        status: selected,
        remarks: attendance.remarks,
      );
      await _db.updateAttendance(updated);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // Month Picker
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      // Simple month/year picker dialog
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
                          int selectedMonth = int.parse(
                            _selectedMonth.split('-')[1],
                          );
                          return StatefulBuilder(
                            builder: (ctx, setDialogState) {
                              return AlertDialog(
                                title: const Text('Select Month'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: () {
                                            setDialogState(() {
                                              selectedYear--;
                                            });
                                          },
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
                                          onPressed: () {
                                            setDialogState(() {
                                              selectedYear++;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: List.generate(12, (i) {
                                        final isSelected =
                                            selectedMonth == i + 1;
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.pop(ctx, {
                                              'year': selectedYear,
                                              'month': i + 1,
                                            });
                                          },
                                          child: Container(
                                            width: 80,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF1565C0)
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                color: isSelected
                                                    ? Colors.white
                                                    : null,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedMonth,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedUserId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        labelText: 'Employee',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._employees.map(
                          (emp) => DropdownMenuItem(
                            value: emp.id,
                            child: Text(emp.fullName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        _selectedUserId = value;
                        _loadData();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quick clock-in/out for employees
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clockIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Clock In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clockOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Clock Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Attendance list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                ? const Center(
                    child: Text(
                      'No attendance records found',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceRecords[index];
                        final statusColor = record.status == 'present'
                            ? Colors.green
                            : record.status == 'late'
                            ? Colors.orange
                            : record.status == 'half-day'
                            ? Colors.purple
                            : record.status == 'leave'
                            ? Colors.blue
                            : Colors.red;
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withValues(
                                alpha: 0.2,
                              ),
                              child: Icon(
                                record.status == 'present'
                                    ? Icons.check
                                    : record.status == 'late'
                                    ? Icons.access_time
                                    : record.status == 'half-day'
                                    ? Icons.wb_sunny
                                    : record.status == 'leave'
                                    ? Icons.beach_access
                                    : Icons.close,
                                color: statusColor,
                              ),
                            ),
                            title: Text(record.date),
                            subtitle: Text(
                              'In: ${record.clockIn ?? "--"} | Out: ${record.clockOut ?? "--"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    record.status?.toUpperCase() ?? 'N/A',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _updateStatus(record),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/payroll_model.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<PayrollModel> _payrolls = [];
  bool _isLoading = true;
  String _selectedPeriod = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    if (auth.isAdmin) {
      _payrolls = await _db.getPayrollByPeriod(_selectedPeriod);
    } else {
      _payrolls = await _db.getPayrollByUser(auth.currentUser!.id!);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generatePayroll() async {
    // Calculate payroll for all employees for the selected period
    final employees = await _db.getEmployees();
    int generated = 0;

    for (final emp in employees) {
      final existing = await _db.getPayrollByUserAndPeriod(
        emp.id!,
        _selectedPeriod,
      );
      if (existing != null) continue;

      // Get attendance stats
      final presentCount = await _db.getPresentCount(emp.id!, _selectedPeriod);
      final absentCount = await _db.getAbsentCount(emp.id!, _selectedPeriod);

      // Calculate salary based on attendance (simplified)
      final basicSalary = emp.salary ?? 0;
      final workingDays = 22; // approximate working days per month
      final dailyRate = workingDays > 0 ? basicSalary / workingDays : 0;
      final totalSalary = (presentCount * dailyRate).toDouble();
      final deductions = (absentCount * dailyRate).toDouble();

      final payroll = PayrollModel(
        userId: emp.id!,
        period: _selectedPeriod,
        basicSalary: basicSalary,
        allowances: 0,
        deductions: deductions,
        totalSalary: totalSalary,
        status: 'pending',
        totalWorkingDays: workingDays,
        totalPresent: presentCount,
        totalAbsent: absentCount,
      );

      await _db.insertPayroll(payroll);
      generated++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated $generated payroll records'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _loadData();
  }

  Future<void> _markAsPaid(PayrollModel payroll) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Mark payroll for period ${payroll.period} as PAID?\n'
          'Amount: \$${payroll.totalSalary.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = PayrollModel(
        id: payroll.id,
        userId: payroll.userId,
        period: payroll.period,
        basicSalary: payroll.basicSalary,
        allowances: payroll.allowances,
        deductions: payroll.deductions,
        totalSalary: payroll.totalSalary,
        paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        status: 'paid',
        totalWorkingDays: payroll.totalWorkingDays,
        totalPresent: payroll.totalPresent,
        totalAbsent: payroll.totalAbsent,
        totalLate: payroll.totalLate,
        totalHalfDays: payroll.totalHalfDays,
        remarks: payroll.remarks,
      );
      await _db.updatePayroll(updated);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payroll marked as paid'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _generatePayroll,
              backgroundColor: const Color(0xFF1565C0),
              icon: const Icon(Icons.calculate, color: Colors.white),
              label: const Text(
                'Generate',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('Period:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      // Month picker (same simplified approach as attendance)
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
                            _selectedPeriod.split('-')[1],
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
                        _selectedPeriod =
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
                            size: 18,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedPeriod,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Payroll list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payrolls.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payments,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No payroll records',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        if (isAdmin)
                          ElevatedButton.icon(
                            onPressed: _generatePayroll,
                            icon: const Icon(Icons.calculate),
                            label: const Text('Generate Payroll'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _payrolls.length,
                      itemBuilder: (context, index) {
                        final payroll = _payrolls[index];
                        final statusColor = payroll.status == 'paid'
                            ? Colors.green
                            : payroll.status == 'cancelled'
                            ? Colors.red
                            : Colors.orange;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Period: ${payroll.period}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        payroll.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Basic Salary: \$${payroll.basicSalary.toStringAsFixed(2)}',
                                ),
                                Text(
                                  'Allowances: \$${payroll.allowances.toStringAsFixed(2)}',
                                ),
                                Text(
                                  'Deductions: \$${payroll.deductions.toStringAsFixed(2)}',
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Net Salary:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '\$${payroll.totalSalary.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                                if (payroll.totalPresent != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Present: ${payroll.totalPresent} / ${payroll.totalWorkingDays ?? 0} days',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (payroll.paymentDate != null)
                                  Text(
                                    'Paid on: ${payroll.paymentDate}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (isAdmin && payroll.status == 'pending') ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _markAsPaid(payroll),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Mark as Paid'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
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

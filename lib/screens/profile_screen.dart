import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService.instance;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _nameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email ?? '');
    _phoneController = TextEditingController(text: user.phone ?? '');
    _salaryController = TextEditingController(
      text: user.salary?.toString() ?? '',
    );
    _departmentController = TextEditingController(text: user.department ?? '');
    _positionController = TextEditingController(text: user.position ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    final updated = UserModel(
      id: user.id,
      username: user.username,
      password: user.password,
      fullName: _nameController.text.trim(),
      role: user.role,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      salary: _salaryController.text.trim().isEmpty
          ? user.salary
          : double.tryParse(_salaryController.text.trim()),
      department: _departmentController.text.trim().isEmpty
          ? user.department
          : _departmentController.text.trim(),
      position: _positionController.text.trim().isEmpty
          ? user.position
          : _positionController.text.trim(),
      joinDate: user.joinDate,
      isActive: user.isActive,
    );

    await _db.updateUser(updated);

    // Update the current user in AuthProvider
    auth.logout(); // Force re-login needed
    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated. Please log in again.'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to login
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

    final totalPayroll = _db.getPayrollByUser(user.id!);
    final totalAttendance = _db.getAttendanceByUser(user.id!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info fields
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoField(
                      'Full Name',
                      Icons.person,
                      _nameController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Username',
                      Icons.account_circle,
                      null,
                      value: user.username,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Email',
                      Icons.email,
                      _emailController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Phone',
                      Icons.phone,
                      _phoneController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Department',
                      Icons.business,
                      _departmentController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Position',
                      Icons.work,
                      _positionController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Salary',
                      Icons.money,
                      _salaryController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoField(
                      'Join Date',
                      Icons.date_range,
                      null,
                      value: user.joinDate ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            FutureBuilder<List>(
              future: Future.wait([totalPayroll, totalAttendance]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final payrolls = snapshot.data![0] as List;
                final attendances = snapshot.data![1] as List;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            _buildStatItem(
                              'Total Attendance',
                              '${attendances.length}',
                              Icons.fingerprint,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              'Payroll Records',
                              '${payrolls.length}',
                              Icons.payments,
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    IconData icon,
    TextEditingController? controller, {
    bool isEditing = false,
    String? value,
  }) {
    if (controller != null && isEditing) {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              controller?.text ?? value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

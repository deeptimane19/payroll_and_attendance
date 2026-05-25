class UserModel {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String role; // 'admin' or 'employee'
  final String? email;
  final String? phone;
  final double? salary;
  final String? department;
  final String? position;
  final String? joinDate;
  final bool isActive;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.salary,
    this.department,
    this.position,
    this.joinDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
      'email': email,
      'phone': phone,
      'salary': salary,
      'department': department,
      'position': position,
      'joinDate': joinDate,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['fullName'] as String,
      role: map['role'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      salary: map['salary'] as double?,
      department: map['department'] as String?,
      position: map['position'] as String?,
      joinDate: map['joinDate'] as String?,
      isActive: (map['isActive'] as int?) == 1,
    );
  }
}

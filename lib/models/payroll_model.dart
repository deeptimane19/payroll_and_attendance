class PayrollModel {
  final int? id;
  final int userId;
  final String period; // e.g. '2026-05'
  final double basicSalary;
  final double allowances;
  final double deductions;
  final double totalSalary;
  final String? paymentDate;
  final String status; // 'pending', 'paid', 'cancelled'
  final int? totalWorkingDays;
  final int? totalPresent;
  final int? totalAbsent;
  final int? totalLate;
  final int? totalHalfDays;
  final String? remarks;

  PayrollModel({
    this.id,
    required this.userId,
    required this.period,
    required this.basicSalary,
    this.allowances = 0,
    this.deductions = 0,
    required this.totalSalary,
    this.paymentDate,
    this.status = 'pending',
    this.totalWorkingDays,
    this.totalPresent,
    this.totalAbsent,
    this.totalLate,
    this.totalHalfDays,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'period': period,
      'basicSalary': basicSalary,
      'allowances': allowances,
      'deductions': deductions,
      'totalSalary': totalSalary,
      'paymentDate': paymentDate,
      'status': status,
      'totalWorkingDays': totalWorkingDays,
      'totalPresent': totalPresent,
      'totalAbsent': totalAbsent,
      'totalLate': totalLate,
      'totalHalfDays': totalHalfDays,
      'remarks': remarks,
    };
  }

  factory PayrollModel.fromMap(Map<String, dynamic> map) {
    return PayrollModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      period: map['period'] as String,
      basicSalary: map['basicSalary'] as double,
      allowances: (map['allowances'] as num?)?.toDouble() ?? 0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0,
      totalSalary: map['totalSalary'] as double,
      paymentDate: map['paymentDate'] as String?,
      status: map['status'] as String? ?? 'pending',
      totalWorkingDays: map['totalWorkingDays'] as int?,
      totalPresent: map['totalPresent'] as int?,
      totalAbsent: map['totalAbsent'] as int?,
      totalLate: map['totalLate'] as int?,
      totalHalfDays: map['totalHalfDays'] as int?,
      remarks: map['remarks'] as String?,
    );
  }
}

class AttendanceModel {
  final int? id;
  final int userId;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? status; // 'present', 'absent', 'late', 'half-day', 'leave'
  final String? remarks;

  AttendanceModel({
    this.id,
    required this.userId,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.status,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'clockIn': clockIn,
      'clockOut': clockOut,
      'status': status,
      'remarks': remarks,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      date: map['date'] as String,
      clockIn: map['clockIn'] as String?,
      clockOut: map['clockOut'] as String?,
      status: map['status'] as String?,
      remarks: map['remarks'] as String?,
    );
  }
}

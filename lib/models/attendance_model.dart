import 'package:qr_attendx_mobile/models/student_model.dart';

class AttendanceModel {
  const AttendanceModel({
    required this.recordId,
    required this.studentId,
    required this.studentName,
    required this.section,
    required this.timeIn,
    this.timeOut,
    required this.status,
  });

  final String recordId;
  final String studentId;
  final String studentName;
  final String section;
  final DateTime timeIn;
  final DateTime? timeOut;
  final String status;

  AttendanceModel copyWith({
    String? recordId,
    String? studentId,
    String? studentName,
    String? section,
    DateTime? timeIn,
    DateTime? timeOut,
    bool clearTimeOut = false,
    String? status,
  }) {
    return AttendanceModel(
      recordId: recordId ?? this.recordId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      section: section ?? this.section,
      timeIn: timeIn ?? this.timeIn,
      timeOut: clearTimeOut ? null : (timeOut ?? this.timeOut),
      status: status ?? this.status,
    );
  }

  factory AttendanceModel.newScan(StudentModel student) {
    final now = DateTime.now();
    return AttendanceModel(
      recordId: '${student.id}_${now.millisecondsSinceEpoch}',
      studentId: student.id,
      studentName: student.fullName,
      section: student.section,
      timeIn: now,
      timeOut: null,
      status: 'Present',
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      recordId: json['recordId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      section: json['section'] as String,
      timeIn: DateTime.parse(json['timeIn'] as String),
      timeOut: json['timeOut'] == null
          ? null
          : DateTime.parse(json['timeOut'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordId': recordId,
      'studentId': studentId,
      'studentName': studentName,
      'section': section,
      'timeIn': timeIn.toIso8601String(),
      'timeOut': timeOut?.toIso8601String(),
      'status': status,
    };
  }
}

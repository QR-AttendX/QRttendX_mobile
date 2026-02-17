import 'package:flutter/material.dart';
import 'package:qr_attendx_mobile/models/attendance_model.dart';
import 'package:qr_attendx_mobile/models/student_model.dart';
import 'package:qr_attendx_mobile/shared/widgets/duplicate_panel.dart';

Future<DuplicateChoice> handleDuplicateDetection({
  required BuildContext context,
  required StudentModel candidateData,
  required AttendanceModel existingMatchData,
}) {
  return showDuplicatePanel(
    context: context,
    candidateData: candidateData,
    existingMatchData: existingMatchData,
  );
}

AttendanceModel? findDuplicateAttendanceRecord({
  required List<AttendanceModel> records,
  required AttendanceModel candidateRecord,
}) {
  for (final record in records.reversed) {
    final isSameStudent = record.studentId == candidateRecord.studentId;
    final isSameDay = _isSameDate(record.timeIn, candidateRecord.timeIn);
    if (isSameStudent && isSameDay) {
      return record;
    }
  }
  return null;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

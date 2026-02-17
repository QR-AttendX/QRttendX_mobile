import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:qr_attendx_mobile/core/utils/duplicate_utils.dart';
import 'package:qr_attendx_mobile/features/attendance/attendance_controller.dart';
import 'package:qr_attendx_mobile/models/attendance_model.dart';
import 'package:qr_attendx_mobile/models/student_model.dart';
import 'package:qr_attendx_mobile/shared/widgets/duplicate_panel.dart';

class QrController extends ChangeNotifier {
  bool _isProcessing = false;
  String _statusMessage = 'Point camera at a student QR code.';
  StudentModel? _lastStudent;

  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  StudentModel? get lastStudent => _lastStudent;

  Future<void> processScan({
    required String rawValue,
    required AttendanceController attendanceController,
    required Future<DuplicateChoice> Function(
      StudentModel candidateData,
      AttendanceModel existingMatchData,
    )
    resolveDuplicate,
  }) async {
    if (_isProcessing || rawValue.trim().isEmpty) {
      return;
    }
    _setProcessing(true);

    try {
      final student = await _fetchStudentData(rawValue.trim());
      if (student == null) {
        _statusMessage = 'No student found for scanned QR.';
        return;
      }
      if (student.role.toLowerCase() != 'student') {
        _statusMessage = 'Scanned QR is not a student account.';
        return;
      }

      final candidateRecord = AttendanceModel.newScan(student);
      final duplicateMatch = findDuplicateAttendanceRecord(
        records: attendanceController.records,
        candidateRecord: candidateRecord,
      );

      if (duplicateMatch != null) {
        final duplicateChoice = await resolveDuplicate(
          student,
          duplicateMatch,
        );

        if (duplicateChoice == DuplicateChoice.cancel) {
          _statusMessage = 'Duplicate scan cancelled.';
          return;
        }

        if (duplicateChoice == DuplicateChoice.useOriginal) {
          _statusMessage = 'Original record kept for ${student.fullName}.';
          return;
        }
      }

      attendanceController.addRecord(candidateRecord);
      _lastStudent = student;
      _statusMessage = 'Attendance saved for ${student.fullName}.';
    } finally {
      _setProcessing(false);
    }
  }

  void clearLogs() {
    _lastStudent = null;
    _statusMessage = 'Logs cleared.';
    notifyListeners();
  }

  Future<StudentModel?> _fetchStudentData(String qrValue) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final parsedStudent = _parseStudentFromJson(qrValue);
    if (parsedStudent != null) {
      return parsedStudent;
    }
    return _mockStudentSource[qrValue];
  }

  StudentModel? _parseStudentFromJson(String rawValue) {
    final decodedMap = _decodeMap(rawValue);
    if (decodedMap != null) {
      return _studentFromMap(decodedMap, rawValue);
    }

    final uri = Uri.tryParse(rawValue);
    if (uri == null) {
      return null;
    }

    final profilePayload = _extractProfilePayloadFromUri(uri);
    if (profilePayload == null || profilePayload.isEmpty) {
      return null;
    }

    final payloadMap = _decodeMap(profilePayload);
    if (payloadMap == null) {
      return null;
    }
    return _studentFromMap(payloadMap, rawValue);
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}

Map<String, dynamic>? _decodeMap(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  } catch (_) {
    return null;
  }
}

String? _extractProfilePayloadFromUri(Uri uri) {
  final queryPayload = uri.queryParameters['profile'];
  if (queryPayload != null && queryPayload.isNotEmpty) {
    return queryPayload;
  }

  final fragment = uri.fragment;
  if (fragment.startsWith('profile=')) {
    return Uri.decodeComponent(fragment.substring('profile='.length));
  }
  return null;
}

StudentModel? _studentFromMap(Map<String, dynamic> decoded, String rawValue) {
  final fullName = _pickString(decoded, const ['fullname', 'fullName']);
  if (fullName == null || fullName.isEmpty) {
    return null;
  }

  final username = _pickString(decoded, const ['username']);
  final section = _pickString(decoded, const ['section']) ?? 'Unknown Section';
  final role = _pickString(decoded, const ['role']) ?? 'student';
  final idFromPayload = _pickString(decoded, const ['id', 'studentId']);
  final idSource = idFromPayload ?? username ?? '$fullName|$section';

  return StudentModel(
    id: _normalizeId(idSource),
    fullName: fullName,
    username: username,
    role: role,
    section: section,
    qrValue: rawValue,
  );
}

String? _pickString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String _normalizeId(String value) {
  final normalized = value.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '_',
      );
  return normalized
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

const Map<String, StudentModel> _mockStudentSource = <String, StudentModel>{
  'STUDENT-1001': StudentModel(
    id: 'S1001',
    fullName: 'Adrian Bautista',
    username: 'adrian_b',
    role: 'student',
    section: '12 - Berners Lee',
    qrValue: 'STUDENT-1001',
  ),
  'STUDENT-1002': StudentModel(
    id: 'S1002',
    fullName: 'Jake Lorenz Ergina',
    username: 'jake_e',
    role: 'student',
    section: '12 - Berners Lee',
    qrValue: 'STUDENT-1002',
  ),
  'STUDENT-1003': StudentModel(
    id: 'S1003',
    fullName: 'Mark Laren Boholano',
    username: 'mark_b',
    role: 'student',
    section: '12 - Berners Lee',
    qrValue: 'STUDENT-1003',
  ),
};

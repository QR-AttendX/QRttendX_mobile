import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qr_attendx_mobile/models/attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _downloadsChannel = MethodChannel(
  'qr_attendx_mobile/downloads',
);

class AttendanceImportResult {
  const AttendanceImportResult({
    required this.importedCount,
    required this.skippedCount,
  });

  final int importedCount;
  final int skippedCount;
}

class AttendanceExportResult {
  const AttendanceExportResult({
    required this.exportedCount,
    required this.filePath,
  });

  final int exportedCount;
  final String filePath;
}

class AttendanceController extends ChangeNotifier {
  AttendanceController() {
    unawaited(_restoreRecords());
  }

  static const String _storageKey = 'attendance_records_v1';
  final List<AttendanceModel> _records = <AttendanceModel>[];
  bool _isLoaded = false;

  UnmodifiableListView<AttendanceModel> get records =>
      UnmodifiableListView<AttendanceModel>(_records);
  bool get isLoaded => _isLoaded;

  void addRecord(AttendanceModel record) {
    _records.add(record);
    notifyListeners();
    unawaited(_persistRecords());
  }

  void addManualStudentAttendance({
    required String fullName,
    required String username,
    required String section,
  }) {
    final trimmedName = fullName.trim();
    final trimmedUsername = username.trim();
    final trimmedSection = section.trim();
    if (trimmedName.isEmpty ||
        trimmedUsername.isEmpty ||
        trimmedSection.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final studentId = _normalizeId(trimmedUsername);
    final record = AttendanceModel(
      recordId: '${studentId}_${now.millisecondsSinceEpoch}',
      studentId: studentId,
      studentName: trimmedName,
      section: trimmedSection,
      timeIn: now,
      timeOut: null,
      status: 'Present',
    );
    addRecord(record);
  }

  void clearRecords() {
    _records.clear();
    notifyListeners();
    unawaited(_persistRecords());
  }

  int deleteRecordsByIds(Set<String> recordIds) {
    if (recordIds.isEmpty) {
      return 0;
    }
    final before = _records.length;
    _records.removeWhere((record) => recordIds.contains(record.recordId));
    final deleted = before - _records.length;
    if (deleted > 0) {
      notifyListeners();
      unawaited(_persistRecords());
    }
    return deleted;
  }

  int setTimeOutForRecordIds({
    required Set<String> recordIds,
    required int hour,
    required int minute,
  }) {
    if (recordIds.isEmpty) {
      return 0;
    }

    var updated = 0;
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      if (!recordIds.contains(record.recordId)) {
        continue;
      }

      final timeout = DateTime(
        record.timeIn.year,
        record.timeIn.month,
        record.timeIn.day,
        hour,
        minute,
      );
      _records[i] = record.copyWith(timeOut: timeout, status: 'Timed Out');
      updated++;
    }

    if (updated > 0) {
      notifyListeners();
      unawaited(_persistRecords());
    }
    return updated;
  }

  Future<AttendanceImportResult> importFromExcelBytes(Uint8List bytes) async {
    final workbook = Excel.decodeBytes(bytes);
    final imported = <AttendanceModel>[];
    var skipped = 0;

    for (final sheetName in workbook.tables.keys) {
      final sheet = workbook.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        continue;
      }

      final headerRow = sheet.rows.first;
      final headers = headerRow
          .map((cell) => _stringValue(_cellValue(cell)).toLowerCase())
          .toList(growable: false);

      final studentIndex = _findIndex(headers, const [
        'student',
        'fullname',
        'full name',
        'name',
      ]);
      if (studentIndex < 0) {
        continue;
      }

      final sectionIndex = _findIndex(headers, const ['section', 'class']);
      final statusIndex = _findIndex(headers, const ['status']);
      final timeInIndex = _findIndex(headers, const [
        'time in',
        'timein',
        'date',
        'datetime',
        'timestamp',
      ]);
      final studentIdIndex = _findIndex(headers, const [
        'student id',
        'studentid',
        'id',
        'username',
      ]);

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final studentName = _cellStringAt(row, studentIndex);
        if (studentName.isEmpty) {
          skipped++;
          continue;
        }

        final section = sectionIndex >= 0
            ? _cellStringAt(row, sectionIndex)
            : 'Unknown Section';
        final status = statusIndex >= 0 ? _cellStringAt(row, statusIndex) : '';
        final rawId = studentIdIndex >= 0
            ? _cellStringAt(row, studentIdIndex)
            : '';
        final rawTime = timeInIndex >= 0
            ? _cellValueAt(row, timeInIndex)
            : null;
        final timeIn = _parseTime(rawTime) ?? DateTime.now();

        final studentId = rawId.isEmpty
            ? _normalizeId('$studentName|$section')
            : _normalizeId(rawId);
        final normalizedSection = section.isEmpty ? 'Unknown Section' : section;

        imported.add(
          AttendanceModel(
            recordId:
                '${studentId}_${timeIn.millisecondsSinceEpoch}_${imported.length}',
            studentId: studentId,
            studentName: studentName,
            section: normalizedSection,
            timeIn: timeIn,
            timeOut: null,
            status: status.isEmpty ? 'Present' : _formatStatus(status),
          ),
        );
      }
    }

    if (imported.isEmpty) {
      return AttendanceImportResult(importedCount: 0, skippedCount: skipped);
    }

    _records.addAll(imported);
    notifyListeners();
    unawaited(_persistRecords());
    return AttendanceImportResult(
      importedCount: imported.length,
      skippedCount: skipped,
    );
  }

  Future<AttendanceExportResult> exportTodayAttendanceExcel({
    String? section,
  }) async {
    final now = DateTime.now();
    final normalizedSection = section?.trim();
    final todayRecords =
        _records
            .where((record) {
              final isToday =
                  record.timeIn.year == now.year &&
                  record.timeIn.month == now.month &&
                  record.timeIn.day == now.day;
              if (!isToday) {
                return false;
              }

              if (normalizedSection == null || normalizedSection.isEmpty) {
                return true;
              }
              return record.section.trim() == normalizedSection;
            })
            .toList(growable: false)
          ..sort((a, b) => a.timeIn.compareTo(b.timeIn));

    final workbook = Excel.createExcel();
    final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
    final sheet = workbook[sheetName];

    sheet.appendRow([
      'Record ID',
      'Student ID',
      'Fullname',
      'Section',
      'Time In',
      'Time Out',
      'Status',
    ]);

    for (final record in todayRecords) {
      sheet.appendRow([
        record.recordId,
        record.studentId,
        record.studentName,
        record.section,
        _formatDateTimeForExcel(record.timeIn),
        record.timeOut == null ? '' : _formatDateTimeForExcel(record.timeOut!),
        record.status,
      ]);
    }

    final encodedBytes = workbook.encode();
    if (encodedBytes == null || encodedBytes.isEmpty) {
      throw StateError('Failed to encode attendance workbook.');
    }
    final bytes = Uint8List.fromList(encodedBytes);

    final fileName =
        'attendance_${_dateForFileName(now)}_${_timeForFileName(now)}.xlsx';
    if (Platform.isAndroid) {
      final savedPath = await _saveToAndroidDownloads(
        fileName: fileName,
        bytes: bytes,
      );
      return AttendanceExportResult(
        exportedCount: todayRecords.length,
        filePath: savedPath,
      );
    }

    final exportDirectory = await _resolveExportDirectory();
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final filePath =
        '${exportDirectory.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return AttendanceExportResult(
      exportedCount: todayRecords.length,
      filePath: file.path,
    );
  }

  Future<Directory> _resolveExportDirectory() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        return Directory('$userProfile\\Downloads\\QR AttendX');
      }
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home/Downloads/QR AttendX');
    }

    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}AttendX',
    );
  }

  Future<String> _saveToAndroidDownloads({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final savedPath = await _downloadsChannel.invokeMethod<String>(
      'saveBytesToDownloads',
      <String, Object>{
        'fileName': fileName,
        'mimeType':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'relativePath': 'Download/QR AttendX',
        'bytes': bytes,
      },
    );
    if (savedPath == null || savedPath.isEmpty) {
      throw StateError('Failed to save attendance export.');
    }
    return savedPath;
  }

  Future<void> _restoreRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _isLoaded = true;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _isLoaded = true;
        notifyListeners();
        return;
      }

      _records
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(
            AttendanceModel.fromJson,
          ),
        );
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _records.map((record) => record.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey, payload);
  }
}

int _findIndex(List<String> headers, List<String> candidates) {
  for (var i = 0; i < headers.length; i++) {
    final current = headers[i].trim();
    for (final candidate in candidates) {
      if (current == candidate) {
        return i;
      }
    }
  }
  return -1;
}

Object? _cellValueAt(List<dynamic> row, int index) {
  if (index < 0 || index >= row.length) {
    return null;
  }
  return _cellValue(row[index]);
}

String _cellStringAt(List<dynamic> row, int index) {
  return _stringValue(_cellValueAt(row, index));
}

Object? _cellValue(dynamic cell) {
  if (cell == null) {
    return null;
  }
  try {
    return cell.value;
  } catch (_) {
    return cell;
  }
}

String _stringValue(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

DateTime? _parseTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return _fromExcelSerial(value.toDouble());
  }
  if (value is double) {
    return _fromExcelSerial(value);
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

DateTime _fromExcelSerial(double serial) {
  final millis = (serial * 86400000).round();
  final epoch = DateTime.utc(1899, 12, 30);
  return epoch.add(Duration(milliseconds: millis)).toLocal();
}

String _normalizeId(String input) {
  final normalized = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return normalized
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _formatStatus(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.isEmpty) {
    return 'Present';
  }
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

String _formatDateTimeForExcel(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute:$second';
}

String _dateForFileName(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}$month$day';
}

String _timeForFileName(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$hour$minute$second';
}

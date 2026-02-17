class StudentModel {
  const StudentModel({
    required this.id,
    required this.fullName,
    this.username,
    required this.role,
    required this.section,
    required this.qrValue,
  });

  final String id;
  final String fullName;
  final String? username;
  final String role;
  final String section;
  final String qrValue;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'studentId', 'username']);
    final fullName = _readString(json, const ['fullName', 'fullname', 'name']);
    final section = _readString(json, const ['section']);
    return StudentModel(
      id: id ?? '',
      fullName: fullName ?? '',
      username: _readString(json, const ['username']),
      role: _readString(json, const ['role']) ?? 'student',
      section: section ?? '',
      qrValue: _readString(json, const ['qrValue']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'username': username,
      'role': role,
      'section': section,
      'qrValue': qrValue,
    };
  }
}

String? _readString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

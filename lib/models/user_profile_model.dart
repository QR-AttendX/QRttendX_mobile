class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    this.teacherType,
  });

  final String id;
  final String fullName;
  final String username;
  final String role;
  final String? teacherType;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final username = (json['username'] as String? ?? '').trim();
    final storedId = (json['id'] as String? ?? '').trim();
    return UserProfileModel(
      id: storedId.isEmpty ? normalizeId(username) : storedId,
      fullName: (json['fullName'] as String? ?? '').trim(),
      username: username,
      role: (json['role'] as String? ?? '').trim(),
      teacherType: (json['teacherType'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'username': username,
      'role': role,
      'teacherType': teacherType,
    };
  }

  static String normalizeId(String value) {
    final normalized = value.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
    return normalized
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

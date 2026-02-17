import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:qr_attendx_mobile/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController._(this._prefs) {
    _profile = _readProfile();
  }

  static const String _profileStorageKey = 'user_profile_v1';

  final SharedPreferences _prefs;
  UserProfileModel? _profile;

  UserProfileModel? get profile => _profile;
  bool get isCompleted => _profile != null;

  static Future<OnboardingController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingController._(prefs);
  }

  Future<void> completeProfile(UserProfileModel profile) async {
    _profile = profile;
    await _prefs.setString(_profileStorageKey, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> clearProfile() async {
    _profile = null;
    await _prefs.remove(_profileStorageKey);
    notifyListeners();
  }

  UserProfileModel? _readProfile() {
    final raw = _prefs.getString(_profileStorageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final profile = UserProfileModel.fromJson(decoded);
      if (profile.fullName.isEmpty ||
          profile.username.isEmpty ||
          profile.role.isEmpty) {
        return null;
      }
      return profile;
    } catch (_) {
      return null;
    }
  }
}

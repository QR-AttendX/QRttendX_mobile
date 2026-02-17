import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_utils.dart';
import 'package:qr_attendx_mobile/features/onboarding/onboarding_controller.dart';
import 'package:qr_attendx_mobile/models/user_profile_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _studentRole = 'student';
  static const String _teacherRole = 'teacher';

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();

  String _selectedRole = _studentRole;
  String? _selectedTeacherType;
  bool _isSubmitting = false;

  static const List<DropdownMenuItem<String>> _roleItems = [
    DropdownMenuItem(value: _studentRole, child: Text('Student')),
    DropdownMenuItem(value: _teacherRole, child: Text('Teacher')),
  ];

  static const List<DropdownMenuItem<String>> _teacherTypeItems = [
    DropdownMenuItem(
      value: 'subject_teacher',
      child: Text('Subject Teacher'),
    ),
    DropdownMenuItem(
      value: 'adviser_teacher',
      child: Text('Adviser Teacher'),
    ),
    DropdownMenuItem(
      value: 'subject_and_adviser_teacher',
      child: Text('Both Subject and Adviser Teacher'),
    ),
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Started',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile to continue.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: _roleItems,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedRole = value;
                              if (_selectedRole != _teacherRole) {
                                _selectedTeacherType = null;
                              }
                            });
                          },
                        ),
                        if (_selectedRole == _teacherRole) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTeacherType,
                            decoration: const InputDecoration(
                              labelText: 'Teacher Type',
                              border: OutlineInputBorder(),
                            ),
                            items: _teacherTypeItems,
                            onChanged: (value) {
                              setState(() {
                                _selectedTeacherType = value;
                              });
                            },
                            validator: (value) {
                              if (_selectedRole == _teacherRole &&
                                  (value == null || value.isEmpty)) {
                                return 'Teacher type is required.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final onboardingController = context.read<OnboardingController>();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final profile = UserProfileModel(
        id: UserProfileModel.normalizeId(_usernameController.text.trim()),
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        role: _selectedRole,
        teacherType:
            _selectedRole == _teacherRole ? _selectedTeacherType : null,
      );
      await onboardingController.completeProfile(profile);
      if (!mounted) {
        return;
      }
      context.go(AppNavigationUtils.dashboardPath);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

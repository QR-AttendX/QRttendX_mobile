import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendx_mobile/features/attendance/attendance_controller.dart';
import 'package:qr_attendx_mobile/models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const String _allSections = 'All Sections';
  static const String _newSectionOption = _AddStudentSheetState.newSectionValue;

  String _selectedSection = _allSections;
  bool _isImporting = false;
  bool _isEditMode = false;
  final Set<String> _selectedRecordIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final attendanceController = context.watch<AttendanceController>();
    if (!attendanceController.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayRecords = attendanceController.records
        .where(_isToday)
        .toList(growable: false);
    final sections = _todaySections(todayRecords);
    if (!sections.contains(_selectedSection)) {
      _selectedSection = _allSections;
    }

    final filteredRecords = _selectedSection == _allSections
        ? todayRecords
        : todayRecords
            .where((record) => record.section == _selectedSection)
            .toList(growable: false);
    final selectedVisibleCount = filteredRecords
        .where((record) => _selectedRecordIds.contains(record.recordId))
        .length;
    final allVisibleSelected =
        filteredRecords.isNotEmpty && selectedVisibleCount == filteredRecords.length;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _isEditMode ? 220 : 110),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _FilterRow(
                      sections: sections,
                      selectedSection: _selectedSection,
                      isImporting: _isImporting,
                      onSectionChanged: _onSectionChanged,
                      onImportExportPressed: _openImportExportSheet,
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: allVisibleSelected,
                            onChanged: filteredRecords.isEmpty
                                ? null
                                : (value) {
                                    _selectAllVisibleRows(
                                      filteredRecords,
                                      value ?? false,
                                    );
                                  },
                          ),
                          Text(
                            'Select all rows',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (filteredRecords.isEmpty)
                      _buildEmptyState(context)
                    else
                      _AttendanceTable(
                        records: filteredRecords,
                        isEditMode: _isEditMode,
                        selectedRecordIds: _selectedRecordIds,
                        onToggleRecordSelection: _toggleRecordSelection,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: _buildFabColumn(selectedCount: selectedVisibleCount),
          ),
        ),
      ],
    );
  }

  Widget _buildFabColumn({required int selectedCount}) {
    if (_isEditMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'attendance_done_edit_fab',
            mini: true,
            onPressed: _toggleEditMode,
            child: const Icon(Icons.done),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'attendance_delete_fab',
            mini: true,
            onPressed: selectedCount == 0 ? null : _deleteSelectedRows,
            child: const Icon(Icons.delete_outline),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'attendance_timeout_fab',
            onPressed: selectedCount == 0 ? null : _setTimeOutForSelectedRows,
            icon: const Icon(Icons.access_time),
            label: const Text('Set Time Out'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'attendance_edit_mode_fab',
          mini: true,
          onPressed: _toggleEditMode,
          child: const Icon(Icons.edit_outlined),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'attendance_add_student_fab',
          onPressed: _openAddStudentSheet,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Student'),
        ),
      ],
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedRecordIds.clear();
      }
    });
  }

  void _onSectionChanged(String value) {
    setState(() {
      _selectedSection = value;
      _selectedRecordIds.clear();
    });
  }

  void _selectAllVisibleRows(List<AttendanceModel> records, bool shouldSelect) {
    setState(() {
      if (shouldSelect) {
        _selectedRecordIds.addAll(records.map((record) => record.recordId));
      } else {
        _selectedRecordIds.removeAll(records.map((record) => record.recordId));
      }
    });
  }

  void _toggleRecordSelection(String recordId, bool selected) {
    setState(() {
      if (selected) {
        _selectedRecordIds.add(recordId);
      } else {
        _selectedRecordIds.remove(recordId);
      }
    });
  }

  Future<void> _deleteSelectedRows() async {
    final deletedCount = context
        .read<AttendanceController>()
        .deleteRecordsByIds(_selectedRecordIds);
    setState(() {
      _selectedRecordIds.clear();
    });
    _showMessage('Deleted $deletedCount row(s).');
  }

  Future<void> _setTimeOutForSelectedRows() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    final updatedCount = context.read<AttendanceController>().setTimeOutForRecordIds(
          recordIds: _selectedRecordIds,
          hour: selectedTime.hour,
          minute: selectedTime.minute,
        );
    setState(() {
      _selectedRecordIds.clear();
    });
    _showMessage('Time out set for $updatedCount row(s).');
  }

  bool _isToday(AttendanceModel record) {
    final now = DateTime.now();
    return record.timeIn.year == now.year &&
        record.timeIn.month == now.month &&
        record.timeIn.day == now.day;
  }

  List<String> _todaySections(List<AttendanceModel> todayRecords) {
    final unique = <String>{};
    for (final record in todayRecords) {
      if (record.section.trim().isNotEmpty) {
        unique.add(record.section.trim());
      }
    }
    final sorted = unique.toList(growable: false)..sort();
    return <String>[_allSections, ...sorted];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No attendance records yet. Scan a student QR code first.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Future<void> _openImportExportSheet() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Import Attendance Excel'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _importExcel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Attendance Excel'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export is not implemented yet.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importExcel() async {
    final attendanceController = context.read<AttendanceController>();
    setState(() {
      _isImporting = true;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        return;
      }

      final bytes = picked.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Unable to read selected file.');
        return;
      }

      final result = await attendanceController.importFromExcelBytes(
        Uint8List.fromList(bytes),
      );

      if (result.importedCount == 0) {
        _showMessage('No valid attendance rows found in the Excel file.');
        return;
      }

      _showMessage(
        'Imported ${result.importedCount} record(s)'
        '${result.skippedCount > 0 ? ', skipped ${result.skippedCount}' : ''}.',
      );
    } catch (_) {
      _showMessage('Failed to import attendance Excel file.');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _openAddStudentSheet() async {
    final allSections = _allRecordedSections(
      context.read<AttendanceController>().records,
    );
    final result = await showModalBottomSheet<_NewStudentInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _AddStudentSheet(
        sectionOptions: allSections,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    context.read<AttendanceController>().addManualStudentAttendance(
          fullName: result.fullName,
          username: result.username,
          section: result.section,
        );
    _showMessage('Student added to today\'s attendance.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> _allRecordedSections(List<AttendanceModel> records) {
    final unique = <String>{};
    for (final record in records) {
      final section = record.section.trim();
      if (section.isNotEmpty) {
        unique.add(section);
      }
    }
    final sorted = unique.toList(growable: false)..sort();
    return <String>[_newSectionOption, ...sorted];
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.sections,
    required this.selectedSection,
    required this.isImporting,
    required this.onSectionChanged,
    required this.onImportExportPressed,
  });

  final List<String> sections;
  final String selectedSection;
  final bool isImporting;
  final ValueChanged<String> onSectionChanged;
  final VoidCallback onImportExportPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            key: ValueKey(selectedSection),
            initialValue: selectedSection,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
            ),
            items: sections
                .map(
                  (section) => DropdownMenuItem<String>(
                    value: section,
                    child: Text(
                      section,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onSectionChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 44,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onPressed: isImporting ? null : onImportExportPressed,
              icon: isImporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.import_export, size: 18),
              label: const Text(
                'Import/Export',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({
    required this.records,
    required this.isEditMode,
    required this.selectedRecordIds,
    required this.onToggleRecordSelection,
  });

  final List<AttendanceModel> records;
  final bool isEditMode;
  final Set<String> selectedRecordIds;
  final void Function(String recordId, bool selected) onToggleRecordSelection;

  @override
  Widget build(BuildContext context) {
    final visibleRows = records.length > _maxVisibleRows
        ? _maxVisibleRows
        : records.length;
    final height = visibleRows * _rowHeight + (visibleRows - 1);
    final isScrollable = records.length > _maxVisibleRows;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (isEditMode) const SizedBox(width: 34),
              const Expanded(
                flex: 4,
                child: Text(
                  'Student',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Time In',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Status',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: height,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: isScrollable
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final record = records[index];
                final isSelected = selectedRecordIds.contains(record.recordId);
                return InkWell(
                  onTap: !isEditMode
                      ? null
                      : () {
                          onToggleRecordSelection(
                            record.recordId,
                            !isSelected,
                          );
                        },
                  child: SizedBox(
                    height: _rowHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          if (isEditMode)
                            SizedBox(
                              width: 34,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  onToggleRecordSelection(
                                    record.recordId,
                                    value ?? false,
                                  );
                                },
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              record.studentName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatTime(record.timeIn),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              record.status,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AddStudentSheet extends StatefulWidget {
  const _AddStudentSheet({
    required this.sectionOptions,
  });

  final List<String> sectionOptions;

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  static const String newSectionValue = '__new_section__';
  static const String _newSectionLabel = 'New section';

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _sectionController = TextEditingController();
  late String _selectedSectionOption;

  @override
  void initState() {
    super.initState();
    _selectedSectionOption = newSectionValue;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Student',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Fullname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Fullname is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedSectionOption,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
                items: widget.sectionOptions
                    .map(
                      (section) => DropdownMenuItem<String>(
                        value: section,
                        child: Text(
                          section == newSectionValue
                              ? _newSectionLabel
                              : section,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedSectionOption = value;
                  });
                },
              ),
              if (_selectedSectionOption == newSectionValue) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _sectionController,
                  decoration: const InputDecoration(
                    labelText: 'New Section',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedSectionOption == newSectionValue &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Section is required.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Save Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _NewStudentInput(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        section: _selectedSectionOption == newSectionValue
            ? _sectionController.text.trim()
            : _selectedSectionOption,
      ),
    );
  }
}

class _NewStudentInput {
  const _NewStudentInput({
    required this.fullName,
    required this.username,
    required this.section,
  });

  final String fullName;
  final String username;
  final String section;
}

const int _maxVisibleRows = 7;
const double _rowHeight = 48;

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

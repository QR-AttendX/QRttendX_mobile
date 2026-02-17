import 'package:flutter/material.dart';
import 'package:qr_attendx_mobile/models/attendance_model.dart';
import 'package:qr_attendx_mobile/models/student_model.dart';

enum DuplicateChoice {
  cancel,
  useOriginal,
  useDuplicate,
}

class DuplicatePanel extends StatelessWidget {
  const DuplicatePanel({
    required this.candidateData,
    required this.existingMatchData,
    super.key,
  });

  final StudentModel candidateData;
  final AttendanceModel existingMatchData;

  @override
  Widget build(BuildContext context) {
    final timeIn = TimeOfDay.fromDateTime(existingMatchData.timeIn).format(
      context,
    );

    return AlertDialog(
      title: const Text('Potential Duplicate Detected'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Candidate: ${candidateData.fullName}'),
          Text('Section: ${candidateData.section}'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Existing Record',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(existingMatchData.studentName),
          Text('Section: ${existingMatchData.section}'),
          Text('Time In: $timeIn'),
          Text('Status: ${existingMatchData.status}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(DuplicateChoice.cancel);
          },
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).pop(DuplicateChoice.useOriginal);
          },
          child: const Text('Use Original'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(DuplicateChoice.useDuplicate);
          },
          child: const Text('Use Duplicate'),
        ),
      ],
    );
  }
}

Future<DuplicateChoice> showDuplicatePanel({
  required BuildContext context,
  required StudentModel candidateData,
  required AttendanceModel existingMatchData,
}) async {
  final result = await showDialog<DuplicateChoice>(
    context: context,
    builder: (context) {
      return DuplicatePanel(
        candidateData: candidateData,
        existingMatchData: existingMatchData,
      );
    },
  );
  return result ?? DuplicateChoice.cancel;
}

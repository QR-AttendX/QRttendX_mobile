import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendx_mobile/features/attendance/attendance_controller.dart';
import 'package:qr_attendx_mobile/models/attendance_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = context.watch<AttendanceController>();
    if (!attendanceController.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final records = attendanceController.records.toList(growable: false);
    final recentTodayLogs = _todayLogs(records);
    final leaderboardEntries = _buildLeaderboard(records);

    final totalStudents = records.map((record) => record.studentId).toSet().length;
    final presentToday = recentTodayLogs
        .where((record) => record.status.toLowerCase() == 'present')
        .map((record) => record.studentId)
        .toSet()
        .length;
    final absentToday = recentTodayLogs
        .where((record) => record.status.toLowerCase() == 'absent')
        .map((record) => record.studentId)
        .toSet()
        .length;
    final lateToday = recentTodayLogs
        .where((record) => record.status.toLowerCase() == 'late')
        .map((record) => record.studentId)
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCardRow(
          totalStudents: totalStudents,
          presentToday: presentToday,
          absentToday: absentToday,
          lateToday: lateToday,
        ),
        const SizedBox(height: 16),
        _RecentStudentsCard(records: recentTodayLogs),
        const SizedBox(height: 16),
        _LeaderboardCard(entries: leaderboardEntries),
      ],
    );
  }
}

class _SummaryCardRow extends StatelessWidget {
  const _SummaryCardRow({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.lateToday,
  });

  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int lateToday;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _SummaryRow(
              left: _MetricTile(
                icon: Icons.group_outlined,
                value: '$totalStudents',
                label: 'Total Students',
              ),
              right: _MetricTile(
                icon: Icons.check_circle_outline,
                value: '$presentToday',
                label: 'Present Today',
              ),
            ),
            const Divider(height: 20),
            _SummaryRow(
              left: _MetricTile(
                icon: Icons.cancel_outlined,
                value: '$absentToday',
                label: 'Absent Today',
              ),
              right: _MetricTile(
                icon: Icons.watch_later_outlined,
                value: '$lateToday',
                label: 'Late Today',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: left),
          const VerticalDivider(width: 20),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentStudentsCard extends StatelessWidget {
  const _RecentStudentsCard({required this.records});

  final List<AttendanceModel> records;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Students',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _HeaderRow(columns: const ['Fullname', 'Time In', 'Section']),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const _EmptyState(
                height: 140,
                text: 'No recent student logs yet',
              )
            else
              _RecentStudentRows(records: records),
          ],
        ),
      ),
    );
  }
}

class _RecentStudentRows extends StatelessWidget {
  const _RecentStudentRows({required this.records});

  final List<AttendanceModel> records;

  @override
  Widget build(BuildContext context) {
    final visibleHeight = _tableBodyHeight(records.length);
    final isScrollable = records.length > _maxVisibleRows;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SizedBox(
        height: visibleHeight,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          physics: isScrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (context, index) {
            return Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            );
          },
          itemBuilder: (context, index) {
            final record = records[index];
            return SizedBox(
              height: _tableRowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.studentName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(_formatTime(record.timeIn)),
                    ),
                    Expanded(
                      child: Text(
                        record.section,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries});

  final List<_LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Student's Leaderboard",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Attendance counted every month',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _HeaderRow(columns: const ['Fullname', 'Days Present']),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const _EmptyState(height: 140, text: 'No leaderboard data yet')
            else
              _LeaderboardRows(entries: entries),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRows extends StatelessWidget {
  const _LeaderboardRows({required this.entries});

  final List<_LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final visibleHeight = _tableBodyHeight(entries.length);
    final isScrollable = entries.length > _maxVisibleRows;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SizedBox(
        height: visibleHeight,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          physics: isScrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (context, index) {
            return Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            );
          },
          itemBuilder: (context, index) {
            final entry = entries[index];
            return SizedBox(
              height: _tableRowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text('${entry.daysPresent}'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: columns
            .map(
              (column) => Expanded(
                child: Text(
                  column,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.height,
    required this.text,
  });

  final double height;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

const int _maxVisibleRows = 5;
const double _tableRowHeight = 52;

double _tableBodyHeight(int rowCount) {
  final visibleRows = rowCount < _maxVisibleRows ? rowCount : _maxVisibleRows;
  if (visibleRows <= 0) {
    return 0;
  }
  return visibleRows * _tableRowHeight + (visibleRows - 1);
}

List<AttendanceModel> _todayLogs(List<AttendanceModel> records) {
  final now = DateTime.now();
  final filtered = records.where((record) {
    final time = record.timeIn;
    return time.year == now.year && time.month == now.month && time.day == now.day;
  }).toList(growable: false);

  filtered.sort((a, b) => b.timeIn.compareTo(a.timeIn));
  return filtered;
}

List<_LeaderboardEntry> _buildLeaderboard(List<AttendanceModel> records) {
  final byStudent = <String, _LeaderboardAccumulator>{};
  for (final record in records) {
    final key = record.studentId;
    final accumulator = byStudent.putIfAbsent(
      key,
      () => _LeaderboardAccumulator(fullName: record.studentName),
    );
    accumulator.fullName = record.studentName;
    accumulator.presentDays.add(_dateKey(record.timeIn));
  }

  final entries = byStudent.values
      .map(
        (acc) => _LeaderboardEntry(
          fullName: acc.fullName,
          daysPresent: acc.presentDays.length,
        ),
      )
      .toList(growable: false);

  entries.sort((a, b) {
    final byDays = b.daysPresent.compareTo(a.daysPresent);
    if (byDays != 0) {
      return byDays;
    }
    return a.fullName.compareTo(b.fullName);
  });
  return entries;
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

class _LeaderboardAccumulator {
  _LeaderboardAccumulator({required this.fullName});

  String fullName;
  final Set<String> presentDays = <String>{};
}

class _LeaderboardEntry {
  const _LeaderboardEntry({
    required this.fullName,
    required this.daysPresent,
  });

  final String fullName;
  final int daysPresent;
}

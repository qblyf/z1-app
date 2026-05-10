import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../api/calendar_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 行事历 - 我验收的列表页
/// 对应 PWA /pages/path-d/my-calendar/check-list.tsx
/// 显示当前用户作为验收人的行事历任务，含"未验收"和"已验收"两个Tab
class CalendarCheckListPage extends ConsumerStatefulWidget {
  const CalendarCheckListPage({super.key});

  @override
  ConsumerState<CalendarCheckListPage> createState() => _CalendarCheckListPageState();
}

class _CalendarCheckListPageState extends ConsumerState<CalendarCheckListPage> {
  final CalendarApi _api = CalendarApi();

  bool _uncheckedMode = true; // true=未验收，false=已验收
  List<CalendarSendTask> _uncheckedList = [];
  List<CalendarSendTask> _checkedList = [];
  Map<String, List<CalendarSendTask>> _groupedChecked = {};
  int _checkedTotal = 0;
  bool _isLoading = false;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUnchecked();
  }

  String get _dateRangeText =>
      '${DateFormat('yyyy.MM.dd').format(_startDate)}-${DateFormat('MM.dd').format(_endDate)}';

  Future<void> _loadUnchecked() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getMyCalendarCheckList(unchecked: true);
      if (mounted) {
        setState(() {
          _uncheckedList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChecked() async {
    setState(() => _isLoading = true);
    try {
      final startUnix = _startDate.millisecondsSinceEpoch ~/ 1000;
      final endUnix = _endDate.millisecondsSinceEpoch ~/ 1000;

      final counts = await _api.getMyCalendarCheckCount(
        statStartAt: startUnix,
        statEndAt: endUnix,
      );
      final finishedCount = counts
          .firstWhere((c) => c.status == 'finished',
              orElse: () => CalendarStatusCount(status: 'finished', count: 0))
          .count;

      if (finishedCount < 1) {
        if (mounted) {
          setState(() {
            _checkedList = [];
            _groupedChecked = {};
            _checkedTotal = 0;
            _isLoading = false;
          });
        }
        return;
      }

      final list = await _api.getMyCalendarCheckList(
        unchecked: false,
        statStartAt: startUnix,
        statEndAt: endUnix,
        limit: 300,
      );

      // 按 categoryName 分组
      final grouped = <String, List<CalendarSendTask>>{};
      for (final task in list) {
        final key = task.categoryName ?? '未分类';
        grouped.putIfAbsent(key, () => []).add(task);
      }

      if (mounted) {
        setState(() {
          _checkedList = list;
          _groupedChecked = grouped;
          _checkedTotal = finishedCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchTab(bool unchecked) {
    if (_uncheckedMode == unchecked) return;
    setState(() => _uncheckedMode = unchecked);
    if (unchecked) {
      _loadUnchecked();
    } else {
      _loadChecked();
    }
  }

  Future<void> _showDateRangePicker() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(
                    child: const Text('确认'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadChecked();
                    }),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _startDate,
                onDateTimeChanged: (d) => setState(() => _startDate = d),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _endDate,
                onDateTimeChanged: (d) => setState(() => _endDate = d),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int ts) {
    if (ts == 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'doing':
        return const Color(0xFF0A84FF);
      case 'unchecked':
        return const Color(0xFFFF9500);
      case 'finished':
        return const Color(0xFF30D158);
      case 'overdueFinished':
        return const Color(0xFFFF9F0A);
      case 'unfinished':
        return const Color(0xFFFF3B30);
      case 'invalid':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'doing':
        return '进行中';
      case 'unchecked':
        return '待验收';
      case 'finished':
        return '已完成';
      case 'overdueFinished':
        return '逾期完成';
      case 'unfinished':
        return '未完成';
      case 'invalid':
        return '已作废';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我验收的'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 日期范围选择（已验收tab）
            if (!_uncheckedMode)
              GestureDetector(
                onTap: _showDateRangePicker,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar,
                          size: 15, color: Color(0xFF0A84FF)),
                      const SizedBox(width: 8),
                      Text(_dateRangeText,
                          style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14, color: Color(0xFF999999)),
                    ],
                  ),
                ),
              ),

            // Tab切换
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabCountCard(
                      label: '未验收',
                      count: _uncheckedMode ? _uncheckedList.length : null,
                      isActive: _uncheckedMode,
                      color: const Color(0xFF0A84FF),
                      onTap: () => _switchTab(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TabCountCard(
                      label: '已验收',
                      count: !_uncheckedMode ? _checkedTotal : null,
                      isActive: !_uncheckedMode,
                      color: const Color(0xFF30D158),
                      onTap: () => _switchTab(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _uncheckedMode
                      ? _buildUncheckedList()
                      : _buildCheckedList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUncheckedList() {
    if (_uncheckedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar,
                size: 64, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text('暂无待验收任务', style: AppText.body),
          ],
        ),
      );
    }

    // 按 categoryName 分组
    final grouped = <String, List<CalendarSendTask>>{};
    for (final task in _uncheckedList) {
      final key = task.categoryName ?? '未分类';
      grouped.putIfAbsent(key, () => []).add(task);
    }

    return _RefreshWrapper(
      onRefresh: _loadUnchecked,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: grouped.length,
        itemBuilder: (ctx, i) {
          final entry = grouped.entries.elementAt(i);
          return _CategoryGroup(
            categoryName: entry.key,
            tasks: entry.value,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
            formatTime: _formatTime,
            onTaskTap: (task) =>
                context.push('/task-management/log/${task.taskLogID}'),
          );
        },
      ),
    );
  }

  Widget _buildCheckedList() {
    if (_checkedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar,
                size: 64, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text('暂无已验收任务', style: AppText.body),
          ],
        ),
      );
    }

    return _RefreshWrapper(
      onRefresh: _loadChecked,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _groupedChecked.length,
        itemBuilder: (ctx, i) {
          final entry = _groupedChecked.entries.elementAt(i);
          return _CategoryGroup(
            categoryName: entry.key,
            tasks: entry.value,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
            formatTime: _formatTime,
            onTaskTap: (task) =>
                context.push('/task-management/log/${task.taskLogID}'),
          );
        },
      ),
    );
  }
}

class _TabCountCard extends StatelessWidget {
  final String label;
  final int? count;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _TabCountCard({
    required this.label,
    required this.count,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              count != null ? '$count' : '-',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isActive ? color : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? color : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _RefreshWrapper({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

class _CategoryGroup extends StatefulWidget {
  final String categoryName;
  final List<CalendarSendTask> tasks;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final String Function(int) formatTime;
  final void Function(CalendarSendTask) onTaskTap;

  const _CategoryGroup({
    required this.categoryName,
    required this.tasks,
    required this.statusColor,
    required this.statusLabel,
    required this.formatTime,
    required this.onTaskTap,
  });

  @override
  State<_CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends State<_CategoryGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '总数: ${widget.tasks.length}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFFB6D1F9)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: widget.tasks.asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final task = entry.value;
                return Column(
                  children: [
                    if (index > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: const Color(0xFFEEEEEE),
                      ),
                    _TaskCard(
                      task: task,
                      statusColor: widget.statusColor(task.taskLogStatus),
                      statusLabel: widget.statusLabel(task.taskLogStatus),
                      formatTime: widget.formatTime,
                      onTap: () => widget.onTaskTap(task),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final CalendarSendTask task;
  final Color statusColor;
  final String statusLabel;
  final String Function(int) formatTime;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.statusColor,
    required this.statusLabel,
    required this.formatTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.taskName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(fontSize: 12, color: statusColor)),
                ),
              ],
            ),
            if (task.introduction != null && task.introduction!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.introduction!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(CupertinoIcons.clock,
                    size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(formatTime(task.startAt),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                if (task.duration > 0) ...[
                  const SizedBox(width: 8),
                  Text('时长 ${task.duration ~/ 60}h',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999))),
                ],
                const Spacer(),
                const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: Color(0xFFC7C7CC)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

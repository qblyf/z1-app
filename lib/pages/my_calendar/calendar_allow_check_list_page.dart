import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/calendar_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 行事历 - 待验收列表页
/// 对应 PWA /pages/path-d/my-calendar/allow-check-list.tsx
/// 显示当前用户可验收的所有行事历任务，按类别分组
class CalendarAllowCheckListPage extends ConsumerStatefulWidget {
  const CalendarAllowCheckListPage({super.key});

  @override
  ConsumerState<CalendarAllowCheckListPage> createState() => _CalendarAllowCheckListPageState();
}

class _CalendarAllowCheckListPageState extends ConsumerState<CalendarAllowCheckListPage> {
  final CalendarApi _api = CalendarApi();

  bool _isLoading = true;
  String? _errorMsg;
  Map<String, List<CalendarSendTask>> _groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final list = await _api.getMyCheckCalendar();

      // 按 categoryName 分组
      final grouped = <String, List<CalendarSendTask>>{};
      for (final task in list) {
        final key = task.categoryName ?? '未分类';
        grouped.putIfAbsent(key, () => []).add(task);
      }

      if (mounted) {
        setState(() {
          _groupedTasks = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMsg = '加载失败：$e'; });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'doing': return const Color(0xFF0A84FF);
      case 'unchecked': return const Color(0xFFFF9500);
      case 'finished': return const Color(0xFF30D158);
      case 'overdueFinished': return const Color(0xFFFF9F0A);
      case 'unfinished': return const Color(0xFFFF3B30);
      case 'invalid': return const Color(0xFF8E8E93);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'doing': return '进行中';
      case 'unchecked': return '待验收';
      case 'finished': return '已完成';
      case 'overdueFinished': return '逾期完成';
      case 'unfinished': return '未完成';
      case 'invalid': return '已作废';
      default: return status;
    }
  }

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('待验收'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMsg != null
                ? Center(child: Text(_errorMsg!, style: AppText.body))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_groupedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar, size: 64, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text('暂无待验收任务', style: AppText.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async { await _loadData(); },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _groupedTasks.length,
        itemBuilder: (ctx, i) {
          final entry = _groupedTasks.entries.elementAt(i);
          return _CategoryGroup(
            categoryName: entry.key,
            tasks: entry.value,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
            formatTime: _formatTime,
          );
        },
      ),
    );
  }
}

class RefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const RefreshIndicator({super.key, required this.onRefresh, required this.child});

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

  const _CategoryGroup({
    required this.categoryName,
    required this.tasks,
    required this.statusColor,
    required this.statusLabel,
    required this.formatTime,
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
        // 分类标题
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
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
                        style: const TextStyle(fontSize: 15, color: CupertinoColors.white, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '总数: ${widget.tasks.length}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFFB6D1F9)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        // 任务列表
        if (_expanded) ...[
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: widget.tasks.asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final task = entry.value;
                final color = widget.statusColor(task.taskLogStatus);
                return Column(
                  children: [
                    if (index > 0)
                      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0xFFEEEEEE)),
                    _TaskCard(task: task, color: color, statusLabel: widget.statusLabel(task.taskLogStatus), formatTime: widget.formatTime),
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
  final Color color;
  final String statusLabel;
  final String Function(int) formatTime;

  const _TaskCard({required this.task, required this.color, required this.statusLabel, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/task-management/log/${task.taskLogID}'),
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 12, color: color)),
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
                const Icon(CupertinoIcons.clock, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(formatTime(task.startAt), style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                if (task.duration > 0) ...[
                  const SizedBox(width: 8),
                  Text('时长 ${task.duration ~/ 60}h', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

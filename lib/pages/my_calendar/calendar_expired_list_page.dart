import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/calendar_api.dart';
import '../../theme/app_theme.dart';

/// 行事历 - 已过期列表页
/// 对应 PWA /pages/path-d/my-calendar/expired-list.tsx
/// 显示已过期的行事历任务，支持按状态筛选
class CalendarExpiredListPage extends ConsumerStatefulWidget {
  const CalendarExpiredListPage({super.key});

  @override
  ConsumerState<CalendarExpiredListPage> createState() => _CalendarExpiredListPageState();
}

class _CalendarExpiredListPageState extends ConsumerState<CalendarExpiredListPage> {
  final CalendarApi _api = CalendarApi();

  bool _isLoading = true;
  String? _errorMsg;
  List<CalendarSendTask> _allTasks = [];

  // 筛选 Tab: unfinished / finished / all
  int _tabIndex = 2; // 默认显示全部

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final list = await _api.getMyOverdueCalendarList(
        startAt: DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
        endAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      if (mounted) {
        setState(() { _allTasks = list; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMsg = '加载失败：$e'; });
      }
    }
  }

  List<CalendarSendTask> get _filteredTasks {
    switch (_tabIndex) {
      case 0: return _allTasks.where((t) => t.taskLogStatus == 'unfinished').toList();
      case 1: return _allTasks.where((t) => t.taskLogStatus == 'finished' || t.taskLogStatus == 'overdueFinished').toList();
      default: return _allTasks;
    }
  }

  int get _unfinishedCount => _allTasks.where((t) => t.taskLogStatus == 'unfinished').length;
  int get _finishedCount => _allTasks.where((t) => t.taskLogStatus == 'finished' || t.taskLogStatus == 'overdueFinished').length;

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
        middle: const Text('已过期'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tab 切换
            Container(
              color: CupertinoColors.white,
              child: Row(
                children: [
                  _TabButton(label: '未完成($_unfinishedCount)', isActive: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                  _TabButton(label: '已完成($_finishedCount)', isActive: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                  _TabButton(label: '全部($_allTasks.length)', isActive: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _errorMsg != null
                      ? Center(child: Text(_errorMsg!, style: AppText.body))
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final tasks = _filteredTasks;
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.calendar, size: 64, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text('暂无数据', style: AppText.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async { await _loadData(); },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: tasks.length,
        itemBuilder: (ctx, i) => _ExpiredTaskCard(
          task: tasks[i],
          statusColor: _statusColor(tasks[i].taskLogStatus),
          statusLabel: _statusLabel(tasks[i].taskLogStatus),
          formatTime: _formatTime,
        ),
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

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Expanded(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFFF6B6B) : CupertinoColors.systemGrey5,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? const Color(0xFFFF6B6B) : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _ExpiredTaskCard extends StatelessWidget {
  final CalendarSendTask task;
  final Color statusColor;
  final String statusLabel;
  final String Function(int) formatTime;

  const _ExpiredTaskCard({
    required this.task,
    required this.statusColor,
    required this.statusLabel,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/task-management/log/${task.taskLogID}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.categoryName != null && task.categoryName!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(task.categoryName!, style: const TextStyle(fontSize: 11, color: Color(0xFF5856D6))),
                  ),
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
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor)),
                ),
              ],
            ),
            if (task.introduction != null && task.introduction!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.introduction!, style: const TextStyle(fontSize: 13, color: Color(0xFF666666)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 13, color: Color(0xFFFF3B30)),
                const SizedBox(width: 4),
                Text(formatTime(task.startAt), style: const TextStyle(fontSize: 12, color: Color(0xFFFF3B30))),
                if (task.duration > 0) ...[
                  const SizedBox(width: 12),
                  Text('时长 ${task.duration ~/ 60}h', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.person, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text('负责人ID: ${task.responsibleEmployee}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const Spacer(),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

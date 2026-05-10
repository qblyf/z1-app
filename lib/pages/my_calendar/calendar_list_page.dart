import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/calendar_api.dart';
import '../../models/calendar.dart';
import '../../providers/calendar_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 行事历列表页面
class CalendarListPage extends ConsumerStatefulWidget {
  const CalendarListPage({super.key});

  @override
  ConsumerState<CalendarListPage> createState() => _CalendarListPageState();
}

class _CalendarListPageState extends ConsumerState<CalendarListPage> {
  int _selectedIndex = 0;
  final _tabs = ['进行中', '已结束', '待验收', '岗位任务'];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的行事历'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('提示'),
                content: const Text('创建行事历功能开发中...'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 分段选择器
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedIndex,
                  children: {
                    for (int i = 0; i < _tabs.length; i++)
                      i: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(_tabs[i], style: const TextStyle(fontSize: 13)),
                      ),
                  },
                  onValueChanged: (index) {
                    if (index == null) return;
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),

            // 内容
            Expanded(
              child: [
                const _DoingCalendarView(),
                const _ExpiredCalendarView(),
                const _PendingCheckCalendarView(),
                const _TaskCalendarView(),
              ][_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoingCalendarView extends ConsumerWidget {
  const _DoingCalendarView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(doingCalendarProvider);

    return calendarAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          return const EmptyWidget(
            message: '暂无进行中的行事历',
            icon: CupertinoIcons.calendar_badge_plus,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(doingCalendarProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CalendarCard(calendar: calendars[index]),
                  childCount: calendars.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(doingCalendarProvider),
      ),
    );
  }
}

class _ExpiredCalendarView extends ConsumerStatefulWidget {
  const _ExpiredCalendarView();

  @override
  ConsumerState<_ExpiredCalendarView> createState() => _ExpiredCalendarViewState();
}

class _ExpiredCalendarViewState extends ConsumerState<_ExpiredCalendarView> {
  final _scrollController = ScrollController();
  int _offset = 0;
  List<CalendarTask> _calendars = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
    });

    try {
      final api = ref.read(calendarApiProvider);
      final calendars = await api.getExpired(offset: 0);
      setState(() {
        _calendars = calendars;
        _offset = calendars.length;
        _hasMore = calendars.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final api = ref.read(calendarApiProvider);
      final calendars = await api.getExpired(offset: _offset);
      setState(() {
        _calendars.addAll(calendars);
        _offset += calendars.length;
        _hasMore = calendars.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_calendars.isEmpty && _isLoading) {
      return const LoadingWidget(message: '加载中...');
    }

    if (_calendars.isEmpty) {
      return const EmptyWidget(
        message: '暂无已结束的行事历',
        icon: CupertinoIcons.calendar,
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _calendars.length) {
                  return _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CupertinoActivityIndicator()),
                        )
                      : const SizedBox.shrink();
                }
                return _CalendarCard(calendar: _calendars[index]);
              },
              childCount: _calendars.length + (_hasMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingCheckCalendarView extends ConsumerWidget {
  const _PendingCheckCalendarView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(pendingCheckCalendarProvider);

    return calendarAsync.when(
      data: (calendars) {
        if (calendars.isEmpty) {
          return const EmptyWidget(
            message: '暂无待验收的行事历',
            icon: CupertinoIcons.clock,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(pendingCheckCalendarProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cal = calendars[index];
                    return _CalendarCard(
                      calendar: cal,
                      showApproveButton: true,
                      onTap: () {
                        final id = int.tryParse(cal.taskLogIdent) ?? 0;
                        context.push(Routes.taskLogDetail.replaceAll(':id', id.toString()));
                      },
                    );
                  },
                  childCount: calendars.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(pendingCheckCalendarProvider),
      ),
    );
  }
}

class _TaskCalendarView extends ConsumerStatefulWidget {
  const _TaskCalendarView();

  @override
  ConsumerState<_TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends ConsumerState<_TaskCalendarView> {
  late final CalendarApi _calendarApi;

  List<CalendarSendTask> _list = [];
  Map<String, List<CalendarSendTask>> _grouped = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calendarApi = ref.read(calendarApiProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _calendarApi.getMyCalendarList(
        currentUserType: 'responsible',
        limit: 500,
      );

      // 按 categoryName 分组
      final grouped = <String, List<CalendarSendTask>>{};
      for (final task in list) {
        final key = task.categoryName ?? '其他任务';
        grouped.putIfAbsent(key, () => []).add(task);
      }

      if (mounted) {
        setState(() {
          _list = list;
          _grouped = grouped;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

  String _formatTime(int ts) {
    if (ts == 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_list.isEmpty) {
      return const EmptyWidget(
        message: '暂无岗位任务',
        icon: CupertinoIcons.doc_text,
      );
    }

    return _TaskRefreshWrapper(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _grouped.length,
        itemBuilder: (ctx, i) {
          final entry = _grouped.entries.elementAt(i);
          return _TaskCategoryGroup(
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

class _TaskRefreshWrapper extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _TaskRefreshWrapper({required this.onRefresh, required this.child});

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

class _TaskCategoryGroup extends StatefulWidget {
  final String categoryName;
  final List<CalendarSendTask> tasks;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final String Function(int) formatTime;

  const _TaskCategoryGroup({
    required this.categoryName,
    required this.tasks,
    required this.statusColor,
    required this.statusLabel,
    required this.formatTime,
  });

  @override
  State<_TaskCategoryGroup> createState() => _TaskCategoryGroupState();
}

class _TaskCategoryGroupState extends State<_TaskCategoryGroup> {
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
              color: const Color(0xFF5856D6),
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
                  _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
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
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final CalendarSendTask task;
  final Color statusColor;
  final String statusLabel;
  final String Function(int) formatTime;

  const _TaskCard({
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 14,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatTime(task.startAt),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '>',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF2D6EC9).withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '>',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D6EC9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  final CalendarTask calendar;
  final bool showApproveButton;
  final VoidCallback? onTap;

  const _CalendarCard({
    required this.calendar,
    this.showApproveButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap ?? () => context.push('/calendar/${calendar.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      calendar.title,
                      style: AppText.subtitle,
                    ),
                  ),
                  StatusBadge(
                    label: calendar.statusLabel,
                    color: _getStatusColor(calendar.status),
                  ),
                ],
              ),
              if (calendar.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  calendar.description!,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 4),
                  DateTimeText(unix: calendar.startTime, format: 'MM-dd HH:mm'),
                  const Text(' - ', style: TextStyle(color: CupertinoColors.systemGrey)),
                  DateTimeText(unix: calendar.endTime, format: 'HH:mm'),
                ],
              ),
              if (calendar.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      size: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calendar.location!,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (calendar.assigneeName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person,
                      size: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calendar.assigneeName!,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (calendar.isCheckedIn) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle,
                      size: 14,
                      color: CupertinoColors.activeGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '已签到',
                      style: TextStyle(
                        color: CupertinoColors.activeGreen,
                        fontSize: 12,
                      ),
                    ),
                    if (calendar.isCheckedOut) ...[
                      const SizedBox(width: 16),
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 14,
                        color: CupertinoColors.activeGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '已签退',
                        style: TextStyle(
                          color: CupertinoColors.activeGreen,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (showApproveButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => _handleApprove(context, ref),
                    child: const Text('验收'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    final actionService = ref.read(calendarActionProvider);
    final result = await actionService.approve(calendar.id);

    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(result.success ? '成功' : '失败'),
          content: Text(result.success ? '验收成功' : '验收失败: ${result.message}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return CupertinoColors.activeBlue;
      case 2:
        return CupertinoColors.activeOrange;
      case 3:
        return CupertinoColors.activeGreen;
      case 4:
        return CupertinoColors.systemGrey;
      case 5:
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

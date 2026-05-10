import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/calendar.dart';
import '../../providers/calendar_provider.dart';
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
                  (context, index) => _CalendarCard(
                    calendar: calendars[index],
                    showApproveButton: true,
                  ),
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

class _TaskCalendarView extends ConsumerWidget {
  const _TaskCalendarView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EmptyWidget(
      message: '暂无岗位任务',
      icon: CupertinoIcons.doc_text,
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  final CalendarTask calendar;
  final bool showApproveButton;

  const _CalendarCard({
    required this.calendar,
    this.showApproveButton = false,
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
        onPressed: () => context.push('/calendar/${calendar.id}'),
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

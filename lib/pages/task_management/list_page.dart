import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../api/task_management_api.dart';
import '../../models/task_management.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

/// 岗位任务管理列表页
class TaskManagementPage extends ConsumerStatefulWidget {
  const TaskManagementPage({super.key});

  @override
  ConsumerState<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends ConsumerState<TaskManagementPage> {
  int _tabIndex = 0; // 0=任务分配 1=执行记录 2=任务统计

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
                leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
        middle: const Text('岗位任务'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => context.push('/task-management/template/edit'),
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
                  Expanded(child: _TabButton(label: '任务分配', isActive: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0))),
                  Expanded(child: _TabButton(label: '执行记录', isActive: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1))),
                  Expanded(child: _TabButton(label: '任务统计', isActive: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2))),
                  Expanded(child: _TabButton(label: '模板', isActive: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3))),
                ],
              ),
            ),
            Expanded(
              child: _tabIndex == 0
                  ? const _AllocationListView()
                  : _tabIndex == 1
                      ? const _LogListView()
                      : _tabIndex == 2
                          ? const _StatisticsTab()
                          : const _TemplateListView(),
            ),
          ],
        ),
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey5,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isActive ? const Color(0xFF0A84FF) : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 任务分配列表
class _AllocationListView extends ConsumerStatefulWidget {
  const _AllocationListView();

  @override
  ConsumerState<_AllocationListView> createState() => _AllocationListViewState();
}

class _AllocationListViewState extends ConsumerState<_AllocationListView> {
  List<TaskAllocation> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) { _page = 0; _hasMore = true; }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final api = TaskManagementApi();
      final data = await api.listAllocations(limit: 20, offset: _page * 20);
      setState(() {
        if (refresh) _list = data; else _list.addAll(data);
        _hasMore = data.length >= 20;
        _isLoading = false;
        _page++;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _list.isEmpty && !_isLoading
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.list_bullet, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text('暂无任务分配', style: AppText.caption),
              ],
            ),
          )
        : NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
                _loadData();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: () => _loadData(refresh: true)),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AllocationCard(item: _list[i]),
                      childCount: _list.length,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  ),
              ],
            ),
          );
  }
}

/// 执行记录列表
class _LogListView extends ConsumerStatefulWidget {
  const _LogListView();

  @override
  ConsumerState<_LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends ConsumerState<_LogListView> {
  List<TaskAllocationLog> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) { _page = 0; _hasMore = true; }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final api = TaskManagementApi();
      List<int>? statusValues;
      if (_statusFilter != null) statusValues = [_statusFilter!];

      final data = await api.listLogs(statusValues: statusValues, limit: 20, offset: _page * 20);
      setState(() {
        if (refresh) _list = data; else _list.addAll(data);
        _hasMore = data.length >= 20;
        _isLoading = false;
        _page++;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 状态筛选
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _StatusChip(
                label: '全部',
                isActive: _statusFilter == null,
                onTap: () => setState(() { _statusFilter = null; _loadData(refresh: true); }),
              ),
              const SizedBox(width: 8),
              ...TaskAllocationStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StatusChip(
                  label: s.label,
                  isActive: _statusFilter == s.value,
                  color: s.color,
                  onTap: () => setState(() { _statusFilter = s.value; _loadData(refresh: true); }),
                ),
              )),
            ],
          ),
        ),
        Expanded(
          child: _list.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.doc_text, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 8),
                      Text('暂无执行记录', style: AppText.caption),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
                      _loadData();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(onRefresh: () => _loadData(refresh: true)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _LogCard(item: _list[i]),
                            childCount: _list.length,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CupertinoActivityIndicator()),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF0A84FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? chipColor : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? CupertinoColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final TaskAllocation item;

  const _AllocationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/task-management/allocation-info/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                Expanded(
                  child: Text(
                    item.taskTemplateName ?? '任务模板${item.taskTemplateID}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.type.label,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF)),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.repeat, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.repeatCycleLabel, style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.clock, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('持续 ${item.duration}h', style: AppText.caption),
              ],
            ),
            if (item.responsibleEmployeeNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.person_2, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.responsibleEmployeeNames.where((n) => n != null).join('、'),
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.calendar, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.formattedCreatedAt, style: AppText.caption),
                const Spacer(),
                Text(item.creatorName ?? '-', style: AppText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final TaskAllocationLog item;

  const _LogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/task-management/log/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                Expanded(
                  child: Text(
                    item.taskTemplateName ?? '任务${item.taskTemplateID}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(fontSize: 12, color: item.status.color, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.employeeName ?? '-', style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.departmentName ?? '-', style: AppText.caption),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(CupertinoIcons.time, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${item.formattedStartAt} → ${item.formattedEndAt}', style: AppText.caption),
              ],
            ),
            if (item.finalScore != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(CupertinoIcons.star_fill, size: 14, color: Color(0xFFFF9500)),
                  const SizedBox(width: 4),
                  Text(
                    '得分：${item.selfScore ?? '-'}/${item.finalScore}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFFF9500), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 任务统计 Tab
class _StatisticsTab extends ConsumerStatefulWidget {
  const _StatisticsTab();

  @override
  ConsumerState<_StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<_StatisticsTab> {
  final TaskManagementApi _api = TaskManagementApi();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isMineOnly = true;
  String _dimension = 'employee';
  List<TaskLogCountItem> _countSummary = [];
  List<TaskLogStatisticItem> _statistics = [];
  bool _isLoading = false;
  bool _hasError = false;

  String get _dateRangeText =>
      '${DateFormat('yyyy.MM.dd').format(_startDate)}-${DateFormat('MM.dd').format(_endDate)}';

  int get _totalCount => _countSummary.fold(0, (sum, e) => sum + e.count);

  int _countForStatus(String status) =>
      _countSummary.where((e) => e.status == status).fold(0, (sum, e) => sum + e.count);

  int get _finishedCount =>
      _countForStatus('finished') + _countForStatus('overdueFinished');

  double get _overallRate => _totalCount > 0 ? (_finishedCount / _totalCount) * 100 : 0.0;

  double get _onTimeRate {
    final finished = _countForStatus('finished');
    return _totalCount > 0 ? (finished / _totalCount) * 100 : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final startUnix = DateTime(_startDate.year, _startDate.month, _startDate.day)
          .millisecondsSinceEpoch ~/ 1000;
      final endUnix = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)
          .millisecondsSinceEpoch ~/ 1000;
      final currentUser = ref.read(currentUserProvider).value;
      List<int>? giveBy;
      List<int>? userIdents;
      if (_isMineOnly && currentUser != null) {
        giveBy = [currentUser.userIdent];
        userIdents = [currentUser.userIdent];
      }
      final results = await Future.wait([
        _api.taskLogCount(statStartAt: startUnix, statEndAt: endUnix, giveBy: giveBy),
        _api.taskLogStatistic(startAt: startUnix, endAt: endUnix, userIdents: userIdents, dimension: _dimension),
      ]);
      if (mounted) {
        setState(() {
          _countSummary = results[0] as List<TaskLogCountItem>;
          _statistics = results[1] as List<TaskLogStatisticItem>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
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
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(child: const Text('确认'), onPressed: () { Navigator.pop(ctx); _loadData(); }),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _countSummary.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_hasError && _countSummary.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            Text('加载失败', style: AppText.body),
            const SizedBox(height: 12),
            CupertinoButton(onPressed: _loadData, child: const Text('重新加载')),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: () => _loadData()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterRow(),
                const SizedBox(height: AppSpacing.md),
                _buildCountCards(),
                const SizedBox(height: AppSpacing.md),
                _buildRateCard('总体完成率', _overallRate),
                const SizedBox(height: AppSpacing.sm),
                _buildRateCard('按时完成率', _onTimeRate),
                const SizedBox(height: AppSpacing.md),
                _buildSectionTitle(),
                if (_statistics.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: Text('暂无数据', style: AppText.caption)),
                  )
                else
                  ..._statistics.map((s) => _buildStatisticCard(s)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _showDateRangePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 13, color: CupertinoColors.systemGrey),
                  const SizedBox(width: 5),
                  Text(_dateRangeText, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _isMineOnly = !_isMineOnly; _loadData(); }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_isMineOnly ? '我分配的' : '全部',
                      style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 11, color: CupertinoColors.systemGrey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: _showDimensionPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CupertinoColors.systemGrey5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_dimensionLabel,
                      style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 11, color: CupertinoColors.systemGrey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _dimensionLabel {
    switch (_dimension) {
      case 'employee': return '按职员';
      case 'label': return '按标签';
      case 'taskTemplateCate': return '按分类';
      default: return '按职员';
    }
  }

  Future<void> _showDimensionPicker() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(ctx); setState(() => _dimension = 'employee'); _loadData(); }, child: const Text('按职员')),
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(ctx); setState(() => _dimension = 'label'); _loadData(); }, child: const Text('按标签')),
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(ctx); setState(() => _dimension = 'taskTemplateCate'); _loadData(); }, child: const Text('按分类')),
        ],
        cancelButton: CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ),
    );
  }

  Widget _buildCountCards() {
    return Row(
      children: [
        _buildCountCard('全部', _totalCount, const Color(0xFF1677FF)),
        const SizedBox(width: 6),
        _buildCountCard('已逾期', _countForStatus('unfinished'), const Color(0xFFFF9500)),
        const SizedBox(width: 6),
        _buildCountCard('进行中', _countForStatus('doing'), const Color(0xFF36CBCF)),
        const SizedBox(width: 6),
        _buildCountCard('待验收', _countForStatus('unchecked'), const Color(0xFF722ED1)),
        const SizedBox(width: 6),
        _buildCountCard('已完成', _finishedCount, const Color(0xFF52C41A)),
      ],
    );
  }

  Widget _buildCountCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(5),
          color: color.withValues(alpha: 0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(String label, double rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text('${rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: rate / 100,
                backgroundColor: CupertinoColors.systemGrey5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  rate >= 80 ? const Color(0xFF52C41A)
                      : rate >= 50 ? const Color(0xFFFF9500)
                      : const Color(0xFFFF4D4F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    String title; IconData icon;
    switch (_dimension) {
      case 'employee': title = '员工任务完成情况'; icon = CupertinoIcons.person_fill; break;
      case 'label': title = '标签任务统计'; icon = CupertinoIcons.tag_fill; break;
      case 'taskTemplateCate': title = '分类任务统计'; icon = CupertinoIcons.list_bullet; break;
      default: title = '任务统计'; icon = CupertinoIcons.chart_bar_fill;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 15, color: CupertinoColors.label),
          const SizedBox(width: 5),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatisticCard(TaskLogStatisticItem item) {
    final total = item.statistic.fold(0, (sum, e) => sum + e.count);
    final finished = item.statistic
        .where((e) => e.status == 'finished' || e.status == 'overdueFinished')
        .fold(0, (sum, e) => sum + e.count);
    final rate = total > 0 ? (finished / total) * 100 : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: CupertinoColors.systemGrey5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getItemTitle(item), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCountItem('全部', total, null),
              _buildStatCountItem('已逾期',
                  item.statistic.where((e) => e.status == 'unfinished').fold(0, (s, e) => s + e.count),
                  const Color(0xFFFF9500)),
              _buildStatCountItem('进行中',
                  item.statistic.where((e) => e.status == 'doing').fold(0, (s, e) => s + e.count),
                  const Color(0xFF36CBCF)),
              _buildStatCountItem('待验收',
                  item.statistic.where((e) => e.status == 'unchecked').fold(0, (s, e) => s + e.count),
                  const Color(0xFF722ED1)),
              _buildStatCountItem('已完成', finished, const Color(0xFF52C41A)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    backgroundColor: CupertinoColors.systemGrey5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 80 ? const Color(0xFF52C41A)
                          : rate >= 50 ? const Color(0xFFFF9500)
                          : const Color(0xFFFF4D4F),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('按时完成率', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  Text('${rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCountItem(String label, int count, Color? color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? CupertinoColors.label)),
          Text(label, style: TextStyle(fontSize: 10, color: color ?? AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _getItemTitle(TaskLogStatisticItem item) {
    if (item.userIdent != null) return '员工 #${item.userIdent}';
    if (item.labelID != null) return '标签 #${item.labelID}';
    if (item.taskTemplateCate != null) return item.taskTemplateCate!;
    return '-';
  }
}

// ── 任务模板列表 ─────────────────────────────────────────────

class _TemplateListView extends ConsumerStatefulWidget {
  const _TemplateListView();

  @override
  ConsumerState<_TemplateListView> createState() => _TemplateListViewState();
}

class _TemplateListViewState extends ConsumerState<_TemplateListView> {
  final TaskManagementApi _api = TaskManagementApi();
  List<TaskTemplate> _list = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 0;
  String? _hasError;

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) { _page = 0; _hasMore = true; }
    if (!_hasMore) return;
    setState(() { _isLoading = true; _hasError = null; });
    try {
      final data = await _api.listTaskTemplates(limit: 20, offset: _page * 20);
      if (!mounted) return;
      setState(() {
        if (refresh) _list = data; else _list.addAll(data);
        _hasMore = data.length >= 20;
        _isLoading = false;
        _page++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _hasError = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError != null && _list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            Text('加载失败', style: AppText.body),
            const SizedBox(height: 12),
            CupertinoButton(onPressed: () => _loadData(refresh: true), child: const Text('重新加载')),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
          _loadData();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: () => _loadData(refresh: true)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TemplateCard(
                  item: _list[i],
                  onTap: () => context.push('/task-management/template/edit/${_list[i].id}'),
                  onToggleStatus: () async {
                    final item = _list[i];
                    final newStatus = item.status == 'enabled' ? 'disabled' : 'enabled';
                    await _api.invalidateTaskTemplate(item.id, disable: newStatus == 'disabled');
                    _loadData(refresh: true);
                  },
                ),
                childCount: _list.length,
              ),
            ),
          ),
          if (_isLoading && _list.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
          if (_list.isEmpty && !_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3),
                      const SizedBox(height: 12),
                      Text('暂无任务模板', style: AppText.caption),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        child: const Text('新建模板'),
                        onPressed: () => context.push('/task-management/template/edit'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TaskTemplate item;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const _TemplateCard({required this.item, required this.onTap, required this.onToggleStatus});

  @override
  Widget build(BuildContext context) {
    final isEnabled = item.status == 'enabled';
    final cateLabel = TaskTemplateCate.fromValue(item.taskTemplateCate)?.label ?? item.taskTemplateCate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: isEnabled ? null : Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isEnabled ? const Color(0xFF30D158) : CupertinoColors.systemGrey3).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEnabled ? '已启用' : '已停用',
                    style: AppText.caption.copyWith(
                      color: isEnabled ? const Color(0xFF30D158) : CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: Icon(
                    isEnabled ? CupertinoIcons.pause_circle : CupertinoIcons.play_circle,
                    color: CupertinoColors.systemGrey,
                    size: 22,
                  ),
                  onPressed: onToggleStatus,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(cateLabel, style: AppText.caption.copyWith(color: const Color(0xFF0A84FF))),
                ),
                const SizedBox(width: 8),
                Text('权重: ${item.taskWeight}', style: AppText.caption),
                const Spacer(),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

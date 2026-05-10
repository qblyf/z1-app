import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_inspection_api.dart';
import '../../models/store_inspection.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 门店巡店列表页
class StoreInspectionListPage extends ConsumerStatefulWidget {
  const StoreInspectionListPage({super.key});

  @override
  ConsumerState<StoreInspectionListPage> createState() => _StoreInspectionListPageState();
}

class _StoreInspectionListPageState extends ConsumerState<StoreInspectionListPage> {
  List<StoreInspectionLog> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int _total = 0;

  int? _statusFilter;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

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
      final api = StoreInspectionApi();
      final minTime = _startDate.copyWith(hour: 0, minute: 0, second: 0);
      final maxTime = _endDate.copyWith(hour: 23, minute: 59, second: 59);

      List<int>? statusValues;
      if (_statusFilter != null) statusValues = [_statusFilter!];

      final total = await api.count(statusValues: statusValues);
      final data = await api.list(
        statusValues: statusValues,
        minCreatedAt: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: maxTime.millisecondsSinceEpoch ~/ 1000,
        limit: 20,
        offset: _page * 20,
      );

      setState(() {
        if (refresh) {
          _list = data;
        } else {
          _list.addAll(data);
        }
        _hasMore = data.length >= 20;
        _total = total;
        _isLoading = false;
        _page++;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _StoreInspectionFilterSheet(
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (status, start, end) {
          setState(() {
            _statusFilter = status;
            _startDate = start;
            _endDate = end;
          });
          _loadData(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('门店巡店'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: () => context.push('/store-inspection/ready'),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc_text),
              onPressed: () => context.push('/store-inspection/logs'),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.slider_horizontal_3),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Text('共 $_total 条', style: AppText.caption),
                  const Spacer(),
                  Text('本页 ${_list.length} 条', style: AppText.caption),
                ],
              ),
            ),
            Expanded(
              child: _list.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.map, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无巡店记录', style: AppText.caption),
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
                                (_, i) => _InspectionCard(log: _list[i]),
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
        ),
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final StoreInspectionLog log;

  const _InspectionCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/store-inspection/info/${log.logID}'),
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
                    log.inspectionName ?? '巡店任务',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: log.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(log.status.label,
                    style: TextStyle(fontSize: 12, color: log.status.color, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(log.departmentName ?? '部门${log.departmentID}', style: AppText.caption),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBF5AF2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(log.type.label, style: const TextStyle(fontSize: 11, color: Color(0xFFBF5AF2))),
                ),
                const SizedBox(width: 8),
                Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(log.assigneeName ?? '-', style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.calendar, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(log.formattedCreatedAt, style: AppText.caption),
              ],
            ),
            if (log.scoreDisplay != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(CupertinoIcons.star_fill, size: 14, color: Color(0xFFFF9500)),
                  const SizedBox(width: 4),
                  Text(
                    '得分：${log.scoreDisplay}',
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

class _StoreInspectionFilterSheet extends StatefulWidget {
  final int? statusFilter;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(int?, DateTime, DateTime) onApply;

  const _StoreInspectionFilterSheet({
    required this.statusFilter,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_StoreInspectionFilterSheet> createState() => _StoreInspectionFilterSheetState();
}

class _StoreInspectionFilterSheetState extends State<_StoreInspectionFilterSheet> {
  late int _statusIndex;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.statusFilter == null
        ? 0
        : StoreInspectionStatus.values.indexWhere((s) => s.value == widget.statusFilter) + 1;
    if (_statusIndex < 0) _statusIndex = 0;
    _start = widget.startDate;
    _end = widget.endDate;
  }

  int? get _selectedStatus {
    if (_statusIndex == 0) return null;
    final allStatuses = [null, ...StoreInspectionStatus.values];
    if (_statusIndex <= allStatuses.length) return allStatuses[_statusIndex]?.value;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md, right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('筛选', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('状态', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _StatusChip(label: '全部', isActive: _statusIndex == 0, onTap: () => setState(() => _statusIndex = 0)),
              ...StoreInspectionStatus.values.asMap().entries.map((e) =>
                _StatusChip(
                  label: e.value.label,
                  isActive: _statusIndex == e.key + 1,
                  onTap: () => setState(() => _statusIndex = e.key + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_selectedStatus, _start, _end);
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? CupertinoColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

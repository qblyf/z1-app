import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/price_difference_api.dart';
import '../../models/price_difference.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 差异调整单列表页
class PriceDifferenceListPage extends ConsumerStatefulWidget {
  const PriceDifferenceListPage({super.key});

  @override
  ConsumerState<PriceDifferenceListPage> createState() => _PriceDifferenceListPageState();
}

class _PriceDifferenceListPageState extends ConsumerState<PriceDifferenceListPage> {
  List<PriceDifference> _list = [];
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
      final api = PriceDifferenceApi();
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
        if (refresh) _list = data; else _list.addAll(data);
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
      builder: (_) => _DiffFilterSheet(
        statusFilter: _statusFilter,
        onApply: (status) {
          setState(() => _statusFilter = status);
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
        middle: const Text('差异调整单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
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
                          Icon(CupertinoIcons.doc_text, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无差异调整单', style: AppText.caption),
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
                                (_, i) => _DiffCard(item: _list[i]),
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

class _DiffCard extends StatelessWidget {
  final PriceDifference item;

  const _DiffCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Text(item.number, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.status.label,
                  style: TextStyle(fontSize: 12, color: item.status.color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(item.departmentName ?? '部门${item.departmentID}', style: AppText.caption),
              const SizedBox(width: 12),
              Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(item.creatorName ?? '-', style: AppText.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(item.formattedCreatedAt, style: AppText.caption),
              const Spacer(),
              Text('${item.items.length} 个商品调价', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiffFilterSheet extends StatefulWidget {
  final int? statusFilter;
  final void Function(int?) onApply;

  const _DiffFilterSheet({required this.statusFilter, required this.onApply});

  @override
  State<_DiffFilterSheet> createState() => _DiffFilterSheetState();
}

class _DiffFilterSheetState extends State<_DiffFilterSheet> {
  late int _statusIndex;

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.statusFilter == null
        ? 0
        : PriceDifferenceStatus.values.indexWhere((s) => s.value == widget.statusFilter) + 1;
    if (_statusIndex < 0) _statusIndex = 0;
  }

  int? get _selectedStatus {
    if (_statusIndex == 0) return null;
    final allStatuses = [null, ...PriceDifferenceStatus.values];
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
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Chip(label: '全部', isActive: _statusIndex == 0, onTap: () => setState(() => _statusIndex = 0)),
              ...PriceDifferenceStatus.values.asMap().entries.map((e) =>
                _Chip(
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
              widget.onApply(_selectedStatus);
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isActive, required this.onTap});

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

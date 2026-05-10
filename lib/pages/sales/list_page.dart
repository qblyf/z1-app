import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/sales_api.dart';
import '../../models/sales.dart';
import '../../theme/app_theme.dart';

/// 销售查询列表页
class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  List<SalesOrder> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int _total = 0;

  int? _typeFilter; // null=全部, 1=销售, 2=退货, 3=换货
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
      final api = SalesApi();
      final minTime = _startDate.copyWith(hour: 0, minute: 0, second: 0);
      final maxTime = _endDate.copyWith(hour: 23, minute: 59, second: 59);

      List<int>? typeValues;
      if (_typeFilter != null) typeValues = [_typeFilter!];

      List<int>? statusValues;
      if (_statusFilter != null) statusValues = [_statusFilter!];

      final total = await api.count(statusValues: statusValues);
      final data = await api.list(
        typeValues: typeValues,
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
      builder: (_) => _SalesFilterSheet(
        typeFilter: _typeFilter,
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (type, status, start, end) {
          setState(() {
            _typeFilter = type;
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
        middle: const Text('销售查询'),
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
                          Icon(CupertinoIcons.money_dollar_circle, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无销售记录', style: AppText.caption),
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
                                (_, i) => _SalesCard(order: _list[i]),
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

class _SalesCard extends StatelessWidget {
  final SalesOrder order;

  const _SalesCard({required this.order});

  Color get _typeColor {
    switch (order.type) {
      case SalesType.sale: return const Color(0xFF30D158);
      case SalesType.refunds: return const Color(0xFFFF3B30);
      case SalesType.change: return const Color(0xFFBF5AF2);
    }
  }

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.type.label,
                  style: TextStyle(fontSize: 12, color: _typeColor, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.status.label,
                  style: TextStyle(fontSize: 12, color: order.status.color, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(
                '¥${order.totalAmountYuan.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF9500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(order.departmentName ?? '部门${order.departmentID}', style: AppText.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (order.memberName != null) ...[
                Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(order.memberName!, style: AppText.caption),
                const SizedBox(width: 12),
              ],
              Icon(CupertinoIcons.calendar, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(order.formattedCreatedAt, style: AppText.caption),
            ],
          ),
          if (order.products.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: order.products.take(3).map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${p.displayName} ×${p.quantity}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF))),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalesFilterSheet extends StatefulWidget {
  final int? typeFilter;
  final int? statusFilter;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(int?, int?, DateTime, DateTime) onApply;

  const _SalesFilterSheet({
    required this.typeFilter,
    required this.statusFilter,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_SalesFilterSheet> createState() => _SalesFilterSheetState();
}

class _SalesFilterSheetState extends State<_SalesFilterSheet> {
  late int _typeIndex;
  late int _statusIndex;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _typeIndex = widget.typeFilter == null ? 0 : SalesType.values.indexWhere((t) => t.value == widget.typeFilter) + 1;
    if (_typeIndex < 0) _typeIndex = 0;
    _statusIndex = widget.statusFilter == null ? 0 : SalesStatus.values.indexWhere((s) => s.value == widget.statusFilter) + 1;
    if (_statusIndex < 0) _statusIndex = 0;
    _start = widget.startDate;
    _end = widget.endDate;
  }

  int? get _selectedType {
    if (_typeIndex == 0) return null;
    final all = [null, ...SalesType.values];
    if (_typeIndex <= all.length) return all[_typeIndex]?.value;
    return null;
  }

  int? get _selectedStatus {
    if (_statusIndex == 0) return null;
    final all = [null, ...SalesStatus.values];
    if (_statusIndex <= all.length) return all[_statusIndex]?.value;
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
          Text('类型', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Chip(label: '全部', isActive: _typeIndex == 0, onTap: () => setState(() => _typeIndex = 0)),
              ...SalesType.values.asMap().entries.map((e) =>
                _Chip(label: e.value.label, isActive: _typeIndex == e.key + 1, onTap: () => setState(() => _typeIndex = e.key + 1)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('状态', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Chip(label: '全部', isActive: _statusIndex == 0, onTap: () => setState(() => _statusIndex = 0)),
              ...SalesStatus.values.asMap().entries.map((e) =>
                _Chip(label: e.value.label, isActive: _statusIndex == e.key + 1, onTap: () => setState(() => _statusIndex = e.key + 1)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_selectedType, _selectedStatus, _start, _end);
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

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/purchase_order_api.dart';
import '../../models/purchase_order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 采购订单列表页
class PurchaseOrderListPage extends ConsumerStatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  ConsumerState<PurchaseOrderListPage> createState() =>
      _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends ConsumerState<PurchaseOrderListPage> {
  List<PurchaseOrder> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int _total = 0;

  int? _statusFilter; // null=全部
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final api = PurchaseOrderApi();
      final minTime = _startDate.copyWith(hour: 0, minute: 0, second: 0);
      final maxTime = _endDate.copyWith(hour: 23, minute: 59, second: 59);

      List<int>? statusValues;
      if (_statusFilter != null) statusValues = [_statusFilter!];

      final total = await api.count(
        minCreatedAt: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: maxTime.millisecondsSinceEpoch ~/ 1000,
        statusValues: statusValues,
      );

      final data = await api.list(
        minCreatedAt: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: maxTime.millisecondsSinceEpoch ~/ 1000,
        statusValues: statusValues,
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
      builder: (_) => _PurchaseFilterSheet(
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
        middle: const Text('采购订单'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showFilterSheet,
              child: const Icon(CupertinoIcons.slider_horizontal_3),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/purchase-order/create'),
              child: const Icon(CupertinoIcons.plus),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
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
                          Icon(CupertinoIcons.cube_box,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无采购订单', style: AppText.caption),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification &&
                            n.metrics.extentAfter < 100 &&
                            _hasMore &&
                            !_isLoading) {
                          _loadData();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          CupertinoSliverRefreshControl(
                            onRefresh: () => _loadData(refresh: true),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _PurchaseOrderCard(
                                  order: _list[i],
                                  onTap: () => context.push(
                                    '/purchase-order/detail/${_list[i].purchaseOrderID}',
                                  ),
                                ),
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

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;

  const _PurchaseOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(order.status.colorValue);
    return GestureDetector(
      onTap: onTap,
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
            // 编号行
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.purchaseOrderNumber ?? 'NO.${order.purchaseOrderID}',
                    style:
                        AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 信息行
            Row(
              children: [
                Icon(CupertinoIcons.person,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(order.vendorName ?? '供应商${order.vendorID}',
                    style: AppText.caption),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(CupertinoIcons.building_2_fill,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(order.warehouseName ?? '仓库${order.warehouseID}',
                    style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.calendar,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(order.formattedCreatedAt, style: AppText.caption),
              ],
            ),
            if (order.products.isNotEmpty) ...[
              const SizedBox(height: 8),
              // 商品摘要
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: order.products.take(3).map((p) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${p.displayName} ×${p.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0A84FF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '共 ${order.products.length} 种商品',
                    style: AppText.caption,
                  ),
                ),
                Text(
                  '¥${order.totalAmountYuan.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFF9500),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

/// 采购订单筛选面板
class _PurchaseFilterSheet extends StatefulWidget {
  final int? statusFilter;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(int?, DateTime, DateTime) onApply;

  const _PurchaseFilterSheet({
    required this.statusFilter,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_PurchaseFilterSheet> createState() => _PurchaseFilterSheetState();
}

class _PurchaseFilterSheetState extends State<_PurchaseFilterSheet> {
  late int _statusIndex;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.statusFilter == null
        ? 0
        : PurchaseOrderStatus.values
            .indexWhere((s) => s.value == widget.statusFilter);
    if (_statusIndex < 0) _statusIndex = 0;
    _start = widget.startDate;
    _end = widget.endDate;
  }

  int? get _selectedStatus {
    if (_statusIndex == 0) return null;
    final statuses = [
      null,
      PurchaseOrderStatus.draft,
      PurchaseOrderStatus.pending,
      PurchaseOrderStatus.approved,
      PurchaseOrderStatus.rejected,
      PurchaseOrderStatus.finished,
    ];
    if (_statusIndex < statuses.length) return statuses[_statusIndex]?.value;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      '全部',
      '草稿',
      '待审核',
      '已审核',
      '已拒绝',
      '已完成',
    ];

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
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
              const Text('筛选',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill,
                    color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('状态', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusOptions.asMap().entries.map((e) {
              final isActive = _statusIndex == e.key;
              return GestureDetector(
                onTap: () => setState(() => _statusIndex = e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0A84FF)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive
                          ? CupertinoColors.white
                          : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: '开始日期',
                  date: _start,
                  onChanged: (d) => setState(() => _start = d),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(
                  label: '结束日期',
                  date: _end,
                  onChanged: (d) => setState(() => _end = d),
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: AppText.body,
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

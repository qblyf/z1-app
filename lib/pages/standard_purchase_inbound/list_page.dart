import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/standard_purchase_inbound_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 标品采购入库单列表页
/// 对应 PWA /pages/path-d/standard-purchase-inbound/order-list.tsx
class StandardPurchaseInboundListPage extends ConsumerStatefulWidget {
  const StandardPurchaseInboundListPage({super.key});

  @override
  ConsumerState<StandardPurchaseInboundListPage> createState() =>
      _StandardPurchaseInboundListPageState();
}

class _StandardPurchaseInboundListPageState
    extends ConsumerState<StandardPurchaseInboundListPage> {
  final StandardPurchaseInboundApi _api = StandardPurchaseInboundApi();

  List<PurchaseInbound> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int _total = 0;
  int _totalCount = 0;
  String _totalAmount = '';

  // 筛选条件
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int? _statusFilter;
  String? _purchaseOrderNumber;
  String? _inboundOrderNumber;

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
      final minTime = _startDate.copyWith(hour: 0, minute: 0, second: 0);
      final maxTime = _endDate.copyWith(hour: 23, minute: 59, second: 59);

      List<int>? stateValues;
      if (_statusFilter != null) stateValues = [_statusFilter!];

      List<String>? numbers;
      if (_inboundOrderNumber != null && _inboundOrderNumber!.isNotEmpty) {
        numbers = [_inboundOrderNumber!];
      }

      List<String>? purchaseNumbers;
      if (_purchaseOrderNumber != null && _purchaseOrderNumber!.isNotEmpty) {
        purchaseNumbers = [_purchaseOrderNumber!];
      }

      final countResult = await _api.count(
        minCreatedAt: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: maxTime.millisecondsSinceEpoch ~/ 1000,
        vendorIDs: null,
      );

      final data = await _api.list(
        minCreatedAt: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: maxTime.millisecondsSinceEpoch ~/ 1000,
        numbers: numbers,
        purchaseOrderNumbers: purchaseNumbers,
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
        _total = countResult.count;
        _totalCount = countResult.totalCount;
        _totalAmount = countResult.formattedTotalAmount;
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
      builder: (_) => _FilterSheet(
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
        purchaseOrderNumber: _purchaseOrderNumber,
        inboundOrderNumber: _inboundOrderNumber,
        onApply: (status, start, end, poNum, inboundNum) {
          setState(() {
            _statusFilter = status;
            _startDate = start;
            _endDate = end;
            _purchaseOrderNumber = poNum;
            _inboundOrderNumber = inboundNum;
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
        middle: const Text('采购入库单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 统计栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Text('共 $_total 条', style: AppText.caption),
                  const SizedBox(width: 16),
                  Text('$_totalCount 件', style: AppText.caption),
                  const SizedBox(width: 16),
                  Text(_totalAmount, style: AppText.caption.copyWith(color: const Color(0xFFFF9500))),
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
                          Text('暂无采购入库单', style: AppText.caption),
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
                                (context, i) => _PurchaseInboundCard(
                                  item: _list[i],
                                  onTap: () => context.push('/standard-purchase-inbound/detail/${_list[i].purchaseID}'),
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

class _PurchaseInboundCard extends StatelessWidget {
  final PurchaseInbound item;
  final VoidCallback onTap;

  const _PurchaseInboundCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = PurchaseInboundState.fromValue(item.state);
    final stateColor = _getStateColor(state);

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.number ?? 'NO.${item.purchaseID}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(state.label, style: TextStyle(fontSize: 12, color: stateColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.calendar, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.formattedCreatedAt, style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.warehouseName ?? '仓库${item.warehouseID}',
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.vendorName ?? '往来单位${item.vendorID}', style: AppText.caption),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.purchaseOrderNumber != null) ...[
                  Icon(CupertinoIcons.doc_text, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('采购单: ${item.purchaseOrderNumber}', style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(width: 12),
                ],
                Text('共 ${item.totalQuantity} 件', style: AppText.caption),
                const Spacer(),
                Text(item.formattedAmount, style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFFF9500))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(PurchaseInboundState state) {
    switch (state) {
      case PurchaseInboundState.normal:
        return const Color(0xFF30D158);
      case PurchaseInboundState.draft:
        return const Color(0xFF8E8E93);
      case PurchaseInboundState.undetermined:
        return const Color(0xFFFF9500);
    }
  }
}

class _FilterSheet extends StatefulWidget {
  final int? statusFilter;
  final DateTime startDate;
  final DateTime endDate;
  final String? purchaseOrderNumber;
  final String? inboundOrderNumber;
  final void Function(int?, DateTime, DateTime, String?, String?) onApply;

  const _FilterSheet({
    required this.statusFilter,
    required this.startDate,
    required this.endDate,
    required this.purchaseOrderNumber,
    required this.inboundOrderNumber,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _statusIndex;
  late DateTime _start;
  late DateTime _end;
  late TextEditingController _poController;
  late TextEditingController _inboundController;

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.statusFilter == null ? 0 :
        PurchaseInboundState.values.indexWhere((s) => s.value == widget.statusFilter) + 1;
    if (_statusIndex < 0) _statusIndex = 0;
    _start = widget.startDate;
    _end = widget.endDate;
    _poController = TextEditingController(text: widget.purchaseOrderNumber);
    _inboundController = TextEditingController(text: widget.inboundOrderNumber);
  }

  int? get _selectedStatus {
    if (_statusIndex == 0) return null;
    final all = [null, ...PurchaseInboundState.values];
    if (_statusIndex < all.length) return all[_statusIndex]?.value;
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
              ...PurchaseInboundState.values.asMap().entries.map((e) =>
                _StatusChip(label: e.value.label, isActive: _statusIndex == e.key + 1,
                  onTap: () => setState(() => _statusIndex = e.key + 1)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('采购订单号', style: AppText.label),
          const SizedBox(height: 8),
          CupertinoTextField(controller: _poController, placeholder: '请输入采购订单号'),
          const SizedBox(height: AppSpacing.md),
          Text('入库单号', style: AppText.label),
          const SizedBox(height: 8),
          CupertinoTextField(controller: _inboundController, placeholder: '请输入入库单号'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DateField(label: '开始日期', date: _start, onChanged: (d) => setState(() => _start = d)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(label: '结束日期', date: _end, onChanged: (d) => setState(() => _end = d)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(
                _selectedStatus, _start, _end,
                _poController.text.isNotEmpty ? _poController.text : null,
                _inboundController.text.isNotEmpty ? _inboundController.text : null,
              );
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
        child: Text(label, style: TextStyle(
          fontSize: 14,
          color: isActive ? CupertinoColors.white : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        )),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateField({required this.label, required this.date, required this.onChanged});

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
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
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

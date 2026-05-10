import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../api/warehouse_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 盘库记录列表页（盘库结果查询）
/// 对应 PWA /pages/path-d/stocktaking-log-list.tsx
class StocktakingLogListPage extends ConsumerStatefulWidget {
  const StocktakingLogListPage({super.key});

  @override
  ConsumerState<StocktakingLogListPage> createState() => _StocktakingLogListPageState();
}

class _StocktakingLogListPageState extends ConsumerState<StocktakingLogListPage> {
  final StocktakingApi _api = StocktakingApi();
  final WarehouseApi _warehouseApi = WarehouseApi();

  // 筛选条件
  List<int> _selectedWarehouseIds = [];
  List<int> _selectedPlanIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  StocktakingRecordState _selectedState = StocktakingRecordState.completed;

  // 数据
  List<Stocktaking> _records = [];
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;

  // 下拉选项数据
  List<WarehouseInfo> _warehouses = [];
  List<StocktakingPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    // 默认时间范围：最近30天
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30));
  }

  Future<void> _loadFilterOptions() async {
    try {
      final results = await Future.wait([
        _warehouseApi.getManagerWarehouses(),
        _api.planList(states: [StocktakingPlanState.available.value]),
      ]);
      if (mounted) {
        setState(() {
          _warehouses = results[0] as List<WarehouseInfo>;
          _plans = results[1] as List<StocktakingPlan>;
        });
      }
    } catch (_) {}
  }

  Future<void> _search() async {
    if (_startDate == null || _endDate == null) {
      _showToast('请选择开始日期和结束日期');
      return;
    }
    if (_startDate!.isAfter(_endDate!)) {
      _showToast('开始日期不能晚于结束日期');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _records = [];
    });

    try {
      final results = await Future.wait([
        _api.stocktakingLogList(
          states: [_selectedState.value],
          warehouseIDs: _selectedWarehouseIds.isNotEmpty ? _selectedWarehouseIds : null,
          planIDs: _selectedPlanIds.isNotEmpty ? _selectedPlanIds : null,
          minCreatedAt: _startDate!.toUtc().millisecondsSinceEpoch ~/ 1000,
          maxCreatedAt: _endDate!.add(const Duration(days: 1)).toUtc().millisecondsSinceEpoch ~/ 1000 - 1,
          limit: 20,
          offset: 0,
        ),
        _api.stocktakingLogCount(
          states: [_selectedState.value],
          warehouseIDs: _selectedWarehouseIds.isNotEmpty ? _selectedWarehouseIds : null,
          planIDs: _selectedPlanIds.isNotEmpty ? _selectedPlanIds : null,
          minCreatedAt: _startDate!.toUtc().millisecondsSinceEpoch ~/ 1000,
          maxCreatedAt: _endDate!.add(const Duration(days: 1)).toUtc().millisecondsSinceEpoch ~/ 1000 - 1,
        ),
      ]);

      if (mounted) {
        final list = results[0] as List<Stocktaking>;
        // 按盘盈数量倒序
        list.sort((a, b) => (b.outOfStockQuantity ?? 0).compareTo(a.outOfStockQuantity ?? 0));
        setState(() {
          _records = list;
          _total = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _records.length >= _total) return;

    setState(() => _isLoadingMore = true);
    try {
      final list = await _api.stocktakingLogList(
        states: [_selectedState.value],
        warehouseIDs: _selectedWarehouseIds.isNotEmpty ? _selectedWarehouseIds : null,
        planIDs: _selectedPlanIds.isNotEmpty ? _selectedPlanIds : null,
        minCreatedAt: _startDate!.toUtc().millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: _endDate!.add(const Duration(days: 1)).toUtc().millisecondsSinceEpoch ~/ 1000 - 1,
        limit: 20,
        offset: _records.length,
      );

      if (mounted) {
        list.sort((a, b) => (b.outOfStockQuantity ?? 0).compareTo(a.outOfStockQuantity ?? 0));
        setState(() {
          _records.addAll(list);
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('盘库结果查询'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 筛选表单
            _buildFilterForm(),
            // 结果列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : !_hasSearched
                      ? Center(child: Text('请点击"查询"按钮搜索', style: AppText.body))
                      : _records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.cube_box, size: 64, color: AppColors.textTertiary),
                                  const SizedBox(height: 12),
                                  Text('未找到盘库记录', style: AppText.body),
                                ],
                              ),
                            )
                          : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterForm() {
    return Container(
      color: CupertinoColors.white,
      child: Column(
        children: [
          // 仓库选择
          _FilterRow(
            label: '仓库选择',
            subLabel: '(可多选)',
            value: _selectedWarehouseIds.isEmpty
                ? '请选择仓库'
                : _warehouses
                    .where((w) => _selectedWarehouseIds.contains(w.id))
                    .map((w) => w.name ?? '仓库${w.id}')
                    .join('、'),
            onTap: _showWarehousePicker,
          ),
          _Divider(),
          // 方案选择
          _FilterRow(
            label: '方案选择',
            subLabel: '(可多选)',
            value: _selectedPlanIds.isEmpty
                ? '请选择方案'
                : _plans
                    .where((p) => _selectedPlanIds.contains(p.id))
                    .map((p) => p.title)
                    .join('、'),
            onTap: _showPlanPicker,
          ),
          _Divider(),
          // 日期范围
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text('日期范围', style: TextStyle(fontSize: 14, color: Color(0xFF2A2A2A))),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _DatePickerButton(date: _startDate, hint: '开始日期', onTap: () => _showDatePicker(true))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('至', style: TextStyle(color: Color(0xFF636366))),
                      ),
                      Expanded(child: _DatePickerButton(date: _endDate, hint: '结束日期', onTap: () => _showDatePicker(false))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Divider(),
          // 状态选择
          _FilterRow(
            label: '状态',
            value: '',
            trailing: CupertinoSlidingSegmentedControl<StocktakingRecordState>(
              groupValue: _selectedState,
              children: const {
                StocktakingRecordState.inProgress: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('进行中', style: TextStyle(fontSize: 13)),
                ),
                StocktakingRecordState.completed: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('已完成', style: TextStyle(fontSize: 13)),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _selectedState = v);
              },
            ),
          ),
          _Divider(),
          // 查询按钮
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _isLoading ? null : _search,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('查询'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        if (_hasSearched)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: Row(
              children: [
                Text(
                  '共 $_total 条记录',
                  style: AppText.caption.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _records.length + (_records.length < _total ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= _records.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CupertinoButton(
                    onPressed: _isLoadingMore ? null : _loadMore,
                    child: _isLoadingMore
                        ? const CupertinoActivityIndicator()
                        : Text('点击查看更多', style: AppText.body.copyWith(color: AppColors.primary)),
                  ),
                );
              }
              return _StocktakingLogCard(
                record: _records[i],
                onTap: () {
                  if (_records[i].isInProgress) {
                    context.push('/stocktaking/take/${_records[i].id}');
                  } else {
                    context.push('/stocktaking/info/${_records[i].id}');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showWarehousePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _MultiSelectSheet<WarehouseInfo>(
        title: '选择仓库',
        items: _warehouses,
        selectedIds: _selectedWarehouseIds,
        itemLabel: (w) => w.name ?? '仓库${w.id}',
        itemId: (w) => w.id,
        onConfirm: (ids) => setState(() => _selectedWarehouseIds = ids),
      ),
    );
  }

  void _showPlanPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _MultiSelectSheet<StocktakingPlan>(
        title: '选择方案',
        items: _plans,
        selectedIds: _selectedPlanIds,
        itemLabel: (p) => p.title,
        itemId: (p) => p.id,
        onConfirm: (ids) => setState(() => _selectedPlanIds = ids),
      ),
    );
  }

  void _showDatePicker(bool isStart) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('确认'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (dt) {
                  setState(() {
                    if (isStart) {
                      _startDate = dt;
                    } else {
                      _endDate = dt;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final String? subLabel;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _FilterRow({
    required this.label,
    this.subLabel,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2A2A2A))),
                  if (subLabel != null)
                    Text(subLabel!, style: const TextStyle(fontSize: 10, color: Color(0xFF636366))),
                ],
              ),
            ),
            Expanded(
              child: trailing ??
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.startsWith('请') ? const Color(0xFF8E8E93) : const Color(0xFF2A2A2A),
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
            if (trailing == null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: AppSpacing.md),
      color: const Color(0xFFDDDDE0),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  const _DatePickerButton({required this.date, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                    : hint,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null ? const Color(0xFF2A2A2A) : const Color(0xFF8E8E93),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Icon(CupertinoIcons.calendar, size: 14, color: Color(0xFF636366)),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<int> selectedIds;
  final String Function(T) itemLabel;
  final int Function(T) itemId;
  final void Function(List<int>) onConfirm;

  const _MultiSelectSheet({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.itemLabel,
    required this.itemId,
    required this.onConfirm,
  });

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late List<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('确定'),
                  onPressed: () {
                    widget.onConfirm(_selected);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (_, i) {
                final item = widget.items[i];
                final id = widget.itemId(item);
                final isSelected = _selected.contains(id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(id);
                      } else {
                        _selected.add(id);
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(widget.itemLabel(item), style: const TextStyle(fontSize: 15)),
                        ),
                        Icon(
                          isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                          color: isSelected ? AppColors.primary : const Color(0xFFC7C7CC),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StocktakingLogCard extends StatelessWidget {
  final Stocktaking record;
  final VoidCallback onTap;

  const _StocktakingLogCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.clock, size: 14, color: Color(0xFF636366)),
                  const SizedBox(width: 6),
                  Text('盘库时间', style: AppText.caption.copyWith(color: const Color(0xFF636366))),
                  const SizedBox(width: 8),
                  Text(record.formattedCreatedAt.split(' ')[0], style: AppText.body),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: record.state.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.state.label,
                      style: TextStyle(fontSize: 12, color: record.state.color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // 分隔线
            Container(height: 0.5, color: const Color(0xFFDDDDE0)),
            // 内容
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          record.warehouseName ?? '仓库${record.warehouseID}',
                          style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '盘库人: ${record.creatorName ?? record.createdBy}',
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatBadge(label: '库存', value: '${record.dueQuantity}', color: const Color(0xFF636366)),
                      const SizedBox(width: 8),
                      _StatBadge(label: '实际', value: '${record.actualQuantity}', color: const Color(0xFF30D158)),
                      if (record.transferLockStockQuantity > 0) ...[
                        const SizedBox(width: 8),
                        _StatBadge(label: '调拨在途', value: '${record.transferLockStockQuantity}', color: const Color(0xFF5856D6)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatBadge(label: '盘亏', value: '${record.computedOutOfStockQuantity}', color: const Color(0xFFFF3B30)),
                      const SizedBox(width: 8),
                      _StatBadge(label: '盘盈', value: '${record.extraQuantity}', color: const Color(0xFF30D158)),
                    ],
                  ),
                ],
              ),
            ),
            // 操作按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFDDDDE0), width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      record.isInProgress ? '补充盘库' : '查看详情',
                      style: const TextStyle(fontSize: 12, color: CupertinoColors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
          Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../api/warehouse_api.dart';
import '../../models/stocktaking.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 盘库交接单页（库管交接班）
/// 对应 PWA /pages/path-d/stocktaking-delivery-receipt.tsx
class StocktakingDeliveryReceiptPage extends ConsumerStatefulWidget {
  const StocktakingDeliveryReceiptPage({super.key});

  @override
  ConsumerState<StocktakingDeliveryReceiptPage> createState() => _StocktakingDeliveryReceiptPageState();
}

class _StocktakingDeliveryReceiptPageState extends ConsumerState<StocktakingDeliveryReceiptPage> {
  final StocktakingApi _api = StocktakingApi();

  List<UserStocktakingOnDuty> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getUserOnDutyList();
      if (mounted) {
        // Filter out 已完成(complete) records, sort: pending first
        final filtered = list.where((r) => r.status != StocktakingOnDutyStatus.complete).toList();
        filtered.sort((a, b) {
          if (a.status == StocktakingOnDutyStatus.pending && b.status != StocktakingOnDutyStatus.pending) return -1;
          if (b.status == StocktakingOnDutyStatus.pending && a.status != StocktakingOnDutyStatus.pending) return 1;
          return 0;
        });
        setState(() {
          _records = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
        middle: const Text('库管交接单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loadData,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 操作按钮栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: '认领',
                      color: const Color(0xFF30D158),
                      icon: CupertinoIcons.hand_raised,
                      onTap: () => _showOperationSheet('claim'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: '交班',
                      color: const Color(0xFF0A84FF),
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      onTap: () => _showOperationSheet('handover'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: '指定',
                      color: const Color(0xFF5856D6),
                      icon: CupertinoIcons.person_badge_plus,
                      onTap: () => _showOperationSheet('assign'),
                    ),
                  ),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.tray, size: 64, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('暂无交接记录', style: AppText.body),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            CupertinoSliverRefreshControl(onRefresh: _loadData),
                            SliverPadding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _DutyCard(
                                    record: _records[i],
                                    onReceive: () => _receive(_records[i]),
                                    onRefuse: () => _showRefuseDialog(_records[i]),
                                  ),
                                  childCount: _records.length,
                                ),
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

  void _showOperationSheet(String type) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _OperationSheet(
        api: _api,
        type: type,
        warehouseApi: WarehouseApi(),
        onComplete: () {
          Navigator.pop(ctx);
          _loadData();
        },
        onError: _showToast,
      ),
    );
  }

  Future<void> _receive(UserStocktakingOnDuty record) async {
    try {
      await _api.onDutyReceive(id: record.id);
      _showToast('已确认接班');
      _loadData();
    } catch (_) {
      _showToast('操作失败');
    }
  }

  void _showRefuseDialog(UserStocktakingOnDuty record) {
    final textController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('拒绝接班'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text('请输入拒绝原因（选填）'),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: textController,
              placeholder: '拒绝原因',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.onDutyRefuse(id: record.id, remarks: textController.text);
                _showToast('已拒绝');
                _loadData();
              } catch (_) {
                _showToast('操作失败');
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: CupertinoColors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DutyCard extends StatelessWidget {
  final UserStocktakingOnDuty record;
  final VoidCallback onReceive;
  final VoidCallback onRefuse;

  const _DutyCard({
    required this.record,
    required this.onReceive,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 状态头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            color: record.status.color.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: record.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: record.status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow('仓库', '仓库${record.warehouseID}'),
                    ),
                    Expanded(
                      child: _InfoRow('方案', '方案${record.planID}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow('交班库管', record.preManager?.toString() ?? '无'),
                    ),
                    Expanded(
                      child: _InfoRow('接班库管', record.newManager?.toString() ?? '无'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  record.status == StocktakingOnDutyStatus.refused
                      ? '拒绝时间'
                      : record.status == StocktakingOnDutyStatus.pending
                          ? '交接时间'
                          : '确认时间',
                  _formatTime(record.at),
                ),
                if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow('备注', record.remarks!),
                ],
              ],
            ),
          ),
          // 操作按钮（待确认状态显示）
          if (record.status == StocktakingOnDutyStatus.pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFDDDDE0), width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: onRefuse,
                      child: const Text(
                        '拒绝接班',
                        style: TextStyle(color: Color(0xFFFF3B30), fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: onReceive,
                      child: const Text(
                        '确认接班',
                        style: TextStyle(color: Color(0xFF0A84FF), fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String get _statusText {
    switch (record.status) {
      case StocktakingOnDutyStatus.pending:
        return '待确认';
      case StocktakingOnDutyStatus.inUse:
        return '在用已确认';
      case StocktakingOnDutyStatus.complete:
        return '已完成';
      case StocktakingOnDutyStatus.refused:
        return '已拒绝';
    }
  }

  String _formatTime(int ts) {
    if (ts == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text('$label:', style: AppText.caption.copyWith(color: AppColors.textTertiary)),
        ),
        Expanded(
          child: Text(value, style: AppText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// 操作表单弹窗（认领/交班/指定）
class _OperationSheet extends ConsumerStatefulWidget {
  final StocktakingApi api;
  final String type; // claim | handover | assign
  final WarehouseApi warehouseApi;
  final VoidCallback onComplete;
  final void Function(String) onError;

  const _OperationSheet({
    required this.api,
    required this.type,
    required this.warehouseApi,
    required this.onComplete,
    required this.onError,
  });

  @override
  ConsumerState<_OperationSheet> createState() => _OperationSheetState();
}

class _OperationSheetState extends ConsumerState<_OperationSheet> {
  List<WarehouseInfo> _warehouses = [];
  List<StocktakingPlan> _plans = [];
  List<UserStocktakingOnDuty> _myDuties = [];
  WarehouseInfo? _selectedWarehouse;
  StocktakingPlan? _selectedPlan;
  int? _selectedNewManager;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.warehouseApi.getManagerWarehouses(),
        widget.api.planList(states: [StocktakingPlanState.available.value]),
        widget.api.getUserOnDutyList(),
      ]);
      if (mounted) {
        setState(() {
          _warehouses = results[0] as List<WarehouseInfo>;
          _plans = results[1] as List<StocktakingPlan>;
          _myDuties = results[2] as List<UserStocktakingOnDuty>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _title {
    switch (widget.type) {
      case 'claim':
        return '认领盘库';
      case 'handover':
        return '交班';
      case 'assign':
        return '指定接班';
      default:
        return '操作';
    }
  }

  /// 认领时：只能选择我未负责的方案
  List<StocktakingPlan> get _availablePlans {
    if (widget.type == 'claim') {
      final myPlanIds = _myDuties
          .where((d) => d.status == StocktakingOnDutyStatus.inUse)
          .map((d) => d.planID)
          .toSet();
      return _plans.where((p) => !myPlanIds.contains(p.id)).toList();
    }
    if (widget.type == 'handover') {
      final myPlanIds = _myDuties
          .where((d) => d.status == StocktakingOnDutyStatus.inUse)
          .map((d) => d.planID)
          .toSet();
      return _plans.where((p) => myPlanIds.contains(p.id)).toList();
    }
    return _plans;
  }

  Future<void> _submit() async {
    if (_selectedWarehouse == null) {
      widget.onError('请选择仓库');
      return;
    }
    if (_selectedPlan == null) {
      widget.onError('请选择方案');
      return;
    }
    if (widget.type != 'claim' && _selectedNewManager == null) {
      widget.onError('请选择接班库管');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (widget.type == 'claim') {
        await widget.api.onDutyClaim(
          warehouseID: _selectedWarehouse!.id,
          planID: _selectedPlan!.id,
        );
      } else if (widget.type == 'handover') {
        await widget.api.onDutyHandover(
          warehouseID: _selectedWarehouse!.id,
          planID: _selectedPlan!.id,
          newManager: _selectedNewManager!,
        );
      } else {
        await widget.api.onDutyDistribution(
          warehouseID: _selectedWarehouse!.id,
          planID: _selectedPlan!.id,
          newManager: _selectedNewManager!,
        );
      }
      widget.onComplete();
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onError('操作失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 头部
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
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator()
                      : const Text('确定'),
                ),
              ],
            ),
          ),
          // 表单
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // 仓库选择
                      _SelectRow(
                        label: '仓库',
                        value: _selectedWarehouse?.name ?? '请选择仓库',
                        onTap: () => _showWarehousePicker(),
                      ),
                      const SizedBox(height: 12),
                      // 方案选择
                      _SelectRow(
                        label: '方案',
                        value: _selectedPlan?.title ?? '请选择方案',
                        onTap: () => _showPlanPicker(),
                      ),
                      if (widget.type != 'claim') ...[
                        const SizedBox(height: 12),
                        _SelectRow(
                          label: '接班库管',
                          value: _selectedNewManager != null ? '$_selectedNewManager' : '请选择库管',
                          onTap: () => _showEmployeePicker(),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showWarehousePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
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
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (i) {
                  setState(() => _selectedWarehouse = _warehouses[i]);
                },
                children: _warehouses.map((w) => Center(child: Text(w.name ?? '仓库${w.id}'))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
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
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (i) {
                  setState(() => _selectedPlan = _availablePlans[i]);
                },
                children: _availablePlans.map((p) => Center(child: Text(p.title))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeePicker() {
    // 简单的数字ID选择（实际应从员工列表选择）
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('选择接班库管'),
        content: const Text('请输入接班库管工号'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SelectRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label, style: AppText.body),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: value.startsWith('请') ? const Color(0xFF8E8E93) : const Color(0xFF2A2A2A),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

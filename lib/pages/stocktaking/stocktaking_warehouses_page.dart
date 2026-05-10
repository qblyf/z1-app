import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../api/warehouse_api.dart';
import '../../models/stocktaking.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 盘库-仓库选择页
/// 对应 PWA /pages/path-d/stocktaking-warehouses.tsx
class StocktakingWarehousesPage extends ConsumerStatefulWidget {
  final int planId;

  const StocktakingWarehousesPage({super.key, required this.planId});

  @override
  ConsumerState<StocktakingWarehousesPage> createState() => _StocktakingWarehousesPageState();
}

class _StocktakingWarehousesPageState extends ConsumerState<StocktakingWarehousesPage> {
  final StocktakingApi _stocktakingApi = StocktakingApi();
  final WarehouseApi _warehouseApi = WarehouseApi();
  final TextEditingController _remarkController = TextEditingController();

  List<WarehouseInfo> _warehouses = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 获取当前用户管理的仓库
      final managerWarehouses = await _warehouseApi.getManagerWarehouses();
      if (managerWarehouses.isEmpty) {
        if (mounted) {
          _showToast('当前用户还不是仓库管理员');
        }
      }
      if (mounted) {
        setState(() {
          _warehouses = managerWarehouses;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<WarehouseInfo> get _filteredWarehouses {
    if (_searchText.isEmpty) return _warehouses;
    final t = _searchText.toLowerCase();
    return _warehouses.where((w) {
      final num = (w.number ?? '').toLowerCase();
      final name = (w.name ?? '').toLowerCase();
      final spell = (w.spell ?? '').toLowerCase();
      return num.contains(t) || name.contains(t) || spell.contains(t);
    }).toList();
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

  /// 显示备注输入弹窗，返回用户输入的备注（或 null 如果取消）
  Future<String?> _showRemarkDialog() async {
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('添加备注'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: _remarkController,
            placeholder: '请输入备注（选填）',
            maxLines: 3,
            minLines: 2,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, _remarkController.text),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _handleWarehouseTap(WarehouseInfo warehouse) async {
    // 查询该仓库+该方案的最近盘库记录
    final records = await _stocktakingApi.dashboardList(
      states: [StocktakingRecordState.inProgress.value, StocktakingRecordState.completed.value],
      warehouseIDs: [warehouse.id],
      planIDs: [widget.planId],
    );

    if (!mounted) return;

    if (records.isEmpty) {
      // 无记录，仅显示"开始盘库"
      _showActionSheet(warehouse, hasInProgress: false, hasCompleted: false);
    } else if (records.length == 1) {
      final record = records.first;
      if (record.isInProgress) {
        // 进行中，仅显示"补充盘库"
        _showActionSheet(warehouse, hasInProgress: true, hasCompleted: false, recordId: record.id);
      } else {
        // 已完成，显示"开始盘库"和"补充盘库"
        _showActionSheet(warehouse, hasInProgress: false, hasCompleted: true, recordId: record.id);
      }
    } else {
      // 多条记录，找进行中的
      final inProgress = records.where((r) => r.isInProgress).toList();
      if (inProgress.isNotEmpty) {
        _showActionSheet(warehouse, hasInProgress: true, hasCompleted: true, recordId: inProgress.first.id);
      } else {
        _showActionSheet(warehouse, hasInProgress: false, hasCompleted: true, recordId: records.first.id);
      }
    }
  }

  void _showActionSheet(WarehouseInfo warehouse, {
    required bool hasInProgress,
    required bool hasCompleted,
    int? recordId,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(warehouse.displayName),
        message: const Text('请选择操作'),
        actions: [
          if (hasInProgress && recordId != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToStocktake(recordId);
              },
              child: const Text('补充盘库'),
            ),
          if (hasCompleted)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                _remarkController.clear();
                final remark = await _showRemarkDialog();
                if (remark == null) return; // 用户取消
                await _startNewStocktaking(warehouse, remark: remark);
              },
              child: const Text('开始盘库'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _startNewStocktaking(WarehouseInfo warehouse, {String? remark}) async {
    try {
      // 格式化备注：添加时间 + 操作人 + 内容
      String? formattedRemark;
      if (remark != null && remark.isNotEmpty) {
        final userAsync = ref.read(currentUserProvider);
        final userName = userAsync.value?.realName ?? '';
        final now = DateTime.now();
        final timeStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        formattedRemark = '添加时间:$timeStr; 操作人:$userName; 内容:$remark; \n';
      }

      final id = await _stocktakingApi.addStocktaking(
        planID: widget.planId,
        warehouseID: warehouse.id,
        remarks: formattedRemark,
      );
      if (mounted) {
        if (id > 0) {
          context.push('/stocktaking/take/$id');
        } else {
          _showToast('创建盘库记录失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('创建盘库记录失败');
      }
    }
  }

  void _navigateToStocktake(int recordId) {
    context.push('/stocktaking/take/$recordId');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('选择仓库'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: CupertinoSearchTextField(
                placeholder: '搜索仓库编号/名称/拼音',
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
            // 仓库列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _filteredWarehouses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.building_2_fill, size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 8),
                              Text(
                                _warehouses.isEmpty ? '当前用户还不是仓库管理员' : '未找到匹配的仓库',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _filteredWarehouses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => _WarehouseCard(
                            warehouse: _filteredWarehouses[i],
                            onTap: _handleWarehouseTap,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final WarehouseInfo warehouse;
  final void Function(WarehouseInfo) onTap;

  const _WarehouseCard({required this.warehouse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(warehouse),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.building_2_fill, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.displayName,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (warehouse.address != null) ...[
                    const SizedBox(height: 2),
                    Text(warehouse.address!, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (warehouse.principalName != null) ...[
                    const SizedBox(height: 2),
                    Text('负责人: ${warehouse.principalName}', style: AppText.caption),
                  ],
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 18, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

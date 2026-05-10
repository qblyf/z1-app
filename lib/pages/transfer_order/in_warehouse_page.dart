import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/warehouse_api.dart';
import '../../api/transfer_order_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// 调拨入库页
/// 对应 PWA /pages/path-d/transfer-order/in-warehouse.tsx
class TransferInWarehousePage extends ConsumerStatefulWidget {
  /// 调拨单ID（从二维码扫码参数传入）
  final int? transferId;

  const TransferInWarehousePage({super.key, this.transferId});

  @override
  ConsumerState<TransferInWarehousePage> createState() =>
      _TransferInWarehousePageState();
}

class _TransferInWarehousePageState
    extends ConsumerState<TransferInWarehousePage> {
  final WarehouseApi _warehouseApi = WarehouseApi();
  final TransferOrderApi _transferApi = TransferOrderApi();

  List<WarehouseInfo> _availableWarehouses = [];
  WarehouseInfo? _selectedWarehouse;
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _warehouseApi.getManagerWarehouses();
      setState(() {
        _availableWarehouses = warehouses;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirm() async {
    if (widget.transferId == null) {
      _showToast('未获取到调拨单参数');
      return;
    }
    if (_selectedWarehouse == null) {
      _showToast('请选择入库仓库');
      return;
    }

    setState(() => _isConfirming = true);
    try {
      final ok = await _transferApi.audit(
        widget.transferId!,
        inWarehouseID: _selectedWarehouse!.id,
      );
      if (ok) {
        _showToast('操作成功！');
        // 跳转到调拨单详情
        if (mounted) {
          context.push('/transfer-order/detail/${widget.transferId}');
        }
      } else {
        _showToast('操作失败');
      }
    } catch (e) {
      _showToast('操作失败：$e');
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showWarehousePicker() {
    if (_availableWarehouses.isEmpty) return;

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
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedWarehouse = _availableWarehouses[index];
                  });
                },
                children: _availableWarehouses
                    .map((w) => Center(child: Text(w.displayName)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTransferId = widget.transferId != null;

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
        child: hasTransferId
            ? _buildContent()
            : _buildNoParamView(),
      ),
    );
  }

  Widget _buildNoParamView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle,
              size: 64, color: CupertinoColors.systemGrey),
          const SizedBox(height: 16),
          Text('未获取到调拨单参数', style: AppText.body),
          const SizedBox(height: 8),
          Text(
            '请通过调拨出库页面扫描二维码进入',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _availableWarehouses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.building_2_fill,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('当前用户还不是仓库管理员', style: AppText.body),
                        ],
                      ),
                    )
                  : _buildWarehouseList(),
        ),
        // 底部确认按钮
        if (_availableWarehouses.isNotEmpty)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _isConfirming ? null : _confirm,
              child: _isConfirming
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('保存并下一步'),
            ),
          ),
      ],
    );
  }

  Widget _buildWarehouseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _availableWarehouses.length,
      itemBuilder: (context, index) {
        final warehouse = _availableWarehouses[index];
        final isSelected = _selectedWarehouse?.id == warehouse.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedWarehouse = isSelected ? null : warehouse;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.building_2_fill,
                    color: isSelected ? AppColors.primary : CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.displayName,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                      if (warehouse.address != null)
                        Text(warehouse.address!, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

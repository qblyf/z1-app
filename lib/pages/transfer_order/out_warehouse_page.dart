import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/warehouse_api.dart';
import '../../api/transfer_order_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 调拨出库页
/// 对应 PWA /pages/path-d/transfer-order/out-warehouse.tsx
class TransferOutWarehousePage extends ConsumerStatefulWidget {
  const TransferOutWarehousePage({super.key});

  @override
  ConsumerState<TransferOutWarehousePage> createState() =>
      _TransferOutWarehousePageState();
}

class _TransferOutWarehousePageState
    extends ConsumerState<TransferOutWarehousePage> {
  final WarehouseApi _warehouseApi = WarehouseApi();
  final TransferOrderApi _transferApi = TransferOrderApi();

  // 出库仓库
  WarehouseInfo? _selectedWarehouse;
  List<WarehouseInfo> _availableWarehouses = [];
  bool _warehouseLoading = true;

  // 商品列表
  final List<_ScannedProduct> _productList = [];
  final TextEditingController _searchController = TextEditingController();

  // 创建结果
  int? _createdTransferId;
  Map<String, dynamic>? _createdTransferDetail;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _warehouseLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      final deptId = user?.deptId ?? 0;

      // 获取当前用户是库管的仓库
      final warehouses = await _warehouseApi.getManagerWarehouses();

      // 如果用户有部门，获取该部门对应的仓库
      if (deptId > 0) {
        final deptWarehouseIds = await _warehouseApi.getWarehouseIdsByMainDeptId(deptId);
        // 优先显示当前部门对应的仓库
        final deptWarehouses = warehouses.where((w) => deptWarehouseIds.contains(w.id)).toList();
        if (deptWarehouses.isNotEmpty) {
          setState(() {
            _availableWarehouses = deptWarehouses;
            _selectedWarehouse = deptWarehouses.first;
            _warehouseLoading = false;
          });
          return;
        }
      }

      setState(() {
        _availableWarehouses = warehouses;
        if (warehouses.isNotEmpty) {
          _selectedWarehouse = warehouses.first;
        }
        _warehouseLoading = false;
      });
    } catch (_) {
      setState(() => _warehouseLoading = false);
    }
  }

  Future<void> _searchProduct(String text) async {
    if (text.trim().isEmpty || _selectedWarehouse == null) return;

    // 简化实现：目前仅支持按商品名称搜索
    // 完整实现需要后端提供商品搜索接口
    _showToast('商品搜索功能开发中，请手动添加商品');
  }

  Future<void> _addProductManually() async {
    // 手动添加商品对话框
    final productIdController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    final result = await showCupertinoDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('手动添加商品'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: productIdController,
              placeholder: '输入商品ID或名称',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: qtyController,
              placeholder: '数量',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('添加'),
            onPressed: () {
              Navigator.pop(context, {
                'productId': productIdController.text.trim(),
                'qty': int.tryParse(qtyController.text) ?? 1,
              });
            },
          ),
        ],
      ),
    );

    if (result != null && result['productId'].toString().isNotEmpty) {
      setState(() {
        _productList.add(_ScannedProduct(
          productId: int.tryParse(result['productId'].toString()) ?? 0,
          productName: result['productId'].toString(),
          qty: result['qty'] as int,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ));
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedWarehouse == null) {
      _showToast('请选择出库仓库');
      return;
    }
    if (_productList.isEmpty) {
      _showToast('请添加至少一个商品');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // 整理商品数据
      final goodsInfo = <Map<String, dynamic>>[];
      for (final p in _productList) {
        goodsInfo.add({
          'productId': p.productId,
          'quantity': p.qty,
        });
      }

      final transferId = await _transferApi.addFast(
        outWarehouseId: _selectedWarehouse!.id,
        goodsInfo: goodsInfo,
        remarks: '面对面调拨',
      );

      if (transferId != null && transferId > 0) {
        // 获取创建后的详情
        final detail = await _transferApi.detail(transferId);
        setState(() {
          _createdTransferId = transferId;
          _createdTransferDetail = detail != null ? {
            'transferID': transferId,
            'outWarehouse': _selectedWarehouse?.name ?? '',
            'productCount': _productList.fold(0, (sum, p) => sum + p.qty),
            'detail': detail,
          } : null;
          _isSubmitting = false;
        });
      } else {
        setState(() => _isSubmitting = false);
        _showToast('创建调拨单失败');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showToast('创建失败：$e');
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_createdTransferId != null ? '调拨完成' : '调拨出库'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _createdTransferId != null
            ? _buildCompletedView()
            : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        // 步骤指示器
        _StepIndicator(currentStep: 0),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 仓库选择
                _SectionTitle('出库仓库'),
                const SizedBox(height: 8),
                _WarehouseCard(
                  warehouse: _selectedWarehouse,
                  isLoading: _warehouseLoading,
                  onTap: _showWarehousePicker,
                ),

                const SizedBox(height: AppSpacing.lg),

                // 商品搜索
                _SectionTitle('调拨清单'),
                const SizedBox(height: 8),
                _SearchBar(
                  controller: _searchController,
                  onSubmitted: _searchProduct,
                  onAddManually: _addProductManually,
                ),

                const SizedBox(height: AppSpacing.md),

                // 商品列表
                if (_productList.isEmpty)
                  _EmptyProductTip()
                else
                  ..._productList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return _ProductCard(
                      product: product,
                      onQtyChanged: (newQty) {
                        setState(() {
                          _productList[index] = product.copyWith(qty: newQty);
                        });
                      },
                      onRemove: () {
                        setState(() => _productList.removeAt(index));
                      },
                    );
                  }),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // 底部提交按钮
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
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('保存并下一步'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final detail = _createdTransferDetail;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFF30D158),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '调拨单创建成功',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '单号: $_createdTransferId',
                  style: AppText.caption,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.divider,
                ),
                const SizedBox(height: 16),
                _DetailRow('出库仓库', detail?['outWarehouse'] ?? '-'),
                _DetailRow('商品数量', '${detail?['productCount'] ?? 0} 件'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () {
                context.go('/transfer-order');
              },
              child: const Text('返回调拨单列表'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.systemGrey5,
              onPressed: () => context.pop(),
              child: const Text(
                '返回上一页',
                style: TextStyle(color: Color(0xFF1C1C1E)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 步骤指示器
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: CupertinoColors.white,
      child: Row(
        children: [
          _StepItem(label: '调拨清单', isActive: currentStep == 0, isCompleted: currentStep > 0),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: currentStep > 0 ? AppColors.primary : CupertinoColors.systemGrey4,
            ),
          ),
          _StepItem(label: '调拨完成', isActive: currentStep == 1, isCompleted: false),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepItem({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? AppColors.primary : CupertinoColors.systemGrey4,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(CupertinoIcons.checkmark, size: 12, color: CupertinoColors.white)
                : Text(
                    isActive ? '1' : '2',
                    style: const TextStyle(color: CupertinoColors.white, fontSize: 11),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive || isCompleted ? AppColors.primary : CupertinoColors.systemGrey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppText.body.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
        ),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final WarehouseInfo? warehouse;
  final bool isLoading;
  final VoidCallback onTap;

  const _WarehouseCard({
    required this.warehouse,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(CupertinoIcons.building_2_fill, color: Color(0xFF00C7BE)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse?.name ?? '请选择仓库',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: warehouse != null
                          ? const Color(0xFF1C1C1E)
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                  if (warehouse?.number != null)
                    Text(warehouse!.number!, style: AppText.caption),
                ],
              ),
            ),
            if (isLoading)
              const CupertinoActivityIndicator()
            else
              const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmitted;
  final VoidCallback onAddManually;

  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoSearchTextField(
            controller: controller,
            placeholder: '扫码添加商品(标准商品)',
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onAddManually,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5856D6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '手动添加',
              style: TextStyle(color: CupertinoColors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyProductTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(CupertinoIcons.cube_box, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('暂未添加商品', style: AppText.caption),
          const SizedBox(height: 4),
          Text('请扫描商品条码或手动添加', style: AppText.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _ScannedProduct product;
  final void Function(int) onQtyChanged;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.onQtyChanged,
    required this.onRemove,
  });

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
                child: Text(
                  product.productName.isNotEmpty
                      ? product.productName
                      : '商品ID: ${product.productId}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                onPressed: onRemove,
                child: const Icon(CupertinoIcons.trash, size: 18, color: Color(0xFFFF3B30)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('数量', style: AppText.caption),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (product.qty > 1) onQtyChanged(product.qty - 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(CupertinoIcons.minus, size: 14),
                ),
              ),
              Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Center(
                  child: Text(
                    '${product.qty}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onQtyChanged(product.qty + 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(CupertinoIcons.plus, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppText.caption),
          const Spacer(),
          Text(value, style: AppText.body),
        ],
      ),
    );
  }
}

/// 扫描添加的商品
class _ScannedProduct {
  final int productId;
  final String productName;
  int qty;
  final int addedAt;

  _ScannedProduct({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.addedAt,
  });

  _ScannedProduct copyWith({int? qty}) {
    return _ScannedProduct(
      productId: productId,
      productName: productName,
      qty: qty ?? this.qty,
      addedAt: addedAt,
    );
  }
}

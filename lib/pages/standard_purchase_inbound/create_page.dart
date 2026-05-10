import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/standard_purchase_inbound_api.dart';
import '../../api/warehouse_api.dart';
import '../../theme/app_theme.dart';

/// 标品采购入库单创建页
/// 对应 PWA /pages/path-d/standard-purchase-inbound/order-create.tsx
/// 支持从采购订单引入或直接创建
class StandardPurchaseInboundCreatePage extends ConsumerStatefulWidget {
  /// 从采购订单引入时的采购订单ID
  final int? prePurchaseOrderId;

  const StandardPurchaseInboundCreatePage({super.key, this.prePurchaseOrderId});

  @override
  ConsumerState<StandardPurchaseInboundCreatePage> createState() =>
      _StandardPurchaseInboundCreatePageState();
}

class _StandardPurchaseInboundCreatePageState
    extends ConsumerState<StandardPurchaseInboundCreatePage> {
  final StandardPurchaseInboundApi _api = StandardPurchaseInboundApi();
  final WarehouseApi _warehouseApi = WarehouseApi();

  // 仓库选择
  List<WarehouseInfo> _warehouses = [];
  WarehouseInfo? _selectedWarehouse;
  bool _warehouseLoading = true;

  // 商品列表
  final List<_AddProduct> _productList = [];

  // 备注
  final TextEditingController _remarksController = TextEditingController();

  // 提交状态
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
    if (widget.prePurchaseOrderId != null) {
      _loadFromPurchaseOrder();
    }
  }

  Future<void> _loadWarehouses() async {
    setState(() => _warehouseLoading = true);
    try {
      final warehouses = await _warehouseApi.getManagerWarehouses();
      setState(() {
        _warehouses = warehouses;
        if (warehouses.isNotEmpty) {
          _selectedWarehouse = warehouses.first;
        }
        _warehouseLoading = false;
      });
    } catch (_) {
      setState(() => _warehouseLoading = false);
    }
  }

  Future<void> _loadFromPurchaseOrder() async {
    // 如果有采购订单ID，可以从这里加载采购订单中的商品
    // 目前简化处理，由用户手动添加商品
  }

  Future<void> _addProduct() async {
    final productIdController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    final result = await showCupertinoDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('添加商品'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: productIdController,
              placeholder: '商品ID或名称',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: qtyController,
              placeholder: '采购数量',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: priceController,
              placeholder: '采购单价（元）',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                'price': double.tryParse(priceController.text),
              });
            },
          ),
        ],
      ),
    );

    if (result != null && result['productId'].toString().isNotEmpty) {
      final priceYuan = result['price'] as double?;
      final priceCent = priceYuan != null ? (priceYuan * 100).round() : null;

      setState(() {
        _productList.add(_AddProduct(
          productId: int.tryParse(result['productId'].toString()) ?? 0,
          productName: result['productId'].toString(),
          qty: result['qty'] as int,
          priceCent: priceCent,
        ));
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedWarehouse == null) {
      _showToast('请选择入库仓库');
      return;
    }
    if (_productList.isEmpty) {
      _showToast('请添加至少一个商品');
      return;
    }

    // 验证：必须有采购单价
    final hasValidPrice = _productList.every((p) => p.priceCent != null);
    if (!hasValidPrice) {
      _showToast('请为所有商品填写采购单价');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final products = _productList.map((p) => {
        'product': p.productId,
        'count': p.qty,
        'cent': p.priceCent,
      }).toList();

      int? newId;
      if (widget.prePurchaseOrderId != null) {
        newId = await _api.addFromPurchaseOrder(
          purchaseOrderID: widget.prePurchaseOrderId!,
          warehouseID: _selectedWarehouse!.id,
          vendorID: 0, // 需要从采购订单获取
          products: products,
          remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        );
      } else {
        newId = await _api.addAudited(
          warehouseID: _selectedWarehouse!.id,
          vendorID: 0, // 需要手动选择
          products: products,
          remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        );
      }

      if (newId != null && newId > 0) {
        _showToast('创建成功！');
        if (mounted) {
          context.pushReplacement('/standard-purchase-inbound/detail/$newId');
        }
      } else {
        _showToast('创建失败');
      }
    } catch (e) {
      _showToast('创建失败：$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    if (_warehouses.isEmpty) return;

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
                    _selectedWarehouse = _warehouses[index];
                  });
                },
                children: _warehouses
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
        middle: const Text('新建采购入库单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: _isSubmitting
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _submit,
                child: const Text('提交', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 仓库选择
                    _SectionTitle('入库仓库'),
                    const SizedBox(height: 8),
                    _WarehouseCard(
                      warehouse: _selectedWarehouse,
                      isLoading: _warehouseLoading,
                      onTap: _showWarehousePicker,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 商品列表
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle('商品信息'),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: _addProduct,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.plus_circle_fill,
                                  size: 18, color: Color(0xFF007AFF)),
                              const SizedBox(width: 4),
                              Text('添加商品',
                                  style: AppText.caption.copyWith(
                                      color: const Color(0xFF007AFF))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_productList.isEmpty)
                      _EmptyTip()
                    else
                      ..._productList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        return _ProductCard(
                          product: product,
                          onQtyChanged: (qty) {
                            setState(() {
                              _productList[index] = product.copyWith(qty: qty);
                            });
                          },
                          onPriceChanged: (priceCent) {
                            setState(() {
                              _productList[index] = product.copyWith(priceCent: priceCent);
                            });
                          },
                          onRemove: () {
                            setState(() => _productList.removeAt(index));
                          },
                        );
                      }),

                    const SizedBox(height: AppSpacing.lg),

                    // 备注
                    _SectionTitle('备注'),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _remarksController,
                      placeholder: '可填写备注信息',
                      maxLines: 3,
                      padding: const EdgeInsets.all(12),
                    ),

                    const SizedBox(height: 100),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
              child: const Icon(CupertinoIcons.building_2_fill,
                  color: Color(0xFF00C7BE)),
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
              const Icon(CupertinoIcons.chevron_right,
                  size: 16, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

class _EmptyTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(CupertinoIcons.cube_box, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('暂无商品', style: AppText.caption),
          const SizedBox(height: 4),
          Text('点击上方"添加商品"按钮添加', style: AppText.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _AddProduct product;
  final void Function(int) onQtyChanged;
  final void Function(int?) onPriceChanged;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.onQtyChanged,
    required this.onPriceChanged,
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
                minSize: 0,
                onPressed: onRemove,
                child: const Icon(CupertinoIcons.trash,
                    size: 18, color: Color(0xFFFF3B30)),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: const Icon(CupertinoIcons.minus, size: 12),
                ),
              ),
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Center(
                  child: Text('${product.qty}', style: const TextStyle(fontSize: 14)),
                ),
              ),
              GestureDetector(
                onTap: () => onQtyChanged(product.qty + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: const Icon(CupertinoIcons.plus, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('单价（元）', style: AppText.caption),
              const Spacer(),
              SizedBox(
                width: 100,
                child: CupertinoTextField(
                  placeholder: '¥0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onChanged: (v) {
                    final cent = (double.tryParse(v) ?? 0) * 100;
                    onPriceChanged(cent > 0 ? cent.round() : null);
                  },
                ),
              ),
            ],
          ),
          if (product.priceCent != null) ...[
            const SizedBox(height: 4),
            Text(
              '合计: ¥${(product.qty * product.priceCent! / 100).toStringAsFixed(2)}',
              style: AppText.caption.copyWith(
                color: const Color(0xFFFF9500),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddProduct {
  final int productId;
  final String productName;
  int qty;
  int? priceCent; // 分

  _AddProduct({
    required this.productId,
    required this.productName,
    required this.qty,
    this.priceCent,
  });

  _AddProduct copyWith({int? qty, int? priceCent}) {
    return _AddProduct(
      productId: productId,
      productName: productName,
      qty: qty ?? this.qty,
      priceCent: priceCent ?? this.priceCent,
    );
  }
}

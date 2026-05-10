import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';

/// 调拨商品数据
class TransferProduct {
  final int productId;
  final String productName;
  final String? thumbnail;
  int quantity;

  TransferProduct({
    required this.productId,
    required this.productName,
    this.thumbnail,
    this.quantity = 1,
  });
}

/// 仓库数据
class Warehouse {
  final int id;
  final String name;
  final String? number;

  const Warehouse({
    required this.id,
    required this.name,
    this.number,
  });
}

final _warehouseListProvider = FutureProvider<List<Warehouse>>((ref) async {
  // 从后端获取仓库列表
  // 这里返回模拟数据
  return [
    const Warehouse(id: 1, name: '中心仓库', number: 'WH001'),
    const Warehouse(id: 2, name: '门店仓库A', number: 'WH002'),
    const Warehouse(id: 3, name: '门店仓库B', number: 'WH003'),
  ];
});

class TransferOrderCreatePage extends ConsumerStatefulWidget {
  const TransferOrderCreatePage({super.key});

  @override
  ConsumerState<TransferOrderCreatePage> createState() =>
      _TransferOrderCreatePageState();
}

class _TransferOrderCreatePageState
    extends ConsumerState<TransferOrderCreatePage> {
  Warehouse? _outWarehouse;
  Warehouse? _inWarehouse;
  final _remarkController = TextEditingController();
  final _searchController = TextEditingController();
  final List<TransferProduct> _products = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarkController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _totalQuantity =>
      _products.fold(0, (sum, p) => sum + p.quantity);

  Future<void> _submit() async {
    // 表单验证
    if (_outWarehouse == null) {
      _showToast('请选择出库仓库');
      return;
    }
    if (_inWarehouse == null) {
      _showToast('请选择入库仓库');
      return;
    }
    if (_products.isEmpty) {
      _showToast('请添加至少一种商品');
      return;
    }

    final invalidProduct = _products.where((p) => p.quantity <= 0).toList();
    if (invalidProduct.isNotEmpty) {
      _showToast('${invalidProduct.first.productName} 的调拨数量为 0，请修改后重试');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final client = ApiClient();
      await client.post('/transfer/create', data: {
        'outWarehouseID': _outWarehouse!.id,
        'inWarehouseID': _inWarehouse!.id,
        'remarks': _remarkController.text.trim(),
        'goodsInfo': _products.map((p) => {
          'productId': p.productId,
          'quantity': p.quantity,
        }).toList(),
      });

      if (mounted) {
        _showToast('调拨单创建成功');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showToast('创建失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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

  void _showOutWarehouseSheet() {
    if (_products.isNotEmpty) {
      _showToast('调拨清单中存在货品时，不允许编辑出库仓库');
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _WarehouseSheet(
        title: '选择出库仓库',
        onSelected: (w) {
          setState(() => _outWarehouse = w);
        },
      ),
    );
  }

  void _showInWarehouseSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _WarehouseSheet(
        title: '选择入库仓库',
        onSelected: (w) {
          setState(() => _inWarehouse = w);
        },
      ),
    );
  }

  void _showRemarkInput() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _RemarkInputModal(
        controller: _remarkController,
        onConfirm: () {
          setState(() {});
        },
      ),
    );
  }

  void _addProduct() {
    if (_outWarehouse == null) {
      _showToast('请先选择出库仓库');
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _AddProductSheet(
        warehouseId: _outWarehouse!.id,
        onAdd: (product) {
          setState(() {
            // 检查是否已存在该商品
            final existingIndex =
                _products.indexWhere((p) => p.productId == product.productId);
            if (existingIndex >= 0) {
              _products[existingIndex].quantity += product.quantity;
            } else {
              _products.add(product);
            }
          });
        },
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _products[index].quantity + delta;
      if (newQty > 0) {
        _products[index].quantity = newQty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('新建调拨单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const CupertinoActivityIndicator()
              : const Text('提交'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 仓库信息
                    _SectionHeader('仓库信息'),
                    const SizedBox(height: AppSpacing.sm),
                    _FormCard(
                      children: [
                        _FormRow(
                          label: '出库仓库',
                          value: _outWarehouse?.name ?? '请选择',
                          valueColor: _outWarehouse == null
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showOutWarehouseSheet,
                          showArrow: _products.isEmpty,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '入库仓库',
                          value: _inWarehouse?.name ?? '请选择',
                          valueColor: _inWarehouse == null
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showInWarehouseSheet,
                          showArrow: true,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '备注',
                          value: _remarkController.text.isEmpty
                              ? '请输入'
                              : _remarkController.text,
                          valueColor: _remarkController.text.isEmpty
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showRemarkInput,
                          showArrow: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 添加商品按钮
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: _outWarehouse == null
                          ? CupertinoColors.systemGrey4
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                      onPressed: _outWarehouse == null ? null : _addProduct,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.plus_circle_fill,
                            color: _outWarehouse == null
                                ? CupertinoColors.systemGrey
                                : AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '添加商品',
                            style: TextStyle(
                              color: _outWarehouse == null
                                  ? CupertinoColors.systemGrey
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_outWarehouse == null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.cube_box,
                              size: 48,
                              color: CupertinoColors.systemGrey3,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '请先选择仓库再添加商品',
                              style: AppText.body.copyWith(
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_products.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeader('调拨清单'),
                          Text(
                            '合计数量: $_totalQuantity',
                            style: AppText.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...List.generate(_products.length, (index) {
                        final product = _products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ProductCard(
                            product: product,
                            onDelete: () => _removeProduct(index),
                            onQuantityChanged: (delta) =>
                                _updateQuantity(index, delta),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // 底部栏
            if (_products.isNotEmpty)
              Container(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).padding.bottom + AppSpacing.md,
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
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('合计数量',
                            style: AppText.caption.copyWith(
                                color: CupertinoColors.secondaryLabel)),
                        Text(
                          '$_totalQuantity 件',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 10),
                      borderRadius: BorderRadius.circular(25),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white)
                          : const Text('提交申请'),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppText.label.copyWith(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showArrow;

  const _FormRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: AppText.body),
            ),
            Expanded(
              child: Text(
                value,
                style: AppText.body.copyWith(
                  color: valueColor ??
                      CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
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
      margin: const EdgeInsets.only(left: AppSpacing.lg),
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final TransferProduct product;
  final VoidCallback onDelete;
  final void Function(int delta) onQuantityChanged;

  const _ProductCard({
    required this.product,
    required this.onDelete,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // 商品图片
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: product.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(product.thumbnail!,
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.cube_box_fill,
                              color: AppColors.primary,
                            )),
                  )
                : Icon(CupertinoIcons.cube_box_fill, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 数量控制
                Row(
                  children: [
                    _QuantityButton(
                      icon: CupertinoIcons.minus,
                      onTap: () => onQuantityChanged(-1),
                    ),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text(
                        '${product.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: CupertinoIcons.plus,
                      onTap: () => onQuantityChanged(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 删除按钮
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                CupertinoIcons.trash,
                color: CupertinoColors.destructiveRed,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

/// 仓库选择弹窗
class _WarehouseSheet extends ConsumerWidget {
  final String title;
  final void Function(Warehouse) onSelected;

  const _WarehouseSheet({
    required this.title,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouses = ref.watch(_warehouseListProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(''),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark_circle_fill,
                        color:
                            CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  ),
                ],
              ),
            ),
            warehouses.when(
              data: (list) => Column(
                children: list.map((w) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onSelected(w);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.building_2_fill,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name, style: AppText.body),
                              if (w.number != null)
                                Text(
                                  w.number!,
                                  style: AppText.caption.copyWith(
                                      color: CupertinoColors.secondaryLabel),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Icon(CupertinoIcons.chevron_right,
                              size: 14,
                              color: CupertinoColors.tertiaryLabel
                                  .resolveFrom(context)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CupertinoActivityIndicator(),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('加载失败'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 备注输入弹窗
class _RemarkInputModal extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _RemarkInputModal({
    required this.controller,
    required this.onConfirm,
  });

  @override
  State<_RemarkInputModal> createState() => _RemarkInputModalState();
}

class _RemarkInputModalState extends State<_RemarkInputModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text('备注',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      widget.controller.text = _controller.text;
                      widget.onConfirm();
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: '请输入备注信息',
                maxLines: 4,
                maxLength: 500,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加商品弹窗
class _AddProductSheet extends StatefulWidget {
  final int warehouseId;
  final void Function(TransferProduct) onAdd;

  const _AddProductSheet({
    required this.warehouseId,
    required this.onAdd,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      // 模拟搜索结果，实际应从 API 获取
      await Future.delayed(const Duration(milliseconds: 300));
      // 模拟商品数据
      setState(() {
        _searchResults = [
          {
            'productId': 1,
            'productName': '商品A - 标准版',
            'thumbnail': null,
          },
          {
            'productId': 2,
            'productName': '商品B - 豪华版',
            'thumbnail': null,
          },
          {
            'productId': 3,
            'productName': '商品C - 简约版',
            'thumbnail': null,
          },
        ].where((item) =>
            (item['productName'] as String).contains(query)).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final newProduct = TransferProduct(
      productId: product['productId'] as int,
      productName: product['productName'] as String,
      thumbnail: product['thumbnail'] as String?,
      quantity: 1,
    );
    widget.onAdd(newProduct);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text('添加商品',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '搜索商品名称或扫码',
                onChanged: _search,
              ),
            ),
            // 商品列表
            Expanded(
              child: _isSearching
                  ? const Center(child: CupertinoActivityIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.search,
                                size: 48,
                                color: CupertinoColors.systemGrey3,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '搜索商品添加到调拨清单',
                                style: AppText.body.copyWith(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            return CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _addProduct(product),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: CupertinoColors.separator
                                          .resolveFrom(context),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.cube_box_fill,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        product['productName'] as String,
                                        style: AppText.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.plus_circle_fill,
                                      color: AppColors.primary,
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
      ),
    );
  }
}

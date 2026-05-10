import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/goods_request_api.dart';
import '../../api/product_api.dart';
import '../../models/product.dart';
import '../../models/goods_request.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../clerk/product_select_page.dart';

/// 报货单创建页
/// 对应 PWA /pages/path-d/goods-request.tsx
///
/// 流程：搜索商品 → 选择SKU并填写报货数量/备注 → 提交
class GoodsRequestCreatePage extends ConsumerStatefulWidget {
  const GoodsRequestCreatePage({super.key});

  @override
  ConsumerState<GoodsRequestCreatePage> createState() => _GoodsRequestCreatePageState();
}

class _GoodsRequestCreatePageState extends ConsumerState<GoodsRequestCreatePage> {
  final GoodsRequestApi _api = GoodsRequestApi();
  final ProductApi _productApi = ProductApi();

  /// 已添加的报货商品列表
  final List<_GoodsRequestItem> _items = [];
  bool _isSubmitting = false;

  /// SKU 名称缓存（避免重复查询）
  final Map<int, String> _skuNameCache = {};

  /// 添加商品到报货单
  Future<void> _addProduct() async {
    final result = await Navigator.of(context).push<Product>(_ CupertinoPageRoute(
      builder: (_) => const ProductSelectPage(),
    ));
    if (result == null) return;

    // 获取 SKU 列表（如果商品有规格，需要让用户选择规格）
    final skus = await _productApi.getSkuList(result.id);

    if (!mounted) return;

    if (skus.isEmpty) {
      // 无规格商品，直接弹出数量输入
      _showQuantitySheet(
        product: result,
        sku: null,
        skuName: result.name,
      );
    } else {
      // 有规格，弹出 SKU 选择
      _showSkuSelectSheet(result, skus);
    }
  }

  void _showSkuSelectSheet(Product product, List<ProductSku> skus) {
    ProductSku? selectedSku;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('选择规格', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: skus.map((sku) {
                  final isSelected = selectedSku?.id == sku.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedSku = sku);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0A84FF).withValues(alpha: 0.1)
                            : CupertinoColors.systemGrey6.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey4.resolveFrom(ctx),
                        ),
                      ),
                      child: Text(
                        sku.name,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF0A84FF) : CupertinoColors.label.resolveFrom(ctx),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: selectedSku != null
                      ? () {
                          Navigator.pop(ctx);
                          _showQuantitySheet(
                            product: product,
                            sku: selectedSku,
                            skuName: selectedSku!.name,
                          );
                        }
                      : null,
                  child: const Text('下一步'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantitySheet({
    required Product product,
    ProductSku? sku,
    required String skuName,
  }) {
    final qtyController = TextEditingController(text: '1');
    final remarkController = TextEditingController();
    final skuId = sku?.id ?? 0;
    // 检查是否已添加过
    final existingIndex = _items.indexWhere((item) => item.skuId == skuId);
    if (existingIndex >= 0) {
      _showTip('该商品已在报货单中，可直接修改数量');
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skuName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
              if (product.imageUrl != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(product.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                              child: const Icon(CupertinoIcons.cube_box),
                            )),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // 报货数量
              Row(
                children: [
                  const Text('报货数量', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CupertinoTextField(
                        controller: qtyController,
                        placeholder: '输入报货数量',
                        keyboardType: TextInputType.number,
                        decoration: null,
                        padding: EdgeInsets.zero,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 备注
              Row(
                children: [
                  const Text('备注', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CupertinoTextField(
                        controller: remarkController,
                        placeholder: '选填',
                        decoration: null,
                        padding: EdgeInsets.zero,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text.trim());
                    if (qty == null || qty <= 0) {
                      _showTip('请输入有效的报货数量');
                      return;
                    }
                    // 缓存 SKU 名称
                    if (sku != null) {
                      _skuNameCache[sku.id] = sku.name;
                    }
                    setState(() {
                      _items.add(_GoodsRequestItem(
                        skuId: skuId,
                        skuName: skuName,
                        productName: product.name,
                        thumbnail: product.imageUrl,
                        quantity: qty,
                        remarks: remarkController.text.trim().isEmpty ? null : remarkController.text.trim(),
                        productId: product.id,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('添加报货'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editItemQuantity(int index) {
    final item = _items[index];
    final qtyController = TextEditingController(text: item.quantity.toString());
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('报货数量', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CupertinoTextField(
                        controller: qtyController,
                        placeholder: '输入报货数量',
                        keyboardType: TextInputType.number,
                        decoration: null,
                        padding: EdgeInsets.zero,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text.trim());
                    if (qty == null || qty <= 0) {
                      _showTip('请输入有效的报货数量');
                      return;
                    }
                    setState(() {
                      _items[index] = item.copyWith(quantity: qty);
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editItemRemarks(int index) {
    final item = _items[index];
    final controller = TextEditingController(text: item.remarks ?? '');
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(item.skuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(ctx),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: '选填',
                  decoration: null,
                  padding: EdgeInsets.zero,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    setState(() {
                      _items[index] = item.copyWith(
                        remarks: controller.text.trim().isEmpty ? null : controller.text.trim(),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      _showTip('请添加商品报货数据后再提交！');
      return;
    }
    final unfilledItems = _items.where((item) => item.quantity <= 0).toList();
    if (unfilledItems.isNotEmpty) {
      _showTip('请填写完整商品报货数据后再提交！');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(currentUserProvider).value;
      final departmentId = user?.departmentId;
      if (departmentId == null) {
        _showTip('无法获取当前用户部门信息');
        setState(() => _isSubmitting = false);
        return;
      }

      final goodsInfo = _items.map((item) => <String, dynamic>{
        'skuID': item.skuId,
        'quantity': item.quantity,
        if (item.remarks != null && item.remarks!.isNotEmpty) 'remarks': item.remarks,
      }).toList();

      final ids = await _api.add(
        departmentID: departmentId,
        goodsrequestInfo: goodsInfo,
      );

      if (ids.isNotEmpty) {
        _showTip('创建报货信息成功！');
        if (mounted) context.pop();
      } else {
        _showTip('提交失败');
      }
    } catch (e) {
      _showTip('提交失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showTip(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
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
        middle: const Text('商品报货单'),
        trailing: _isSubmitting
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _submit,
                child: const Text('提交', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : _buildItemsList(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 272,
            height: 208,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.cube_box_fill, size: 64, color: CupertinoColors.systemGrey3),
                SizedBox(height: 16),
                Text('暂无报货商品', style: TextStyle(color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _addProduct,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.plus, size: 18),
                SizedBox(width: 8),
                Text('搜索商品'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _GoodsRequestItemCard(
          item: item,
          onEditQty: () => _editItemQuantity(index),
          onEditRemark: () => _editItemRemarks(index),
          onDelete: () {
            setState(() => _items.removeAt(index));
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                onPressed: _addProduct,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.plus_circle, color: Color(0xFF0A84FF), size: 18),
                    SizedBox(width: 6),
                    Text('搜索商品', style: TextStyle(color: Color(0xFF0A84FF))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _items.isEmpty || _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('提交申请'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 报货单商品项
class _GoodsRequestItem {
  final int skuId;
  final String skuName;
  final String productName;
  final String? thumbnail;
  final int quantity;
  final String? remarks;
  final int productId;

  const _GoodsRequestItem({
    required this.skuId,
    required this.skuName,
    required this.productName,
    this.thumbnail,
    required this.quantity,
    this.remarks,
    required this.productId,
  });

  _GoodsRequestItem copyWith({
    int? skuId,
    String? skuName,
    String? productName,
    String? thumbnail,
    int? quantity,
    String? remarks,
    int? productId,
  }) {
    return _GoodsRequestItem(
      skuId: skuId ?? this.skuId,
      skuName: skuName ?? this.skuName,
      productName: productName ?? this.productName,
      thumbnail: thumbnail ?? this.thumbnail,
      quantity: quantity ?? this.quantity,
      remarks: remarks ?? this.remarks,
      productId: productId ?? this.productId,
    );
  }
}

/// 报货商品卡片
class _GoodsRequestItemCard extends StatelessWidget {
  final _GoodsRequestItem item;
  final VoidCallback onEditQty;
  final VoidCallback onEditRemark;
  final VoidCallback onDelete;

  const _GoodsRequestItemCard({
    required this.item,
    required this.onEditQty,
    required this.onEditRemark,
    required this.onDelete,
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
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.skuName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onDelete,
                  child: const Text(
                    '删除',
                    style: TextStyle(color: CupertinoColors.systemRed, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // 内容行
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 缩略图 + 数量/备注
                Row(
                  children: [
                    // 缩略图
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5.resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.thumbnail!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  CupertinoIcons.cube_box_fill,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            )
                          : const Icon(
                              CupertinoIcons.cube_box_fill,
                              color: CupertinoColors.systemGrey,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 数量行
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onEditQty,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Text('报货数量:', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                                  const Spacer(),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 13, color: CupertinoColors.label, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.tertiaryLabel),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 备注行
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onEditRemark,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Text('备注:', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                                  const Spacer(),
                                  Flexible(
                                    child: Text(
                                      item.remarks ?? '点击输入',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: item.remarks == null ? CupertinoColors.tertiaryLabel : CupertinoColors.label,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.tertiaryLabel),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

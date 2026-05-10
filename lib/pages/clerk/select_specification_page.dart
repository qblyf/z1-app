import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/product_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 规格选择结果
class SpecificationSelectResult {
  final MallSpuInfo spuInfo;
  final MallSkuInfo skuInfo;
  final int quantity;
  final List<MallServiceItem> services;
  /// 总价（分）
  final int totalPrice;

  const SpecificationSelectResult({
    required this.spuInfo,
    required this.skuInfo,
    required this.quantity,
    required this.services,
    required this.totalPrice,
  });
}

/// 规格选择页面
///
/// 功能对标 PWA SelectSpecification 组件：
/// - SKU 规格选择（单选）
/// - 服务项目选择（多选，同类别互斥）
/// - 数量调整（受库存限制）
/// - 总价实时计算
///
/// 使用方式：
/// ```dart
/// final result = await SelectSpecificationPage.push(context, spuID: 123);
/// if (result != null) { ... }
/// ```
class SelectSpecificationPage extends ConsumerStatefulWidget {
  /// SPU ID（必需）
  final int spuID;

  const SelectSpecificationPage({
    super.key,
    required this.spuID,
  });

  /// 路由跳转方式打开
  static Future<SpecificationSelectResult?> push(BuildContext context, int spuID) {
    return Navigator.of(context).push<SpecificationSelectResult>(
      CupertinoPageRoute(
        builder: (_) => SelectSpecificationPage(spuID: spuID),
      ),
    );
  }

  @override
  ConsumerState<SelectSpecificationPage> createState() => _SelectSpecificationPageState();
}

class _SelectSpecificationPageState extends ConsumerState<SelectSpecificationPage> {
  final ProductApi _api = ProductApi();

  MallProductInfo? _productInfo;
  bool _loading = true;
  String? _error;

  /// 当前选中的 SKU
  int? _selectedSkuId;
  /// 当前选中的服务（每个类别最多选一个）
  final Map<int, MallServiceItem> _selectedServices = {};
  /// 当前数量
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await _api.getMallProduct(widget.spuID);
      if (mounted) {
        setState(() {
          _productInfo = info;
          _loading = false;
          // 默认选中第一个有库存的 SKU
          if (info.skus.isNotEmpty) {
            final firstWithStock = info.skus.where((s) => s.stock > 0).firstOrNull;
            _selectedSkuId = firstWithStock?.id ?? info.skus.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  MallSkuInfo? get _selectedSku {
    if (_selectedSkuId == null || _productInfo == null) return null;
    return _productInfo!.skus.where((s) => s.id == _selectedSkuId).firstOrNull;
  }

  /// 总价计算：SKU价格×数量 + 选中服务价格之和
  int get _totalPrice {
    int total = 0;
    // SKU 价格 × 数量
    if (_selectedSku != null && _selectedSku!.price != null) {
      total += (_selectedSku!.price! * _quantity);
    }
    // 服务价格之和（服务价格是一次性的，不乘数量）
    for (final s in _selectedServices.values) {
      total += s.price;
    }
    return total;
  }

  /// 选中/取消选中 SKU
  void _toggleSku(int skuId) {
    setState(() {
      if (_selectedSkuId == skuId) {
        _selectedSkuId = null;
        _selectedServices.clear();
      } else {
        _selectedSkuId = skuId;
        _selectedServices.clear(); // 切换 SKU 时清空已选服务
        _quantity = 1; // 重置数量
      }
    });
  }

  /// 选中/取消选中服务（同类别互斥）
  void _toggleService(int cateId, MallServiceItem service) {
    setState(() {
      if (_selectedServices[cateId]?.id == service.id) {
        _selectedServices.remove(cateId);
      } else {
        _selectedServices[cateId] = service;
      }
    });
  }

  /// 减少数量
  void _decreaseQuantity() {
    if (_selectedSkuId == null) return;
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  /// 增加数量
  void _increaseQuantity() {
    if (_selectedSkuId == null) return;
    final sku = _selectedSku;
    if (sku == null) return;
    setState(() {
      if (_quantity < sku.stock) {
        _quantity++;
      } else {
        _quantity = sku.stock > 0 ? sku.stock : 1;
      }
    });
  }

  /// 确认添加
  void _confirmAdd() {
    if (_selectedSku == null || _productInfo == null) return;

    final result = SpecificationSelectResult(
      spuInfo: _productInfo!.spu,
      skuInfo: _selectedSku!,
      quantity: _quantity,
      services: _selectedServices.values.toList(),
      totalPrice: _totalPrice,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: Text(
          _productInfo?.spu.name ?? '选择商品',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark_circle_fill, size: 28, color: CupertinoColors.systemGrey3),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingWidget(message: '加载中...');
    }
    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }
    if (_productInfo == null) {
      return const EmptyWidget(message: '商品信息不存在');
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.lg),
                _buildSkuSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildQuantitySection(),
                ...?_buildServiceSections(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 商品头部信息
  Widget _buildHeader() {
    final sku = _selectedSku;
    final image = sku?.thumbnail ?? _productInfo!.spu.images.firstOrNull ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 商品图片
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image.isNotEmpty
                ? Image.network(image, fit: BoxFit.cover)
                : const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 价格和库存
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // 价格
              Text(
                _selectedSkuId == null
                    ? '¥${((_productInfo!.skus.firstOrNull?.price ?? 0) / 100).toStringAsFixed(2)}'
                    : '¥${(_totalPrice / 100).toStringAsFixed(2)}',
                style: AppText.subtitle.copyWith(
                  color: const Color(0xFFFF222C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              // 库存
              if (sku != null)
                Text(
                  '剩余 ${sku.stock} 件',
                  style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// SKU 选择区块
  Widget _buildSkuSection() {
    final skus = _productInfo!.skus;
    if (skus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择', style: AppText.subtitle),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skus.map((sku) {
            final isSelected = _selectedSkuId == sku.id;
            final hasStock = sku.stock > 0;
            return GestureDetector(
              onTap: hasStock ? () => _toggleSku(sku.id) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (hasStock ? CupertinoColors.white : CupertinoColors.systemGrey6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : CupertinoColors.systemGrey4,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  sku.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasStock
                        ? (isSelected ? AppColors.primary : CupertinoColors.label)
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 数量选择区块
  Widget _buildQuantitySection() {
    final sku = _selectedSku;
    final maxStock = sku?.stock ?? 0;
    final canDecrease = _quantity > 1;
    final canIncrease = _quantity < maxStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('数量', style: AppText.subtitle),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            // 减少按钮
            GestureDetector(
              onTap: canDecrease ? _decreaseQuantity : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: canDecrease ? CupertinoColors.white : CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Center(
                  child: Text(
                    '−',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: canDecrease ? CupertinoColors.label : CupertinoColors.systemGrey3,
                    ),
                  ),
                ),
              ),
            ),
            // 数量显示
            Container(
              width: 60,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: Center(
                child: Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // 增加按钮
            GestureDetector(
              onTap: canIncrease ? _increaseQuantity : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: canIncrease ? CupertinoColors.white : CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: canIncrease ? CupertinoColors.label : CupertinoColors.systemGrey3,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (sku != null && maxStock > 0)
              Text(
                '库存 $maxStock',
                style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel),
              ),
          ],
        ),
      ],
    );
  }

  /// 服务选择区块（可选）
  List<Widget>? _buildServiceSections() {
    final categories = _productInfo!.services;
    if (categories == null || categories.isEmpty) return null;

    final widgets = <Widget>[];
    for (final cate in categories) {
      if (cate.service.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cate.cateName, style: AppText.subtitle),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cate.service.map((service) {
                  final isSelected = _selectedServices[cate.cateID]?.id == service.id;
                  return GestureDetector(
                    onTap: () => _toggleService(cate.cateID, service),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : CupertinoColors.systemGrey4,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            service.shortName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? AppColors.primary : CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '¥${(service.price / 100).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.primary
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              // 服务说明
              if (cate.cateRmark != null && cate.cateRmark!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    cate.cateRmark!,
                    style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  /// 底部确认栏
  Widget _buildBottomBar() {
    final isDisabled = _selectedSkuId == null;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '合计',
                  style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel),
                ),
                Text(
                  '¥${(_totalPrice / 100).toStringAsFixed(2)}',
                  style: AppText.subtitle.copyWith(
                    color: const Color(0xFFFF222C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            color: isDisabled ? CupertinoColors.systemGrey4 : AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            borderRadius: BorderRadius.circular(24),
            onPressed: isDisabled ? null : _confirmAdd,
            child: const Text(
              '添加商品',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../api/product_api.dart';
import '../../api/stocktaking_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 商品选择结果（包含选中的商品和SKU）
class ProductSelectResult {
  final Product product;
  final ProductSku? sku;
  const ProductSelectResult({required this.product, this.sku});
}

/// 商品选择 Provider
final productApiProvider = Provider<ProductApi>((ref) => ProductApi());

/// 商品搜索 Provider
final productSearchProvider =
    FutureProvider.family<List<Product>, _ProductSearchParams>((ref, params) async {
  final api = ref.read(productApiProvider);
  return api.search(
    keyword: params.keyword,
    categoryId: params.categoryId,
  );
});

/// 商品列表 Provider
final productListProvider =
    FutureProvider.family<List<Product>, _ProductListParams>((ref, params) async {
  final api = ref.read(productApiProvider);
  return api.getList(
    categoryId: params.categoryId,
    keyword: params.keyword,
  );
});

class _ProductSearchParams {
  final String keyword;
  final int? categoryId;
  const _ProductSearchParams({required this.keyword, this.categoryId});

  @override bool operator ==(Object o) =>
      o is _ProductSearchParams && o.keyword == keyword && o.categoryId == categoryId;
  @override int get hashCode => Object.hash(keyword, categoryId);
}

class _ProductListParams {
  final int? categoryId;
  final String? keyword;
  const _ProductListParams({this.categoryId, this.keyword});

  @override bool operator ==(Object o) =>
      o is _ProductListParams &&
      o.categoryId == categoryId &&
      o.keyword == keyword;
  @override int get hashCode => Object.hash(categoryId, keyword);
}

/// 商品选择页面
///
/// 支持两种使用方式：
/// 1. [onSelect] callback 模式（兼容旧代码）
/// 2. [selectProduct] 静态方法 —— 通过 Navigator.push 返回选中的 Product
/// 3. [returnWithSku] 模式 —— 返回 ProductSelectResult（含商品和SKU）
///
/// [warehouseIds] 不为空时，启用仓库绑定模式：
///   - 显示各商品在部门仓库的库存数量
///   - 库存不足的商品置灰显示
///   - 对应 PWA SelectProduct(warehouseIDs="boundToUserDept")
class ProductSelectPage extends ConsumerStatefulWidget {
  final Function(Product product, ProductSku? sku)? onSelect;
  final bool multiSelect;
  /// 部门绑定仓库的仓库ID列表
  /// 不为空时启用仓库绑定模式（显示库存）
  final List<int>? warehouseIds;
  /// 是否返回时包含 SKU（用于需要同时获取商品和规格的场景）
  final bool returnWithSku;

  const ProductSelectPage({
    super.key,
    this.onSelect,
    this.multiSelect = false,
    this.warehouseIds,
    this.returnWithSku = false,
  });

  /// 通过 push 方式获取选中的商品（无 SKU 选择步骤，直接返回 Product）
  /// 调用方式：
  /// ```dart
  /// final product = await ProductSelectPage.selectProduct(context);
  /// ```
  static Future<Product?> selectProduct(BuildContext context) {
    return Navigator.of(context).push<Product>(
      CupertinoPageRoute(builder: (_) => const ProductSelectPage()),
    );
  }

  /// 通过 push 方式获取选中的商品（仓库绑定模式，显示库存）
  static Future<Product?> selectProductWithWarehouse(
    BuildContext context,
    List<int> warehouseIds,
  ) {
    return Navigator.of(context).push<Product>(
      CupertinoPageRoute(
        builder: (_) => ProductSelectPage(warehouseIds: warehouseIds),
      ),
    );
  }

  /// 通过 push 方式获取选中的商品和SKU（仓库绑定模式）
  /// 适合需要同时获取商品和规格的场景（如预售订单更换预订商品）
  static Future<ProductSelectResult?> selectProductWithResult(
    BuildContext context,
    List<int>? warehouseIds,
  ) {
    return Navigator.of(context).push<ProductSelectResult>(
      CupertinoPageRoute(
        builder: (_) => ProductSelectPage(
          warehouseIds: warehouseIds,
          returnWithSku: true,
        ),
      ),
    );
  }

  /// 关闭页面并返回商品（供外部调用）
  static void finishWithProduct(BuildContext context, Product product) {
    Navigator.of(context).pop(product);
  }

  /// 关闭页面并返回商品+SKU（供外部调用）
  static void finishWithResult(BuildContext context, ProductSelectResult result) {
    Navigator.of(context).pop(result);
  }

  @override
  ConsumerState<ProductSelectPage> createState() => _ProductSelectPageState();
}

class _ProductSelectPageState extends ConsumerState<ProductSelectPage> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  // ignore: prefer_final_fields — 被 setState 中的 add/removeWhere 动态修改
  List<Product> _selectedProducts = [];
  final StocktakingApi _stocktakingApi = StocktakingApi();
  /// 当前选中的商品和SKU（用于 returnWithSku 模式）
  Product? _currentProduct;
  ProductSku? _currentSku;

  /// 商品库存映射表: productId -> totalStock
  Map<int, int> _stockMap = {};
  bool _loadingStock = false;

  /// 仓库绑定模式
  bool get _warehouseBound => widget.warehouseIds != null && widget.warehouseIds!.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 批量获取商品库存（按仓库）
  Future<void> _loadStockForProducts(List<Product> products) async {
    if (!_warehouseBound) return;
    if (products.isEmpty) return;

    setState(() => _loadingStock = true);
    try {
      // 批量获取库存，按 SKU 过滤
      final skuIds = <int>[];
      for (final p in products) {
        if (p.skus.isNotEmpty) {
          skuIds.addAll(p.skus.map((s) => s.id));
        } else {
          skuIds.add(p.id);
        }
      }

      final inv = await _stocktakingApi.getInventory(
        warehouseIDs: widget.warehouseIds!,
        skuIDs: skuIds,
        limit: 1000,
      );

      // 汇总各商品的总库存（跨仓库）
      final Map<int, int> aggregated = {};
      for (final item in inv) {
        final skuId = item['skuID'] as int? ?? item['skuId'] as int? ?? 0;
        final stock = item['stock'] as int? ?? 0;
        // 找到对应 product
        for (final p in products) {
          if (p.skus.isNotEmpty) {
            if (p.skus.any((s) => s.id == skuId)) {
              aggregated[p.id] = (aggregated[p.id] ?? 0) + stock;
            }
          } else if (p.id == skuId) {
            aggregated[p.id] = (aggregated[p.id] ?? 0) + stock;
          }
        }
      }

      if (mounted) {
        setState(() {
          _stockMap = aggregated;
          _loadingStock = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStock = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // returnWithSku 模式的底部确认栏
    Widget? bottomBar;
    if (widget.returnWithSku && _currentProduct != null) {
      final skuLabel = _currentSku != null ? ' / ${_currentSku!.name}' : '';
      bottomBar = Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
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
                  const Text('已选商品', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel)),
                  Text(
                    _currentProduct!.name + skuLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onPressed: () {
                Navigator.pop(context, ProductSelectResult(
                  product: _currentProduct!,
                  sku: _currentSku,
                ));
              },
              child: const Text('确认'),
            ),
          ],
        ),
      );
    }

    final scaffold = CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.returnWithSku
            ? (_currentProduct != null ? '已选商品' : '选择商品')
            : '选择商品'),
        leading: widget.returnWithSku
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              )
            : null,
        trailing: widget.multiSelect && _selectedProducts.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context, _selectedProducts),
                child: Text('确定 (${_selectedProducts.length})'),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(12),
              color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
              child: Column(
                children: [
                  CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: '搜索商品名称/编码',
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        ref.invalidate(productSearchProvider(
                          _ProductSearchParams(keyword: value, categoryId: _selectedCategoryId),
                        ));
                      }
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _CategoryChips(
                    selectedId: _selectedCategoryId,
                    onSelected: (id) {
                      setState(() => _selectedCategoryId = id);
                      ref.invalidate(productListProvider(
                        _ProductListParams(categoryId: id, keyword: _searchController.text),
                      ));
                    },
                  ),
                ],
              ),
            ),
            // 仓库绑定提示
            if (_warehouseBound) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: const Color(0xFFFFF3E0),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.cube_box_fill, size: 14, color: Color(0xFFFF9800)),
                    const SizedBox(width: 6),
                    Text(
                      '仅显示部门仓库商品',
                      style: TextStyle(fontSize: 12, color: const Color(0xFFE65100).withValues(alpha: 0.8)),
                    ),
                    if (_loadingStock) ...[
                      const SizedBox(width: 8),
                      const CupertinoActivityIndicator(radius: 7),
                    ],
                  ],
                ),
              ),
            ],
            // 商品列表
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );

    if (bottomBar != null) {
      return Column(children: [Expanded(child: scaffold), bottomBar]);
    }
    return scaffold;
  }

  Widget _buildProductList() {
    final keyword = _searchController.text.trim();

    if (keyword.isNotEmpty) {
      final searchAsync = ref.watch(productSearchProvider(
        _ProductSearchParams(keyword: keyword, categoryId: _selectedCategoryId),
      ));
      return searchAsync.when(
        data: (products) {
          // 仓库绑定模式下，搜索后也加载库存
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadStockForProducts(products);
          });
          return _buildProductGrid(products);
        },
        loading: () => const LoadingWidget(message: '搜索中...'),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      );
    }

    final listAsync = ref.watch(productListProvider(
      _ProductListParams(categoryId: _selectedCategoryId, keyword: keyword),
    ));

    return listAsync.when(
      data: (products) {
        // 仓库绑定模式下，列表加载后也加载库存
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadStockForProducts(products);
        });
        return _buildProductGrid(products);
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (e, _) => AppErrorWidget(message: e.toString()),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const EmptyWidget(
        message: '未找到商品',
        icon: CupertinoIcons.cube_box,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final stock = _warehouseBound ? (_stockMap[product.id] ?? 0) : null;
        final hasStock = stock == null || stock > 0;

        return Opacity(
          opacity: hasStock ? 1.0 : 0.45,
          child: _ProductCard(
            product: product,
            isSelected: _selectedProducts.any((p) => p.id == product.id),
            stock: stock,
            onTap: () {
              if (!hasStock) return;
              if (widget.multiSelect) {
                setState(() {
                  if (_selectedProducts.any((p) => p.id == product.id)) {
                    _selectedProducts.removeWhere((p) => p.id == product.id);
                  } else {
                    _selectedProducts.add(product);
                  }
                });
              } else {
                _showSkuDialog(product);
              }
            },
          ),
        );
      },
    );
  }

  void _showSkuDialog(Product product) {
    if (widget.returnWithSku) {
      // returnWithSku 模式：存储当前选择，等待确认
      setState(() => _currentProduct = product);
    }

    if (product.skus.isEmpty) {
      if (widget.returnWithSku) {
        setState(() => _currentSku = null);
      } else if (widget.onSelect != null) {
        widget.onSelect!.call(product, null);
        Navigator.pop(context);
      } else {
        Navigator.pop(context, product);
      }
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _SkuSelectSheet(
        product: product,
        warehouseIds: widget.warehouseIds,
        onSelect: (sku) {
          Navigator.pop(ctx);
          if (widget.returnWithSku) {
            setState(() => _currentSku = sku);
          } else if (widget.onSelect != null) {
            widget.onSelect!.call(product, sku);
            Navigator.pop(context);
          } else {
            Navigator.pop(context, product);
          }
        },
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  final int? selectedId;
  final Function(int?) onSelected;

  const _CategoryChips({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: '全部',
                selected: selectedId == null,
                onTap: () => onSelected(null),
              ),
              ...categories.map((c) => _CategoryChip(
                    label: c['name'] as String? ?? '',
                    selected: selectedId == c['id'],
                    onTap: () => onSelected(c['id'] as int?),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// 商品分类 Provider
final productCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(productApiProvider);
  return api.getCategories();
});

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? CupertinoColors.activeBlue.withValues(alpha: 0.2)
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.label.resolveFrom(context),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final int? stock;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isSelected,
    this.stock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasStock = stock == null || (stock ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : CupertinoColors.systemGrey5.resolveFrom(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品图片
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: product.imageUrl != null
                        ? ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(11)),
                            child: Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                CupertinoIcons.cube_box,
                                size: 48,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.cube_box,
                            size: 48,
                            color: CupertinoColors.systemGrey,
                          ),
                  ),
                ),
                // 商品信息
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.formattedPrice,
                              style: const TextStyle(
                                color: CupertinoColors.activeBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 库存标签（仓库绑定模式时显示）
                          if (stock != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: hasStock
                                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                    : const Color(0xFFF44336).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                hasStock ? '库存 $stock' : '无库存',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: hasStock
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFF44336),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 选择标记
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkuSelectSheet extends StatefulWidget {
  final Product product;
  final List<int>? warehouseIds;
  final Function(ProductSku) onSelect;

  const _SkuSelectSheet({
    required this.product,
    this.warehouseIds,
    required this.onSelect,
  });

  @override
  State<_SkuSelectSheet> createState() => _SkuSelectSheetState();
}

class _SkuSelectSheetState extends State<_SkuSelectSheet> {
  ProductSku? _selectedSku;
  Map<int, int> _skuStockMap = {};
  bool _loadingStock = false;

  bool get _warehouseBound =>
      widget.warehouseIds != null && widget.warehouseIds!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_warehouseBound) {
      _loadSkuStock();
    }
  }

  Future<void> _loadSkuStock() async {
    setState(() => _loadingStock = true);
    try {
      final api = StocktakingApi();
      final skuIds = widget.product.skus.map((s) => s.id).toList();
      final inv = await api.getInventory(
        warehouseIDs: widget.warehouseIds!,
        skuIDs: skuIds,
        limit: 1000,
      );
      final Map<int, int> stockMap = {};
      for (final item in inv) {
        final skuId = item['skuID'] as int? ?? item['skuId'] as int? ?? 0;
        final stock = item['stock'] as int? ?? 0;
        stockMap[skuId] = (stockMap[skuId] ?? 0) + stock;
      }
      if (mounted) setState(() { _skuStockMap = stockMap; _loadingStock = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(CupertinoIcons.cube_box),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¥${(_selectedSku?.price ?? widget.product.price) / 100}',
                        style: const TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.xmark_circle_fill),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '选择规格',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_loadingStock) ...[
                  const SizedBox(width: 8),
                  const CupertinoActivityIndicator(radius: 7),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.skus.map((sku) {
                final isSelected = _selectedSku?.id == sku.id;
                final skuStock = _skuStockMap[sku.id];
                final hasStock = skuStock == null || skuStock > 0;

                return Opacity(
                  opacity: hasStock ? 1.0 : 0.5,
                  child: GestureDetector(
                    onTap: hasStock ? () => setState(() => _selectedSku = sku) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
                            : CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey4.resolveFrom(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sku.name,
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                          if (skuStock != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              hasStock ? CupertinoIcons.cube_box_fill : CupertinoIcons.xmark_circle_fill,
                              size: 12,
                              color: hasStock
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFF44336),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _selectedSku != null
                    ? () => widget.onSelect(_selectedSku!)
                    : null,
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

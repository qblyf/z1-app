import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../api/product_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 商品选择 Provider
final productApiProvider = Provider<ProductApi>((ref) => ProductApi());

/// 商品搜索 Provider
final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, keyword) async {
  final api = ref.read(productApiProvider);
  return api.search(keyword: keyword);
});

/// 商品分类 Provider
final productCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(productApiProvider);
  return api.getCategories();
});

/// 商品列表 Provider
final productListProvider =
    FutureProvider.family<List<Product>, Map<String, dynamic>>((ref, params) async {
  final api = ref.read(productApiProvider);
  return api.getList(
    categoryId: params['categoryId'] as int?,
    keyword: params['keyword'] as String?,
    limit: params['limit'] as int? ?? 20,
    offset: params['offset'] as int? ?? 0,
  );
});

/// 商品选择页面
class ProductSelectPage extends ConsumerStatefulWidget {
  final Function(Product product, ProductSku? sku)? onSelect;
  final bool multiSelect;

  const ProductSelectPage({
    super.key,
    this.onSelect,
    this.multiSelect = false,
  });

  @override
  ConsumerState<ProductSelectPage> createState() => _ProductSelectPageState();
}

class _ProductSelectPageState extends ConsumerState<ProductSelectPage> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  List<Product> _selectedProducts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('选择商品'),
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
                        ref.invalidate(productSearchProvider(value));
                      }
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _CategoryChips(
                    selectedId: _selectedCategoryId,
                    onSelected: (id) {
                      setState(() => _selectedCategoryId = id);
                      ref.invalidate(productListProvider({
                        'categoryId': id,
                        'keyword': _searchController.text,
                      }));
                    },
                  ),
                ],
              ),
            ),

            // 商品列表
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final keyword = _searchController.text.trim();

    if (keyword.isNotEmpty) {
      final searchAsync = ref.watch(productSearchProvider(keyword));
      return searchAsync.when(
        data: (products) => _buildProductGrid(products),
        loading: () => const LoadingWidget(message: '搜索中...'),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      );
    }

    final listAsync = ref.watch(productListProvider({
      'categoryId': _selectedCategoryId,
      'keyword': keyword,
    }));

    return listAsync.when(
      data: (products) => _buildProductGrid(products),
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
        return _ProductCard(
          product: product,
          isSelected: _selectedProducts.any((p) => p.id == product.id),
          onTap: () {
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
        );
      },
    );
  }

  void _showSkuDialog(Product product) {
    if (product.skus.isEmpty) {
      widget.onSelect?.call(product, null);
      Navigator.pop(context);
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _SkuSelectSheet(
        product: product,
        onSelect: (sku) {
          widget.onSelect?.call(product, sku);
          Navigator.pop(context);
          Navigator.pop(context);
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
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.bold,
                        ),
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
  final Function(ProductSku) onSelect;

  const _SkuSelectSheet({required this.product, required this.onSelect});

  @override
  State<_SkuSelectSheet> createState() => _SkuSelectSheetState();
}

class _SkuSelectSheetState extends State<_SkuSelectSheet> {
  ProductSku? _selectedSku;

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
                        style: TextStyle(
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
            const Text(
              '选择规格',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.skus.map((sku) {
                final isSelected = _selectedSku?.id == sku.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSku = sku),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    child: Text(
                      sku.name,
                      style: TextStyle(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.label.resolveFrom(context),
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

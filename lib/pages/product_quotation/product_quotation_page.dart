import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/product_api.dart';
import '../../api/warehouse_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 商品报价单页面
/// 对应 PWA /pages/path-d/product-quotation.tsx
class ProductQuotationPage extends ConsumerStatefulWidget {
  const ProductQuotationPage({super.key});

  @override
  ConsumerState<ProductQuotationPage> createState() => _ProductQuotationPageState();
}

class _ProductQuotationPageState extends ConsumerState<ProductQuotationPage> {
  final ProductApi _productApi = ProductApi();
  final WarehouseApi _warehouseApi = WarehouseApi();

  // 搜索相关
  bool _searchVisible = false;
  final _searchController = TextEditingController();
  List<SpuSearchResult> _searchResults = [];
  bool _isSearching = false;

  // 报价单相关
  bool _quotationVisible = false;
  MallProductInfo? _productInfo;
  int? _selectedSkuId;
  int? _limitPrice;
  int _qty = 0;
  List<SkuStockInfo> _stockList = [];
  List<DeptStockInfo> _deptStockList = [];
  List<int> _currentWarehouseIds = [];
  bool _isLoadingQuotation = false;

  @override
  void initState() {
    super.initState();
    _loadUserWarehouses();
  }

  Future<void> _loadUserWarehouses() async {
    try {
      // 对应 PWA warehouseIDs="boundToUserDept"，获取用户部门的绑定仓库
      final user = ref.read(currentUserProvider).value;
      final deptId = user?.deptId;
      if (deptId != null) {
        final ids = await _warehouseApi.getWarehouseIdsByMainDeptId(deptId);
        if (mounted && ids.isNotEmpty) {
          setState(() => _currentWarehouseIds = ids);
          return;
        }
      }
      // 降级：获取当前用户管理的仓库
      final warehouses = await _warehouseApi.getManagerWarehouses();
      if (mounted && warehouses.isNotEmpty) {
        setState(() => _currentWarehouseIds = warehouses.map((w) => w.id).toList());
      }
    } catch (_) {}
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await _productApi.searchSpu(keyword: keyword.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadQuotation(int spuId) async {
    setState(() {
      _isLoadingQuotation = true;
      _quotationVisible = true;
      _searchVisible = false;
      _selectedSkuId = null;
      _qty = 0;
      _limitPrice = null;
      _stockList = [];
      _deptStockList = [];
    });

    try {
      final productInfo = await _productApi.getMallProduct(spuId);
      final skuIds = productInfo.skus.map((s) => s.id).toList();

      // 并行加载库存信息
      List<SkuStockInfo> stockList = [];
      List<DeptStockInfo> deptStockList = [];

      if (skuIds.isNotEmpty && _currentWarehouseIds.isNotEmpty) {
        stockList = await _productApi.getStockStats(
          productIds: skuIds,
          warehouseIds: _currentWarehouseIds.isNotEmpty ? _currentWarehouseIds : null,
        );
        deptStockList = await _productApi.getDepartmentStock(
          skuIds: skuIds,
          warehouseIds: _currentWarehouseIds,
        );
      }

      if (mounted) {
        setState(() {
          _productInfo = productInfo;
          _stockList = stockList;
          _deptStockList = deptStockList;
          _isLoadingQuotation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingQuotation = false);
    }
  }

  Future<void> _loadSkuQuotation(int skuId) async {
    try {
      final skuDetail = await _productApi.getSkuDetail(skuId);
      final stockList = await _productApi.getStockStats(
        productIds: [skuId],
        warehouseIds: _currentWarehouseIds.isNotEmpty ? _currentWarehouseIds : null,
      );
      final deptStockList = await _productApi.getDepartmentStock(
        skuIds: [skuId],
        warehouseIds: _currentWarehouseIds,
      );
      if (mounted) {
        setState(() {
          _selectedSkuId = skuId;
          _limitPrice = skuDetail.limitPrice;
          _stockList = stockList;
          _deptStockList = deptStockList;
        });
      }
    } catch (_) {}
  }

  SkuStockInfo? _getStockInfo(int skuId) {
    return _stockList.where((s) => s.productID == skuId).firstOrNull;
  }

  DeptStockInfo? _getDeptStockInfo(int skuId) {
    return _deptStockList.where((s) => s.skuID == skuId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('商品报价单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // 落地页
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    imageUrl: '/static/image/report.png',
                    width: 180,
                    height: 140,
                    placeholder: (_, __) => const Icon(
                      CupertinoIcons.doc_text,
                      size: 80,
                      color: Color(0xFFDDDDE0),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      CupertinoIcons.doc_text,
                      size: 80,
                      color: Color(0xFFDDDDE0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => setState(() => _searchVisible = true),
                      child: const Text('搜索商品'),
                    ),
                  ),
                ],
              ),
            ),
            // 搜索弹窗
            if (_searchVisible) _buildSearchModal(),
            // 报价单弹窗
            if (_quotationVisible) _buildQuotationModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchModal() {
    return Container(
      color: CupertinoColors.systemBackground,
      child: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: CupertinoColors.white,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: '输入商品名称搜索',
                    onSubmitted: _search,
                    onChanged: (v) {
                      if (v.length >= 2) _search(v);
                    },
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 12),
                  child: const Text('取消'),
                  onPressed: () => setState(() => _searchVisible = false),
                ),
              ],
            ),
          ),
          // 搜索结果
          Expanded(
            child: _isSearching
                ? const Center(child: CupertinoActivityIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty ? '请输入关键词搜索商品' : '未找到相关商品',
                          style: AppText.caption,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = _searchResults[i];
                          return GestureDetector(
                            onTap: () => _loadQuotation(item.id),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                boxShadow: AppShadows.card,
                              ),
                              child: Row(
                                children: [
                                  if (item.mainImage != null && item.mainImage!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item.mainImage!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 60,
                                          height: 60,
                                          color: CupertinoColors.systemGrey6,
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: CupertinoColors.systemGrey6,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.shortName != null && item.shortName!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.shortName!,
                                            style: AppText.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationModal() {
    return Container(
      color: CupertinoColors.white,
      child: Column(
        children: [
          // 关闭栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      color: Color(0xFF8E8E93), size: 24),
                  onPressed: () => setState(() {
                    _quotationVisible = false;
                    _productInfo = null;
                    _selectedSkuId = null;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingQuotation
                ? const Center(child: CupertinoActivityIndicator())
                : _productInfo == null
                    ? const Center(child: Text('加载失败'))
                    : _buildQuotationContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationContent() {
    final spu = _productInfo!.spu;
    final selectedSku = _selectedSkuId != null
        ? _productInfo!.skus.where((s) => s.id == _selectedSkuId).firstOrNull
        : null;
    final stockInfo = _selectedSkuId != null ? _getStockInfo(_selectedSkuId!) : null;
    final deptStockInfo = _selectedSkuId != null ? _getDeptStockInfo(_selectedSkuId!) : null;

    final displayPrice = selectedSku?.price ?? _productInfo!.skus.firstOrNull?.price;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 价格头部
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 价格
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('¥', style: TextStyle(fontSize: 14, color: Color(0xFFF21C1C))),
                    Text(
                      displayPrice != null ? _formatPrice(displayPrice) : '暂无报价',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF21C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 商品编号 & 可售数量
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        label: '商品编号',
                        value: _selectedSkuId != null
                            ? '${_selectedSkuId}'
                            : '未选择',
                        valueColor: const Color(0xFFF21C1C),
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        label: '可售数量',
                        value: deptStockInfo != null ? '${deptStockInfo.saleStock}' : '-',
                        valueColor: const Color(0xFFF21C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 库存 & 锁货
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        label: '商品库存',
                        value: stockInfo != null ? '${stockInfo.totalStock}' : '-',
                        valueColor: const Color(0xFFF21C1C),
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        label: '锁货数量',
                        value: deptStockInfo != null ? '${deptStockInfo.lockStock}' : '-',
                        valueColor: const Color(0xFFF21C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 最低售价
                _InfoItem(
                  label: '最低售价',
                  value: _limitPrice != null ? _formatPrice(_limitPrice!) : '未设置',
                  valueColor: const Color(0xFFF21C1C),
                ),
                const SizedBox(height: 8),
                // 已选SKU
                _InfoItem(
                  label: '已选',
                  value: selectedSku?.name ?? '未选择',
                  valueColor: CupertinoColors.black,
                ),
                if (spu.policyDesc != null && spu.policyDesc!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      spu.policyDesc!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFFF0000)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 商品图片
          if (spu.images.isNotEmpty) ...[
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: spu.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: spu.images[i],
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 160,
                      height: 160,
                      color: CupertinoColors.systemGrey6,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 160,
                      height: 160,
                      color: CupertinoColors.systemGrey6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // SKU选择
          if (spu.skuIDs != null && spu.skuIDs!.isNotEmpty) ...[
            _SectionTitle('选择规格'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _productInfo!.skus.map((sku) {
                final isSelected = sku.id == _selectedSkuId;
                return GestureDetector(
                  onTap: () => _loadSkuQuotation(sku.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                      border: sku.price == null
                          ? Border.all(color: const Color(0xFFDDDDE0), width: 0.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          sku.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? CupertinoColors.white : const Color(0xFF2A2A2A),
                          ),
                        ),
                        if (sku.price != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(sku.price!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? CupertinoColors.white.withValues(alpha: 0.8)
                                  : const Color(0xFFF21C1C),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 保障服务
          if (_productInfo!.services != null && _productInfo!.services!.isNotEmpty) ...[
            _SectionTitle('保障服务'),
            const SizedBox(height: 8),
            ...(_productInfo!.services!.map((cate) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cate.cateName,
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (cate.cateRmark != null) ...[
                        const SizedBox(height: 4),
                        Text(cate.cateRmark!, style: AppText.caption),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cate.service.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.shortName, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 8),
                                Text(
                                  _formatPrice(s.price),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFF21C1C)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ))),
          ],

          // 推荐商品
          if (_productInfo!.recommend.isNotEmpty) ...[
            _SectionTitle('相关推荐'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _productInfo!.recommend.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final rec = _productInfo!.recommend[i];
                  return GestureDetector(
                    onTap: () => _loadQuotation(rec.id),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: rec.mainImage != null && rec.mainImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: rec.mainImage!.first,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: CupertinoColors.systemGrey6,
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: CupertinoColors.systemGrey6,
                                ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            rec.shortName,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatPrice(int fen) {
    return (fen / 100).toStringAsFixed(2);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppText.body.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: valueColor ?? const Color(0xFF333333)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

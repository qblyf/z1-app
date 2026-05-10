import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/label_api.dart';
import '../../api/product_api.dart';
import '../../api/warehouse_api.dart';
import '../../models/label.dart';
import '../../providers/permission_provider.dart';
import '../../theme/app_theme.dart';
import '../clerk/product_select_page.dart';

/// 库存商品分布页面
/// 对应 PWA /pages/path-d/goods/stock-distribution.tsx
///
/// 核心功能：按商品维度展示库存分布，支持仓库/品牌/SKU标签筛选
class StockDistributionPage extends ConsumerStatefulWidget {
  const StockDistributionPage({super.key});

  @override
  ConsumerState<StockDistributionPage> createState() => _StockDistributionPageState();
}

class _StockDistributionPageState extends ConsumerState<StockDistributionPage> {
  final StockDistributionApi _stockApi = StockDistributionApi();
  final WarehouseApi _warehouseApi = WarehouseApi();
  final ProductApi _productApi = ProductApi();

  // 权限状态
  bool _permLoading = true;
  String? _permissionJwt;
  bool _hasPermission = false;

  // 筛选状态
  bool _searchVisible = true;
  List<WarehouseInfo> _warehouses = [];
  List<int> _selectedWarehouseIds = [];
  List<int> _selectedLabelIds = [];
  List<String> _selectedBrands = [];
  List<int> _selectedProductIds = []; // 已选商品SPU ID列表

  // 数据状态
  List<ProductStockDistributionItem> _allData = [];
  List<WarehouseStockItem> _warehouseBreakdown = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMsg;

  // 分页
  static const int _pageSize = 20;
  int _renderCount = _pageSize;

  // 详情弹窗
  bool _detailVisible = false;
  int? _detailProductId;
  bool _detailLoading = false;

  // SKU 名称缓存
  final Map<int, String> _skuNameCache = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadPermission(),
      _loadWarehouses(),
    ]);
    await _loadData();
  }

  Future<void> _loadPermission() async {
    try {
      final jwt = await permissionService.getPermissionJwt('stockManage');
      if (mounted) {
        setState(() {
          _permissionJwt = jwt;
          _hasPermission = jwt != null && jwt.isNotEmpty;
          _permLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permLoading = false;
          _hasPermission = false;
        });
      }
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final list = await _warehouseApi.getManagerWarehouses();
      if (mounted) setState(() => _warehouses = list);
    } catch (e) {
      debugPrint('加载仓库失败: $e');
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final data = await _stockApi.getProductDistribution(
        productIDs: _selectedProductIds.isEmpty ? null : _selectedProductIds,
        warehouseIDs: _selectedWarehouseIds.isEmpty ? null : _selectedWarehouseIds,
        labelIDs: _selectedLabelIds.isEmpty ? null : _selectedLabelIds,
        brands: _selectedBrands.isEmpty ? null : _selectedBrands,
        permissionJWT: _permissionJwt,
      );

      // 预加载 SKU 名称
      await _precacheSkuNames(data.map((e) => e.productID).whereType<int>().toSet());

      if (mounted) {
        setState(() {
          _allData = data;
          _renderCount = _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _precacheSkuNames(Set<int> ids) async {
    final uncached = ids.where((id) => !_skuNameCache.containsKey(id)).toList();
    if (uncached.isEmpty) return;
    try {
      final names = await _productApi.getSkuNames(uncached);
      if (mounted) {
        setState(() {
          for (final entry in names.entries) {
            _skuNameCache[entry.key] = entry.value;
          }
        });
      }
    } catch (_) {
      // 静默失败，使用默认名称
    }
  }

  String _getSkuName(int? productId) {
    if (productId == null) return '-';
    return _skuNameCache[productId] ?? '加载中...';
  }

  Future<void> _loadWarehouseBreakdown(int productId) async {
    setState(() { _detailLoading = true; _detailProductId = productId; });
    try {
      final data = await _stockApi.getProductDistribution(
        warehouseIDs: _selectedWarehouseIds.isEmpty ? null : _selectedWarehouseIds,
        labelIDs: _selectedLabelIds.isEmpty ? null : _selectedLabelIds,
        brands: _selectedBrands.isEmpty ? null : _selectedBrands,
        permissionJWT: _permissionJwt,
        fields: 'warehouse',
        filterZeroStock: false,
      );

      // 按仓库分组，只保留 productID 匹配的行
      final map = <int, WarehouseStockItem>{};
      for (final item in data) {
        if (item.productID == productId &&
            item.warehouseID != null &&
            item.totalStock != null &&
            item.totalStock != 0) {
          if (map.containsKey(item.warehouseID)) {
            final existing = map[item.warehouseID]!;
            map[item.warehouseID!] = existing.copyWith(
              totalStock: existing.totalStock + (item.totalStock ?? 0),
              totalCost: existing.totalCost + item.totalCost,
            );
          } else {
            final wh = _warehouses.firstWhere(
              (w) => w.id == item.warehouseID,
              orElse: () => WarehouseInfo(id: item.warehouseID!, name: '仓库${item.warehouseID}'),
            );
            map[item.warehouseID!] = WarehouseStockItem(
              warehouseId: item.warehouseID!,
              warehouseName: wh.name ?? '仓库${item.warehouseID}',
              totalStock: item.totalStock ?? 0,
              totalCost: item.totalCost,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _warehouseBreakdown = map.values.toList();
          _detailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  // 总计
  int get _totalCount => _allData.fold(0, (sum, item) => sum + (item.totalStock ?? 0));
  int get _totalAmount => _allData.fold(0, (sum, item) => sum + item.totalCost);

  // 当前渲染的数据
  List<ProductStockDistributionItem> get _renderedData {
    final cap = _allData.length < _pageSize + _pageSize ? _allData.length : _renderCount;
    return _allData.take(cap).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedProductIds = [];
      _selectedWarehouseIds = [];
      _selectedLabelIds = [];
      _selectedBrands = [];
    });
    _loadData();
  }

  void _showWarehousePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                const Text('选择仓库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadData();
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _warehouses.length,
                itemBuilder: (_, i) {
                  final w = _warehouses[i];
                  final selected = _selectedWarehouseIds.contains(w.id);
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onPressed: () {
                      setState(() {
                        if (selected) {
                          _selectedWarehouseIds = _selectedWarehouseIds.where((id) => id != w.id).toList();
                        } else {
                          _selectedWarehouseIds = [..._selectedWarehouseIds, w.id];
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                          color: selected ? AppColors.primary : CupertinoColors.systemGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(w.displayName)),
                      ],
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

  void _showBrandInput() {
    final controller = TextEditingController(text: _selectedBrands.join(', '));
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('品牌筛选'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: '输入品牌名称，多个用逗号分隔',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final text = controller.text.trim();
              setState(() {
                _selectedBrands = text.isEmpty ? [] : text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              });
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showProductPicker() async {
    final result = await ProductSelectPage.selectProduct(context);
    if (result != null && mounted) {
      setState(() {
        // 使用商品ID作为筛选条件（商品ID就是SPU ID）
        if (!_selectedProductIds.contains(result.id)) {
          _selectedProductIds = [result.id];
        }
      });
    }
  }

  void _showSkuLabelPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _SkuLabelPickerSheet(
        selectedIds: _selectedLabelIds,
        onApply: (ids) {
          setState(() => _selectedLabelIds = ids);
        },
      ),
    );
  }

  void _showDetailModal(ProductStockDistributionItem item) {
    if (item.productID == null) return;
    _loadWarehouseBreakdown(item.productID!);
    setState(() {
      _detailVisible = true;
      _detailProductId = item.productID;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('库存商品分布')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (!_hasPermission) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('库存商品分布')),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.lock_fill, size: 48, color: CupertinoColors.systemGrey),
              const SizedBox(height: 16),
              Text('暂无权限访问', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('库存商品分布'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(_searchVisible ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 20),
          onPressed: () => setState(() => _searchVisible = !_searchVisible),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 筛选区
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: _searchVisible ? _buildSearchSection() : const SizedBox.shrink(),
                ),
                // 统计汇总
                _buildSummaryBar(),
                // 列表
                Expanded(child: _buildList()),
              ],
            ),
            // 详情弹窗
            if (_detailVisible) _buildDetailModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // 商品分类（简化版：暂不支持，提示）
          _filterRow(
            label: '商品分类',
            value: _selectedProductIds.isEmpty ? '请选择' : '已选${_selectedProductIds.length}个商品',
            placeholder: _selectedProductIds.isEmpty,
            onTap: _showProductPicker,
          ),
          _divider(),
          // 仓库
          _filterRow(
            label: '仓库',
            value: _selectedWarehouseIds.isEmpty
                ? '请选择'
                : _selectedWarehouseIds.length == 1
                    ? _warehouses.firstWhere((w) => w.id == _selectedWarehouseIds.first, orElse: () => WarehouseInfo(id: 0, name: '已选${_selectedWarehouseIds.length}个')).displayName
                    : '已选${_selectedWarehouseIds.length}个',
            placeholder: _selectedWarehouseIds.isEmpty,
            onTap: _showWarehousePicker,
          ),
          _divider(),
          // 品牌
          _filterRow(
            label: '品牌',
            value: _selectedBrands.isEmpty ? '请选择' : _selectedBrands.join(', '),
            placeholder: _selectedBrands.isEmpty,
            onTap: _showBrandInput,
          ),
          _divider(),
          // SKU标签
          _filterRow(
            label: 'SKU标签',
            value: _selectedLabelIds.isEmpty ? '请选择' : '已选${_selectedLabelIds.length}个标签',
            placeholder: _selectedLabelIds.isEmpty,
            onTap: _showSkuLabelPicker,
          ),
          // 按钮行
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    onPressed: _resetFilters,
                    child: const Text('重置筛选', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: _loadData,
                    child: const Text('查询', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow({
    required String label,
    required String value,
    bool placeholder = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: CupertinoColors.label.resolveFrom(context))),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: placeholder
                      ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 0.5, margin: const EdgeInsets.only(left: 16), color: CupertinoColors.separator.resolveFrom(context));

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: CupertinoColors.white,
      child: Row(
        children: [
          Text('商品总数量 ', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          Text('$_totalCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 16),
          Text('商品总金额 ', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          Text('¥${(_totalAmount / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CupertinoActivityIndicator());
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMsg!, style: const TextStyle(color: CupertinoColors.systemRed)),
            const SizedBox(height: 12),
            CupertinoButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_allData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.doc_text, size: 48, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 12),
            Text('暂无数据', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notif) {
        if (notif is ScrollEndNotification && notif.metrics.pixels >= notif.metrics.maxScrollExtent - 100) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _renderedData.length + 1,
        itemBuilder: (context, index) {
          if (index == _renderedData.length) {
            return _renderedData.length < _allData.length
                ? const Padding(padding: EdgeInsets.all(16), child: CupertinoActivityIndicator())
                : const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('— 已加载全部 —', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey))));
          }
          return _buildItem(_renderedData[index], index);
        },
      ),
    );
  }

  void _loadMore() {
    if (_isLoadingMore || _renderCount >= _allData.length) return;
    setState(() {
      _isLoadingMore = true;
      _renderCount += _pageSize;
      _isLoadingMore = false;
    });
  }

  Widget _buildItem(ProductStockDistributionItem item, int index) {
    final name = _getSkuName(item.productID);
    final unitPrice = item.totalStock != null && item.totalStock != 0
        ? (item.totalCost / item.totalStock!).round()
        : 0;

    return GestureDetector(
      onTap: () => _showDetailModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.productID != null)
                          Text(
                            'ID: ${item.productID}',
                            style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.totalStock ?? 0}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const Text('库存', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ],
              ),
            ),
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.md)),
              ),
              child: Row(
                children: [
                  const Text('库存', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  const Spacer(),
                  const Text('单价', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                  const SizedBox(width: 24),
                  const Text('金额', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDetailModal() {
    final productId = _detailProductId;
    final productName = _getSkuName(productId);
    final totalCount = _warehouseBreakdown.fold(0, (sum, w) => sum + w.totalStock);
    final totalAmount = _warehouseBreakdown.fold(0, (sum, w) => sum + w.totalCost);

    return GestureDetector(
      onTap: () => setState(() => _detailVisible = false),
      child: Container(
        color: CupertinoColors.black.withValues(alpha: 0.4),
        child: GestureDetector(
          onTap: () {}, // 阻止点击穿透
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(child: Text('分布情况', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                          GestureDetector(
                            onTap: () => setState(() => _detailVisible = false),
                            child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.primary, size: 22),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                    // 商品信息
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('商品总数量: ', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                              Text('$totalCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(width: 16),
                              Text('商品总金额: ', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                              Text('¥${(totalAmount / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                    // 表头
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Expanded(flex: 3, child: Text('仓库', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey))),
                          const Expanded(flex: 2, child: Text('数量', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey))),
                          const Expanded(flex: 2, child: Text('库存单价', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey))),
                          const Expanded(flex: 2, child: Text('库存金额', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey))),
                        ],
                      ),
                    ),
                    Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 16), color: CupertinoColors.separator.resolveFrom(context)),
                    // 仓库列表
                    SizedBox(
                      height: 220,
                      child: _detailLoading
                          ? const Center(child: CupertinoActivityIndicator())
                          : _warehouseBreakdown.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(CupertinoIcons.doc_text, size: 36, color: Color(0xFFDDDDE0)),
                                      const SizedBox(height: 8),
                                      Text('暂无仓库分布数据', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 13)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _warehouseBreakdown.length,
                                  separatorBuilder: (_, __) => Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                                  itemBuilder: (_, i) {
                                    final w = _warehouseBreakdown[i];
                                    final unitPrice = w.totalStock > 0 ? (w.totalCost / w.totalStock).round() : 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(w.warehouseName, style: const TextStyle(fontSize: 13))),
                                          Expanded(flex: 2, child: Text('${w.totalStock}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                          Expanded(flex: 2, child: Text('¥${(unitPrice / 100).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                          Expanded(flex: 2, child: Text('¥${(w.totalCost / 100).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SKU标签选择弹窗
class _SkuLabelPickerSheet extends StatefulWidget {
  final List<int> selectedIds;
  final void Function(List<int>) onApply;

  const _SkuLabelPickerSheet({
    required this.selectedIds,
    required this.onApply,
  });

  @override
  State<_SkuLabelPickerSheet> createState() => _SkuLabelPickerSheetState();
}

class _SkuLabelPickerSheetState extends State<_SkuLabelPickerSheet> {
  final LabelApi _labelApi = LabelApi();
  List<Label> _allLabels = [];
  late Set<int> _selected;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    try {
      final labels = await _labelApi.listByType(LabelType.sku);
      if (mounted) {
        setState(() {
          _allLabels = labels;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md, right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
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
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择SKU标签', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Row(
                  children: [
                    if (_selected.isNotEmpty)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _selected.clear()),
                        child: const Text('清空', style: TextStyle(fontSize: 14)),
                      ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 标签列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _allLabels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.tag, size: 40, color: CupertinoColors.systemGrey),
                              const SizedBox(height: 8),
                              Text('暂无可用SKU标签', style: AppText.caption),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _allLabels.length,
                          separatorBuilder: (_, __) => Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),
                          itemBuilder: (_, i) {
                            final label = _allLabels[i];
                            final isSelected = _selected.contains(label.id);
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selected.remove(label.id);
                                  } else {
                                    _selected.add(label.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _parseColor(label.color),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        label.name,
                                        style: AppText.body.copyWith(
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(CupertinoIcons.checkmark, size: 18, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 确定按钮
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () {
                  widget.onApply(_selected.toList());
                  Navigator.pop(context);
                },
                child: Text(
                  widget.selectedIds.isEmpty && _selected.isEmpty
                      ? '关闭'
                      : '已选 ${_selected.length} 个标签',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final colorStr = hex.replaceFirst('#', '');
      return Color(int.parse('FF$colorStr', radix: 16));
    } catch (_) {
      return const Color(0xFF7B3763);
    }
  }
}

/// 单个仓库库存明细
class WarehouseStockItem {
  final int warehouseId;
  final String warehouseName;
  final int totalStock;
  final int totalCost;

  WarehouseStockItem({
    required this.warehouseId,
    required this.warehouseName,
    required this.totalStock,
    required this.totalCost,
  });

  WarehouseStockItem copyWith({int? totalStock, int? totalCost}) {
    return WarehouseStockItem(
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      totalStock: totalStock ?? this.totalStock,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

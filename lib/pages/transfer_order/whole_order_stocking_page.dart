import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/draft_api.dart';
import '../../api/goods_api.dart';
import '../../api/warehouse_api.dart';
import '../../api/product_api.dart';
import '../../models/stocking.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import '../../providers/auth_provider.dart';

/// 整单备货页面
/// 从调拨草稿加载，按清单扫码逐件备货
/// 对应 PWA /pages/path-d/transfer-order/whole-order-stocking
class WholeOrderStockingPage extends ConsumerStatefulWidget {
  final int draftId;

  const WholeOrderStockingPage({super.key, required this.draftId});

  @override
  ConsumerState<WholeOrderStockingPage> createState() => _WholeOrderStockingPageState();
}

class _WholeOrderStockingPageState extends ConsumerState<WholeOrderStockingPage> {
  final DraftApi _draftApi = DraftApi();
  final WarehouseApi _warehouseApi = WarehouseApi();
  final GoodsApi _goodsApi = GoodsApi();
  final ProductApi _productApi = ProductApi();

  final _searchController = TextEditingController();
  final _scanInputController = TextEditingController();
  final _focusNode = FocusNode();

  TransferStockingDraft? _draft;
  WarehouseInfo? _outWarehouse;
  WarehouseInfo? _inWarehouse;
  String? _creatorName;

  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSaving = false;
  String? _errorMsg;

  // 备货记录列表（扫描添加的货品）
  List<StockingItem> _stockingItems = [];

  // SKU 名称缓存
  Map<int, String> _skuNames = {};

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanInputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final draft = await _draftApi.getDetail(widget.draftId);
      if (draft == null || !mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '草稿不存在';
        });
        return;
      }

      final data = draft.parseData();
      if (data.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMsg = '草稿数据为空';
        });
        return;
      }

      final draftData = TransferStockingDraft.fromJson(data);
      final outId = draftData.outWarehouseId;
      final inId = draftData.inWarehouseId;

      // 加载仓库信息
      final warehouseIds = [outId, if (inId != null) inId].toSet().toList();
      final warehouses = await _warehouseApi.getWarehousesByIds(warehouseIds);

      WarehouseInfo? outW;
      WarehouseInfo? inW;
      for (final w in warehouses) {
        if (w.id == outId) outW = w;
        if (w.id == inId) inW = w;
      }

      // 加载 SKU 名称
      final productIds = draftData.transferProducts.map((p) => p.productId).toSet().toList();
      final names = await _productApi.getSkuNames(productIds);

      // 加载制单人名称
      final creatorName = await _loadEmployeeName(draftData.createdBy);

      if (!mounted) return;

      setState(() {
        _draft = draftData;
        _outWarehouse = outW;
        _inWarehouse = inW;
        _skuNames = names;
        _creatorName = creatorName;
        _isLoading = false;
      });

      // 如果有已备货的货品（从草稿 data 中恢复）
      _restoreStockingItems(data);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '加载失败: $e';
        });
      }
    }
  }

  void _restoreStockingItems(Map<String, dynamic> data) {
    // 从 transferProducts 中恢复已备货的货品
    // PWA 在备货完成时会保存备货结果到 draft data
    final products = data['transferProducts'] as List<dynamic>? ?? [];
    final currentUser = ref.read(currentUserProvider).value;
    final userId = currentUser?.userIdent ?? 0;

    for (final p in products) {
      final pd = p as Map<String, dynamic>;
      final productId = pd['productID'] as int? ?? 0;
      final goodsList = pd['goodsList'] as List<dynamic>?;

      if (goodsList != null && goodsList.isNotEmpty) {
        for (final g in goodsList) {
          final gd = g as Map<String, dynamic>;
          final goodsId = gd['id'] as int? ?? 0;
          final serial = gd['serial'] as String? ?? '';
          if (goodsId > 0) {
            _stockingItems.add(StockingItem(
              productId: productId,
              goodsId: goodsId,
              createdBy: userId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              remarks: serial,
            ));
          }
        }
      }

      final qty = pd['quantity'] as int?;
      if (qty != null && qty > 0) {
        _stockingItems.add(StockingItem(
          productId: productId,
          qty: qty,
          createdBy: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          remarks: '',
        ));
      }
    }
    if (_stockingItems.isNotEmpty) {
      setState(() {});
    }
  }

  Future<String?> _loadEmployeeName(int userIdent) async {
    try {
      // 简单返回 userIdent 作为备选
      return '员工$userIdent';
    } catch (_) {
      return null;
    }
  }

  /// 搜索串号/扫码
  Future<void> _search(String input) async {
    final text = input.trim();
    if (text.isEmpty) return;
    if (_draft == null) return;

    setState(() => _isSearching = true);

    try {
      final results = await _goodsApi.searchBySerial(text);

      if (!mounted) return;

      if (results.isEmpty) {
        _showToast('未找到该串号');
        setState(() => _isSearching = false);
        return;
      }

      final result = results.first;
      final goodsId = result.goodsId;

      if (goodsId == null) {
        _showToast('串号信息不完整');
        setState(() => _isSearching = false);
        return;
      }

      // 获取货品详情
      final goodsInfo = await _goodsApi.getGoodsDetail([goodsId]);
      final productId = goodsInfo.product;

      // 验证商品是否在调拨清单中
      final allowedProductIds = _draft!.transferProducts.map((p) => p.productId).toSet();
      if (!allowedProductIds.contains(productId)) {
        _showToast('扫描商品与所需商品类型不符');
        setState(() => _isSearching = false);
        return;
      }

      // 检查是否已添加过
      final alreadyAdded = _stockingItems.any((item) => item.goodsId == goodsId);
      if (alreadyAdded) {
        _showToast('该串号已添加');
        setState(() => _isSearching = false);
        return;
      }

      // 获取当前用户
      final currentUser = ref.read(currentUserProvider).value;
      final userId = currentUser?.userIdent ?? 0;

      // 添加备货记录
      final item = StockingItem(
        productId: productId,
        goodsId: goodsId,
        createdBy: userId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        remarks: text,
      );

      setState(() {
        _stockingItems.add(item);
        _isSearching = false;
        _searchController.clear();
      });
    } catch (e) {
      if (mounted) {
        _showToast('搜索失败: $e');
        setState(() => _isSearching = false);
      }
    }
  }

  /// 删除备货项（按 goodsId）
  void _deleteItem(int goodsId) {
    setState(() {
      _stockingItems.removeWhere((i) => i.goodsId == goodsId);
    });
  }

  /// 备货完成 - 保存到草稿并跳转
  Future<void> _completeStocking() async {
    if (_draft == null) return;

    if (_stockingItems.isEmpty) {
      _showToast('您没有选择任何商品');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 转换备货记录为调拨商品格式
      final stockedProducts = convertStockingItemsToTransferProducts(
        _stockingItems,
        _draft!.transferProducts,
      );

      // 验证备货是否完成
      final validationError = _validateStocking(stockedProducts);
      if (validationError != null) {
        _showToast(validationError);
        setState(() => _isSaving = false);
        return;
      }

      // 构建保存数据
      final data = {
        'inWarehouseID': _draft!.inWarehouseId,
        'outWarehouseID': _draft!.outWarehouseId,
        'remarks': _draft!.remarks,
        'transferProducts': stockedProducts.map((p) => p.toJson()).toList(),
      };

      // 保存到草稿
      await _draftApi.update(
        id: widget.draftId,
        data: data,
        remarks: _draft!.remarks,
      );

      if (!mounted) return;

      _showToast('备货完成！');

      // 跳转到调拨单创建页
      context.push('${Routes.transferOrderCreate}?draftId=${widget.draftId}');
    } catch (e) {
      if (mounted) {
        _showToast('保存失败: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateStocking(List<TransferProductStocking> stockedProducts) {
    if (_draft == null) return null;

    final preProducts = _draft!.transferProducts;

    // 检查是否所有商品都已备货
    for (final pre in preProducts) {
      final stocked = stockedProducts.where((s) => s.productId == pre.productId).firstOrNull;

      if (stocked == null) {
        final name = _skuNames[pre.productId] ?? '商品${pre.productId}';
        return '$name 未完成备货，请继续备货！';
      }

      if (pre.goodsList != null) {
        // 强制序列号商品
        if ((stocked.goodsList?.length ?? 0) < pre.preTransferQuantity) {
          final name = _skuNames[pre.productId] ?? '商品${pre.productId}';
          return '$name 未完成备货（当前 ${stocked.goodsList?.length ?? 0} 件 / 需调拨 ${pre.preTransferQuantity} 件）';
        }
      } else {
        // 非强制序列号商品
        if ((stocked.quantity ?? 0) < pre.preTransferQuantity) {
          final name = _skuNames[pre.productId] ?? '商品${pre.productId}';
          return '$name 未完成备货（当前 ${stocked.quantity ?? 0} 件 / 需调拨 ${pre.preTransferQuantity} 件）';
        }
      }
    }

    return null;
  }

  /// 取消备货
  void _cancelStocking() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('取消备货'),
        content: const Text('确认取消备货吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('确认'),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
          ),
        ],
      ),
    );
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

  /// 获取备货后的调拨商品
  TransferProductStocking? _getStockedProduct(int productId) {
    final items = _stockingItems.where((i) => i.productId == productId).toList();
    if (items.isEmpty) return null;

    final preProduct = _draft!.transferProducts.where((p) => p.productId == productId).firstOrNull;
    final preQty = preProduct?.preTransferQuantity ?? 0;

    final hasGoods = items.any((i) => i.goodsId != null);
    if (hasGoods) {
      final goodsList = items
          .where((i) => i.goodsId != null)
          .map((i) => StockingGoods(id: i.goodsId!, serial: i.remarks.trim()))
          .toList();
      return TransferProductStocking(
        productId: productId,
        goodsList: goodsList,
        preTransferQuantity: preQty,
      );
    } else {
      return TransferProductStocking(
        productId: productId,
        quantity: items.length,
        preTransferQuantity: preQty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_draft == null ? '整单备货' : '调拨单草稿详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: _cancelStocking,
        ),
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text(_errorMsg!, style: AppText.body),
            const SizedBox(height: 16),
            CupertinoButton(
              child: const Text('返回'),
              onPressed: () => context.pop(),
            ),
          ],
        ),
      );
    }

    if (_draft == null) {
      return const Center(child: Text('草稿不存在'));
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // 搜索栏
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),

              // 提示
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '*强制序列号商品仅可通过扫码备货，非强制序列号商品可通过扫描69码备货',
                    style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                  ),
                ),
              ),

              // 仓库和制单人信息
              SliverToBoxAdapter(
                child: _buildInfoSection(),
              ),

              // 调拨清单标题
              SliverToBoxAdapter(
                child: _buildListHeader(),
              ),

              // 调拨清单卡片列表
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _draft!.transferProducts[index];
                    return _StockingProductCard(
                      productId: product.productId,
                      productName: _skuNames[product.productId] ?? '商品${product.productId}',
                      preProduct: product,
                      stockedProduct: _getStockedProduct(product.productId),
                      onDeleteGoods: (goodsId) => _deleteItem(goodsId),
                      outWarehouseId: _draft!.outWarehouseId,
                    );
                  },
                  childCount: _draft!.transferProducts.length,
                ),
              ),

              // 底部占位
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),

        // 底部按钮
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // 扫码按钮
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.barcode_viewfinder,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 搜索输入框
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              focusNode: _focusNode,
              placeholder: '扫码添加商品(标准商品)',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              clearButtonMode: OverlayVisibilityMode.editing,
              suffix: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: CupertinoActivityIndicator(),
                    )
                  : null,
              onSubmitted: _search,
              onChanged: (v) {
                if (v.endsWith('\n')) {
                  _search(v.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _InfoRow(
            label: '出库仓库',
            value: _outWarehouse?.displayName ?? '仓库${_draft!.outWarehouseId}',
          ),
          if (_inWarehouse != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              label: '入库仓库',
              value: _inWarehouse!.displayName,
            ),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            label: '制单人',
            value: _creatorName ?? '员工${_draft!.createdBy}',
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final totalCount = _stockingItems.fold<int>(0, (sum, item) {
      return sum + (item.qty ?? 1);
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '调拨清单',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          Text(
            '合计数量: $totalCount',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF007AFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasItems = _stockingItems.isNotEmpty;

    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: CupertinoColors.white,
              onPressed: _cancelStocking,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1),
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '取消备货',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 10),
              disabledColor: CupertinoColors.systemGrey4,
              onPressed: hasItems && !_isSaving ? _completeStocking : null,
              child: _isSaving
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('备货完成'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// 调拨商品备货卡片
class _StockingProductCard extends StatelessWidget {
  final int productId;
  final String productName;
  final TransferProductStocking preProduct;
  final TransferProductStocking? stockedProduct;
  final void Function(int goodsId) onDeleteGoods;
  final int outWarehouseId;

  const _StockingProductCard({
    required this.productId,
    required this.productName,
    required this.preProduct,
    required this.stockedProduct,
    required this.onDeleteGoods,
    required this.outWarehouseId,
  });

  @override
  Widget build(BuildContext context) {
    final isSerialProduct = preProduct.goodsList != null;
    final preQty = preProduct.preTransferQuantity;
    final stockedQty = stockedProduct?.goodsList?.length ?? stockedProduct?.quantity ?? 0;
    final isComplete = stockedQty >= preQty;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '已完成',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF34C759),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 数量信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSerialProduct ? '调拨数量: $preQty' : '调拨数量: $preQty',
                  style: AppText.caption,
                ),
                Text(
                  '备货数量: $stockedQty',
                  style: AppText.caption.copyWith(
                    color: isComplete ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 序列号列表
          if (isSerialProduct) _buildSerialList(),
        ],
      ),
    );
  }

  Widget _buildSerialList() {
    final goodsList = stockedProduct?.goodsList ?? [];

    if (goodsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text(
          '暂无序列号',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      );
    }

    return Column(
      children: goodsList.map((goods) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  goods.serial,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                ),
              ),
              GestureDetector(
                onTap: () => onDeleteGoods(goods.id),
                child: const Text(
                  '删除',
                  style: TextStyle(fontSize: 13, color: Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

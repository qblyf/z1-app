import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 盘库操作页
/// 对应 PWA /pages/path-d/stocktake.tsx
///
/// 流程：选择仓库 → 开始盘库 → 扫码/搜索添加商品 → 填写实盘数量 → 结束盘库
class StocktakePage extends ConsumerStatefulWidget {
  final int stocktakingId;

  const StocktakePage({super.key, required this.stocktakingId});

  @override
  ConsumerState<StocktakePage> createState() => _StocktakePageState();
}

class _StocktakePageState extends ConsumerState<StocktakePage> {
  final StocktakingApi _api = StocktakingApi();

  Stocktaking? _stocktaking;
  StocktakingLog? _log;
  bool _isLoading = true;
  bool _isEnding = false;
  bool _isSubmitting = false;
  int _selectedTab = 1; // 0=调拨在途, 1=未盘库, 2=已盘库, 3=盘盈

  // 盘库产品数据
  List<_StockTakeItem> _pendingItems = []; // 未盘库
  List<_StockTakeItem> _completedItems = []; // 已盘库
  List<_StockTakeItem> _profitItems = []; // 盘盈

  // 搜索
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.stocktakingDetail(id: widget.stocktakingId),
        _api.detail(widget.stocktakingId),
      ]);
      if (!mounted) return;

      final detail = results[0] as Stocktaking?;
      final log = results[1] as StocktakingLog?;

      if (detail != null) {
        _parseStockData(detail);
      }

      if (mounted) {
        setState(() {
          _stocktaking = detail;
          _log = log;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseStockData(Stocktaking detail) {
    // stockSYS: 系统库存（待盘点）
    // stockTake: 实际盘库数据
    // lockSYS: 调拨锁货

    final sysMap = <String, Map<String, dynamic>>{};
    if (detail.stockSYS != null) {
      for (final item in detail.stockSYS!) {
        final map = item as Map<String, dynamic>;
        final key = _makeKey(map);
        sysMap[key] = map;
      }
    }

    // 加载已盘库数据
    final takeMap = <String, Map<String, dynamic>>{};
    if (detail.stockTake != null) {
      for (final item in detail.stockTake!) {
        final map = item as Map<String, dynamic>;
        final key = _makeKey(map);
        takeMap[key] = map;
      }
    }

    // 计算锁货的 key 集合
    final lockKeys = <String>{};
    if (detail.lockSYS != null) {
      for (final item in detail.lockSYS!) {
        final map = item as Map<String, dynamic>;
        lockKeys.add(_makeKey(map));
      }
    }

    // 构建未盘库列表
    final pending = <_StockTakeItem>[];
    final completed = <_StockTakeItem>[];
    final profit = <_StockTakeItem>[];

    for (final entry in sysMap.entries) {
      final sys = entry.value;
      final key = entry.key;
      final take = takeMap[key];

      final item = _StockTakeItem(
        key: key,
        productID: sys['productID'] as int?,
        skuID: sys['skuID'] as int?,
        goodsID: sys['goodsID'] as int?,
        itemID: sys['itemID'] as int?,
        recycleID: sys['recycleID'] as int?,
        productName: sys['productName'] as String? ?? '',
        skuName: sys['skuName'] as String? ?? '',
        goodsName: sys['goodsName'] as String? ?? '',
        serial: sys['serial'] as String?,
        qty: take != null ? (take['qty'] as int? ?? 0) : 0,
        sysQty: _extractQty(sys),
        remarks: take?['remarks'] as String? ?? '',
        isLocked: lockKeys.contains(key),
        isRecycle: sys.containsKey('recycleID'),
      );

      if (take != null && (take['qty'] as int? ?? 0) > 0) {
        if (item.qty > item.sysQty) {
          profit.add(item);
        } else {
          completed.add(item);
        }
      } else {
        pending.add(item);
      }
    }

    // 已盘库中补充锁货记录
    for (final entry in takeMap.entries) {
      final take = entry.value;
      if (!sysMap.containsKey(entry.key)) {
        final item = _StockTakeItem(
          key: entry.key,
          productID: take['productID'] as int?,
          skuID: take['skuID'] as int?,
          goodsID: take['goodsID'] as int?,
          itemID: take['itemID'] as int?,
          recycleID: take['recycleID'] as int?,
          productName: take['productName'] as String? ?? '',
          skuName: take['skuName'] as String? ?? '',
          goodsName: take['goodsName'] as String? ?? '',
          serial: take['serial'] as String?,
          qty: take['qty'] as int? ?? 0,
          sysQty: 0,
          remarks: take['remarks'] as String? ?? '',
          isLocked: false,
          isRecycle: take.containsKey('recycleID'),
        );
        if (item.qty > 0) profit.add(item);
      }
    }

    _pendingItems = pending;
    _completedItems = completed;
    _profitItems = profit;
  }

  String _makeKey(Map<String, dynamic> map) {
    if (map.containsKey('recycleID')) return 'recycle:${map['recycleID']}';
    if (map.containsKey('goodsID')) return 'goods:${map['goodsID']}';
    if (map.containsKey('itemID')) return 'item:${map['itemID']}';
    if (map.containsKey('skuID')) return 'sku:${map['skuID']}';
    return 'product:${map['productID']}';
  }

  int _extractQty(Map<String, dynamic> map) {
    if (map.containsKey('qty')) return (map['qty'] as int?) ?? 0;
    return 1;
  }

  void _updateItemQty(String key, int qty) {
    setState(() {
      for (final list in [_pendingItems, _completedItems, _profitItems]) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].key == key) {
            final item = list[i];
            final updated = item.copyWith(qty: qty);
            list[i] = updated;

            // 重新分类
            if (qty > 0) {
              // 从 pending 移到 completed 或 profit
              if (!_completedItems.any((e) => e.key == key) &&
                  !_profitItems.any((e) => e.key == key)) {
                _pendingItems.removeWhere((e) => e.key == key);
                if (qty > item.sysQty) {
                  if (!_profitItems.any((e) => e.key == key)) _profitItems.add(updated);
                } else {
                  if (!_completedItems.any((e) => e.key == key)) _completedItems.add(updated);
                }
              }
            } else {
              // 从 completed/profit 移回 pending
              _completedItems.removeWhere((e) => e.key == key);
              _profitItems.removeWhere((e) => e.key == key);
              if (!_pendingItems.any((e) => e.key == key)) {
                _pendingItems.add(item.copyWith(qty: 0));
              }
            }
            return;
          }
        }
      }
    });
  }

  void _updateItemRemarks(String key, String remarks) {
    setState(() {
      for (final list in [_pendingItems, _completedItems, _profitItems]) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].key == key) {
            list[i] = list[i].copyWith(remarks: remarks);
            return;
          }
        }
      }
    });
  }

  Future<void> _scanBarcode() async {
    // 简单的条码输入弹窗（实际项目中可使用扫码插件）
    final barcode = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return CupertinoAlertDialog(
          title: const Text('扫码输入'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              placeholder: '请输入条码',
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (barcode == null || barcode.isEmpty) return;
    if (!mounted) return;

    // 调用条码查询接口
    final warehouseId = _stocktaking?.warehouseID;
    if (warehouseId == null) return;

    try {
      final results = await _api.getStockByBarcode(
        warehouseIDs: [warehouseId],
        barcode: barcode,
      );
      if (!mounted) return;

      if (results.isEmpty) {
        _showTip('未找到该条码对应的商品');
        return;
      }

      // 添加到待盘库列表
      for (final item in results) {
        final key = _makeKey(item);
        if (!_pendingItems.any((e) => e.key == key) &&
            !_completedItems.any((e) => e.key == key) &&
            !_profitItems.any((e) => e.key == key)) {
          setState(() {
            _pendingItems.add(_StockTakeItem(
              key: key,
              productID: item['productID'] as int?,
              skuID: item['skuID'] as int?,
              goodsID: item['goodsID'] as int?,
              itemID: item['itemID'] as int?,
              recycleID: item['recycleID'] as int?,
              productName: item['productName'] as String? ?? '',
              skuName: item['skuName'] as String? ?? '',
              goodsName: item['goodsName'] as String? ?? '',
              serial: item['serial'] as String?,
              qty: 0,
              sysQty: _extractQty(item),
              remarks: '',
              isLocked: false,
              isRecycle: item.containsKey('recycleID'),
            ));
          });
        }
        _showTip('找到商品: ${item['productName'] ?? item['goodsName'] ?? ''}');
      }
    } catch (e) {
      if (mounted) _showTip('查询失败: $e');
    }
  }

  Future<void> _submitStocktake() async {
    // 收集所有已盘库数据
    final allItems = [..._completedItems, ..._profitItems];
    if (allItems.isEmpty) {
      _showTip('请先录入至少一件商品的盘点数量');
      return;
    }

    final stockTake = allItems.map((item) {
      final data = <String, dynamic>{
        if (item.productID != null) 'productID': item.productID,
        if (item.skuID != null) 'skuID': item.skuID,
        if (item.goodsID != null) 'goodsID': item.goodsID,
        if (item.itemID != null) 'itemID': item.itemID,
        if (item.recycleID != null) 'recycleID': item.recycleID,
        'qty': item.qty,
        if (item.remarks.isNotEmpty) 'remarks': item.remarks,
      };
      return data;
    }).toList();

    setState(() => _isSubmitting = true);
    try {
      final ok = await _api.take(
        id: widget.stocktakingId,
        stockTake: stockTake,
      );
      if (mounted) {
        if (ok) {
          _showTip('提交成功');
          await _loadData();
        } else {
          _showTip('提交失败');
        }
      }
    } catch (e) {
      if (mounted) _showTip('提交失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _endStocktaking() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('结束盘库'),
        content: Text(
          '确认结束本次盘库操作？\n'
          '未盘库: ${_pendingItems.length} 件\n'
          '已盘库: ${_completedItems.length} 件\n'
          '盘盈: ${_profitItems.length} 件',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认结束'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isEnding = true);
    try {
      final success = await _api.end(widget.stocktakingId);
      if (success && mounted) {
        context.pop();
      } else if (mounted) {
        _showTip('结束盘库失败');
        setState(() => _isEnding = false);
      }
    } catch (_) {
      if (mounted) {
        _showTip('结束盘库失败');
        setState(() => _isEnding = false);
      }
    }
  }

  void _showTip(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_stocktaking != null
            ? '盘库 #${_stocktaking!.id}'
            : _log?.stocktakingLogNumber ?? '盘库'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _scanBarcode,
          child: const Icon(CupertinoIcons.barcode_viewfinder),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _stocktaking == null && _log == null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('加载失败，请重试', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(onPressed: _loadData, child: const Text('重新加载')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final log = _log!;
    final transferLock = _stocktaking?.transferLockStockQuantity ?? 0;

    return Column(
      children: [
        // Tab栏
        Container(
          color: CupertinoColors.white,
          child: Row(
            children: [
              _TabItem(
                label: '调拨在途',
                count: transferLock,
                isActive: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _TabItem(
                label: '未盘库',
                count: _pendingItems.length,
                isActive: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              _TabItem(
                label: '已盘库',
                count: _completedItems.length,
                isActive: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
              _TabItem(
                label: '盘盈',
                count: _profitItems.length,
                isActive: _selectedTab == 3,
                onTap: () => setState(() => _selectedTab = 3),
              ),
            ],
          ),
        ),
        // 盘点信息卡片
        Container(
          margin: const EdgeInsets.all(AppSpacing.md),
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
                      log.stocktakingLogNumber ?? 'NO.${log.stocktakingLogID}',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: log.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(log.status.label,
                        style: TextStyle(fontSize: 12, color: log.status.color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(log.warehouseName ?? '仓库${log.warehouseID}', style: AppText.caption),
                  const SizedBox(width: 16),
                  Icon(CupertinoIcons.calendar, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(_formatTime(log.createdAt), style: AppText.caption),
                ],
              ),
              if (log.totalSkuCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(height: 6, decoration: BoxDecoration(color: CupertinoColors.systemGrey5, borderRadius: BorderRadius.circular(4))),
                            FractionallySizedBox(
                              widthFactor: log.progress.clamp(0.0, 1.0),
                              child: Container(height: 6, decoration: BoxDecoration(color: log.status.color, borderRadius: BorderRadius.circular(4))),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${log.checkedCount}/${log.totalSkuCount}',
                        style: AppText.caption.copyWith(color: log.status.color)),
                  ],
                ),
              ],
              // 备注展示
              if (_stocktaking?.remarks?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.info, size: 14, color: Color(0xFFFF9500)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _stocktaking!.remarks!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8E6000)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // 内容区
        Expanded(
          child: _buildTabContent(),
        ),
        // 底部按钮
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            boxShadow: [BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _isSubmitting ? null : _submitStocktake,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('提交盘点', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                onPressed: _isEnding ? null : _endStocktaking,
                child: _isEnding
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('结束盘库', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    final List<_StockTakeItem> items;
    final String emptyMsg;
    final IconData emptyIcon;

    switch (_selectedTab) {
      case 0:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.cube_box, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 8),
              Text('调拨在途商品', style: AppText.body),
              const SizedBox(height: 4),
              Text('调拨锁货将在此处显示', style: AppText.caption),
            ],
          ),
        );
      case 1:
        items = _pendingItems;
        emptyMsg = '暂无待盘点商品';
        emptyIcon = CupertinoIcons.barcode_viewfinder;
        break;
      case 2:
        items = _completedItems;
        emptyMsg = '暂无已盘点商品';
        emptyIcon = CupertinoIcons.checkmark_circle;
        break;
      case 3:
        items = _profitItems;
        emptyMsg = '暂无盘盈商品';
        emptyIcon = CupertinoIcons.arrow_up_circle;
        break;
      default:
        items = [];
        emptyMsg = '';
        emptyIcon = CupertinoIcons.circle;
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(emptyMsg, style: AppText.body),
            const SizedBox(height: 4),
            if (_selectedTab == 1) ...[
              Text('点击右上角扫码添加商品', style: AppText.caption),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) => _StockTakeCard(
        item: items[index],
        editable: _selectedTab == 1,
        onQtyChanged: (qty) => _updateItemQty(items[index].key, qty),
        onRemarksChanged: (remarks) => _updateItemRemarks(items[index].key, remarks),
      ),
    );
  }
}

/// Tab切换项
class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.white,
                width: 2,
              ),
            ),
          ),
          child: Text(
            '$label${count > 0 ? '($count)' : ''}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? const Color(0xFF0A84FF) : const Color(0xFF636366),
            ),
          ),
        ),
      ),
    );
  }
}

/// 盘库产品项数据
class _StockTakeItem {
  final String key;
  final int? productID;
  final int? skuID;
  final int? goodsID;
  final int? itemID;
  final int? recycleID;
  final String productName;
  final String skuName;
  final String goodsName;
  final String? serial;
  final int qty;
  final int sysQty;
  final String remarks;
  final bool isLocked;
  final bool isRecycle;

  _StockTakeItem({
    required this.key,
    this.productID,
    this.skuID,
    this.goodsID,
    this.itemID,
    this.recycleID,
    required this.productName,
    required this.skuName,
    required this.goodsName,
    this.serial,
    required this.qty,
    required this.sysQty,
    required this.remarks,
    required this.isLocked,
    required this.isRecycle,
  });

  String get displayName {
    if (goodsName.isNotEmpty) return goodsName;
    if (skuName.isNotEmpty) return skuName;
    if (productName.isNotEmpty) return productName;
    return '商品';
  }

  int get variance => qty - sysQty;

  _StockTakeItem copyWith({
    String? key,
    int? productID,
    int? skuID,
    int? goodsID,
    int? itemID,
    int? recycleID,
    String? productName,
    String? skuName,
    String? goodsName,
    String? serial,
    int? qty,
    int? sysQty,
    String? remarks,
    bool? isLocked,
    bool? isRecycle,
  }) {
    return _StockTakeItem(
      key: key ?? this.key,
      productID: productID ?? this.productID,
      skuID: skuID ?? this.skuID,
      goodsID: goodsID ?? this.goodsID,
      itemID: itemID ?? this.itemID,
      recycleID: recycleID ?? this.recycleID,
      productName: productName ?? this.productName,
      skuName: skuName ?? this.skuName,
      goodsName: goodsName ?? this.goodsName,
      serial: serial ?? this.serial,
      qty: qty ?? this.qty,
      sysQty: sysQty ?? this.sysQty,
      remarks: remarks ?? this.remarks,
      isLocked: isLocked ?? this.isLocked,
      isRecycle: isRecycle ?? this.isRecycle,
    );
  }
}

/// 盘库产品卡片
class _StockTakeCard extends StatelessWidget {
  final _StockTakeItem item;
  final bool editable;
  final void Function(int qty) onQtyChanged;
  final void Function(String remarks) onRemarksChanged;

  const _StockTakeCard({
    required this.item,
    required this.editable,
    required this.onQtyChanged,
    required this.onRemarksChanged,
  });

  @override
  Widget build(BuildContext context) {
    final variance = item.variance;
    final varianceColor = variance > 0
        ? const Color(0xFF34C759)
        : variance < 0
            ? const Color(0xFFFF3B30)
            : const Color(0xFF8E8E93);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: item.isLocked
                  ? const Color(0xFFFFF3E0)
                  : item.isRecycle
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF2F2F7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.isLocked) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('调拨锁货', style: TextStyle(fontSize: 10, color: Color(0xFFE65100))),
                  ),
                ],
                if (item.isRecycle) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('回收品', style: TextStyle(fontSize: 10, color: Color(0xFF0A84FF))),
                  ),
                ],
                if (item.serial?.isNotEmpty == true) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item.serial!, style: const TextStyle(fontSize: 10, color: Color(0xFF636366))),
                  ),
                ],
              ],
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 系统库存 / 实盘数量
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        label: '系统库存',
                        value: '${item.sysQty}',
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoChip(
                        label: '实盘数量',
                        value: '${item.qty}',
                        color: item.qty > 0 ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoChip(
                        label: '差异',
                        value: variance > 0 ? '+$variance' : '$variance',
                        color: varianceColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 数量调节按钮
                if (editable) ...[
                  Row(
                    children: [
                      _CountBtn(
                        icon: CupertinoIcons.minus,
                        onTap: item.qty > 0 ? () => onQtyChanged(item.qty - 1) : null,
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.qty}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _CountBtn(
                        icon: CupertinoIcons.plus,
                        onTap: () => onQtyChanged(item.qty + 1),
                      ),
                      SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        minimumSize: const Size(0, 0),
                        onPressed: () => _showQtyInput(context),
                        child: const Icon(CupertinoIcons.pencil, size: 16, color: Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 备注行
                  GestureDetector(
                    onTap: () => _showRemarksDialog(context),
                    behavior: HitTestBehavior.opaque,
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
                              item.remarks.isEmpty ? '点击输入' : item.remarks,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.remarks.isEmpty ? CupertinoColors.tertiaryLabel : CupertinoColors.label,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQtyInput(BuildContext context) {
    final controller = TextEditingController(text: '${item.qty}');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('输入实盘数量'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '实盘数量',
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final qty = int.tryParse(controller.text.trim()) ?? 0;
              onQtyChanged(qty < 0 ? 0 : qty);
              Navigator.pop(ctx);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showRemarksDialog(BuildContext context) {
    final controller = TextEditingController(text: item.remarks);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('备注'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '输入备注（选填）',
            maxLines: 3,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              onRemarksChanged(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

/// 信息标签
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// 数量调节按钮
class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey4,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 20),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';

/// 盘库结果详情页
/// 对应 PWA /pages/path-d/stocktaking-info.tsx
class StocktakingInfoPage extends ConsumerStatefulWidget {
  final int stocktakingId;

  const StocktakingInfoPage({super.key, required this.stocktakingId});

  @override
  ConsumerState<StocktakingInfoPage> createState() => _StocktakingInfoPageState();
}

class _StocktakingInfoPageState extends ConsumerState<StocktakingInfoPage> {
  final StocktakingApi _api = StocktakingApi();

  Stocktaking? _record;
  bool _isLoading = true;
  bool _isReStocking = false;
  int _selectedTab = 0; // 0=未盘库, 1=已盘库

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final record = await _api.stocktakingDetail(id: widget.stocktakingId);
      if (mounted) {
        setState(() {
          _record = record;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reStocktaking() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('补充盘库'),
        content: const Text('确认发起补充盘库？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isReStocking = true);
    try {
      final success = await _api.reStocktaking(id: widget.stocktakingId);
      if (mounted) {
        setState(() => _isReStocking = false);
        if (success) {
          _showToast('补充盘库发起成功');
          // 跳转到盘库操作页
          context.push('/stocktaking/take/${widget.stocktakingId}');
        } else {
          _showToast('补充盘库发起失败');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isReStocking = false);
        _showToast('补充盘库发起失败');
      }
    }
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
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
        middle: Text(_record?.warehouseName ?? '盘库详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _record == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('加载失败', style: AppText.body),
                        CupertinoButton(onPressed: _loadData, child: const Text('重试')),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final record = _record!;
    final stockSYS = record.stockSYS ?? [];
    final stockTake = record.stockTake ?? [];

    // 未盘库 = stockSYS中有但stockTake中没有的
    final stockTakeIds = stockTake.map((e) {
      final map = e as Map<String, dynamic>;
      if (map.containsKey('productID')) return map['productID'];
      if (map.containsKey('goodsID')) return map['goodsID'];
      if (map.containsKey('itemID')) return map['itemID'];
      return null;
    }).whereType<int>().toSet();

    final uncheckedItems = stockSYS.where((e) {
      final map = e as Map<String, dynamic>;
      final id = map['productID'] ?? map['goodsID'] ?? map['itemID'];
      return !stockTakeIds.contains(id);
    }).toList();

    return Column(
      children: [
        // Tab栏
        Container(
          color: CupertinoColors.white,
          child: Row(
            children: [
              _TabItem(
                label: '未盘库',
                count: uncheckedItems.length,
                isActive: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _TabItem(
                label: '已盘库',
                count: stockTake.length,
                isActive: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
        ),
        // 信息卡片
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
                      record.warehouseName ?? '仓库${record.warehouseID}',
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: record.state.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(record.state.label, style: TextStyle(fontSize: 12, color: record.state.color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(record.planName ?? '方案${record.planID}', style: AppText.caption),
                  const SizedBox(width: 12),
                  Icon(CupertinoIcons.clock, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(record.formattedCreatedAt, style: AppText.caption),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(label: '系统库存 ${stockSYS.length}'),
                  const SizedBox(width: 8),
                  _InfoChip(label: '已盘点 ${stockTake.length}', color: const Color(0xFF30D158)),
                  if (uncheckedItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _InfoChip(label: '未盘点 ${uncheckedItems.length}', color: const Color(0xFFFF9500)),
                  ],
                ],
              ),
            ],
          ),
        ),
        // 列表
        Expanded(
          child: _selectedTab == 0
              ? uncheckedItems.isEmpty
                  ? Center(child: Text('全部已盘点', style: AppText.body))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: uncheckedItems.length,
                      itemBuilder: (_, i) => _ProductItem(
                        data: uncheckedItems[i] as Map<String, dynamic>,
                        isChecked: false,
                      ),
                    )
              : stockTake.isEmpty
                  ? Center(child: Text('暂无已盘点记录', style: AppText.body))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: stockTake.length,
                      itemBuilder: (_, i) => _ProductItem(
                        data: stockTake[i] as Map<String, dynamic>,
                        isChecked: true,
                      ),
                    ),
        ),
        // 底部操作
        if (record.isCompleted)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _isReStocking ? null : _reStocktaking,
                child: _isReStocking
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('补充盘库'),
              ),
            ),
          ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.count, required this.isActive, required this.onTap});

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

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _InfoChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color ?? AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isChecked;

  const _ProductItem({required this.data, required this.isChecked});

  String get _productName {
    return data['productName'] as String? ?? data['skuName'] as String? ?? '商品';
  }

  String get _serial {
    return data['serial'] as String? ?? data['imei'] as String? ?? data['sn'] as String? ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.circle,
            size: 20,
            color: isChecked ? const Color(0xFF30D158) : const Color(0xFFFF9500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_productName, style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('SN: $_serial', style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

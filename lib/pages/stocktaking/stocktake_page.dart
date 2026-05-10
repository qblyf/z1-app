import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';

/// 盘库操作页
/// 对应 PWA /pages/path-d/stocktake.tsx
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
  int _selectedTab = 1; // 0=调拨在途, 1=未盘库, 2=已盘库, 3=盘盈

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 并行加载盘库记录详情和日志
      final results = await Future.wait([
        _api.stocktakingDetail(id: widget.stocktakingId),
        _api.detail(widget.stocktakingId),
      ]);
      if (mounted) {
        setState(() {
          _stocktaking = results[0] as Stocktaking?;
          _log = results[1] as StocktakingLog?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _endStocktaking() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('结束盘库'),
        content: const Text('确认结束本次盘库操作？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
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
        _showError('结束盘库失败');
        setState(() => _isEnding = false);
      }
    } catch (_) {
      if (mounted) {
        _showError('结束盘库失败');
        setState(() => _isEnding = false);
      }
    }
  }

  void _showError(String message) {
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
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('加载失败，请重试', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _loadData,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final log = _log!;
    return Column(
      children: [
        // Tab栏
        Container(
          color: CupertinoColors.white,
          child: Row(
            children: [
              _TabItem(
                label: '调拨在途',
                count: 0,
                isActive: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _TabItem(
                label: '未盘库',
                count: log.totalSkuCount - log.checkedCount,
                isActive: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              _TabItem(
                label: '已盘库',
                count: log.checkedCount,
                isActive: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
              _TabItem(
                label: '盘盈',
                count: 0,
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
                    child: Text(
                      log.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: log.status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(log.warehouseName ?? '仓库${log.warehouseID}', style: AppText.caption),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
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
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: log.progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: log.status.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.checkedCount}/${log.totalSkuCount}',
                      style: AppText.caption.copyWith(color: log.status.color),
                    ),
                  ],
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
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _isEnding ? null : _endStocktaking,
                  child: _isEnding
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text(
                          '结束盘库',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.barcode_viewfinder,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTab == 0
                ? '调拨在途商品'
                : _selectedTab == 1
                    ? '待盘点商品'
                    : _selectedTab == 2
                        ? '已盘点商品'
                        : '盘盈商品',
            style: AppText.body,
          ),
          const SizedBox(height: 4),
          Text(
            '请使用扫码设备扫描条码',
            style: AppText.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

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

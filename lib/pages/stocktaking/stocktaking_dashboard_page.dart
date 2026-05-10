import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 盘库结果仪表盘（最新盘库结果查询）
/// 对应 PWA /pages/path-d/stocktaking-dashboard.tsx
class StocktakingDashboardPage extends ConsumerStatefulWidget {
  const StocktakingDashboardPage({super.key});

  @override
  ConsumerState<StocktakingDashboardPage> createState() => _StocktakingDashboardPageState();
}

class _StocktakingDashboardPageState extends ConsumerState<StocktakingDashboardPage> {
  final StocktakingApi _api = StocktakingApi();

  List<Stocktaking> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 查询所有已完成盘库记录（dashboard展示已完成状态）
      final records = await _api.dashboardList(
        states: [StocktakingRecordState.completed.value],
      );

      // 按盘盈数量倒序（参考PWA orderBy outOfStockQuantity desc）
      records.sort((a, b) => (b.outOfStockQuantity ?? 0).compareTo(a.outOfStockQuantity ?? 0));

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('最新盘库结果查询'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loadData,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.cube_box, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('暂无盘库记录', style: AppText.body),
                        const SizedBox(height: 4),
                        Text('请先完成盘库操作', style: AppText.caption),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(onRefresh: _loadData),
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _DashboardCard(
                              record: _records[i],
                              onTap: () => context.push(Routes.stocktakingInfo.replaceFirst(':id', '${_records[i].id}')),
                            ),
                            childCount: _records.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Stocktaking record;
  final VoidCallback onTap;

  const _DashboardCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              record.warehouseName ?? '仓库${record.warehouseID}',
                              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: record.state.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.state.label,
                                style: TextStyle(fontSize: 10, color: record.state.color, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.planName ?? '方案${record.planID}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  if (record.outOfStockQuantity != null && record.outOfStockQuantity! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle, size: 12, color: Color(0xFFFF3B30)),
                          const SizedBox(width: 4),
                          Text(
                            '盘盈${record.outOfStockQuantity}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFFF3B30), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right, size: 18, color: Color(0xFFC7C7CC)),
                ],
              ),
            ),
            // 分隔线
            Container(
              height: 1,
              color: AppColors.background,
            ),
            // 底部统计
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: CupertinoIcons.cube_box,
                    label: '系统库存',
                    value: '${record.stockSYSCount}',
                  ),
                  _StatItem(
                    icon: CupertinoIcons.checkmark_seal,
                    label: '已盘点',
                    value: '${record.stockTakeCount}',
                  ),
                  _StatItem(
                    icon: CupertinoIcons.clock,
                    label: '时间',
                    value: record.formattedCreatedAt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text('$label: ', style: AppText.caption.copyWith(color: AppColors.textTertiary)),
        Text(value, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

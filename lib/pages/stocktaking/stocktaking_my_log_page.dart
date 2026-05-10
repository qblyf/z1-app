import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/stocktaking_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';

/// 我的盘库记录页（最近24小时，我负责的仓库）
/// 对应 PWA /pages/path-d/stocktaking-log-my.tsx
class StocktakingMyLogPage extends ConsumerStatefulWidget {
  const StocktakingMyLogPage({super.key});

  @override
  ConsumerState<StocktakingMyLogPage> createState() => _StocktakingMyLogPageState();
}

class _StocktakingMyLogPageState extends ConsumerState<StocktakingMyLogPage> {
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
      // 1. 获取当前用户负责的仓库盘库任务
      final onDutyList = await _api.getUserOnDutyList();
      if (onDutyList.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. 计算时间范围：当前时间前24小时
      final now = DateTime.now();
      final minTime = now.subtract(const Duration(hours: 24));
      final minTs = minTime.millisecondsSinceEpoch ~/ 1000;
      final maxTs = now.millisecondsSinceEpoch ~/ 1000;

      // 3. 获取对应仓库和方案的盘库记录
      final warehouseIds = onDutyList.map((d) => d.warehouseID).toSet().toList();
      final planIds = onDutyList.map((d) => d.planID).toSet().toList();

      // 查询最近盘库记录
      final records = await _api.dashboardList(
        states: [StocktakingRecordState.inProgress.value, StocktakingRecordState.completed.value],
        warehouseIDs: warehouseIds,
        planIDs: planIds,
      );

      // 过滤24小时内的记录
      final filtered = records.where((r) => r.createdAt >= minTs && r.createdAt <= maxTs).toList();

      if (mounted) {
        setState(() {
          _records = filtered;
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
        middle: const Text('我的盘库记录'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
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
                        Text('最近24小时无盘库记录', style: AppText.body),
                        const SizedBox(height: 4),
                        Text('请在盘库管理中选择仓库开始盘库', style: AppText.caption),
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
                            (context, i) => _RecordCard(
                              record: _records[i],
                              onTap: () => context.push('/stocktaking/take/${_records[i].id}'),
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

class _RecordCard extends StatelessWidget {
  final Stocktaking record;
  final VoidCallback onTap;

  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    '盘库 #${record.id}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: record.state.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.state.label,
                    style: TextStyle(fontSize: 12, color: record.state.color, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('仓库${record.warehouseID}', style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.calendar, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(_formatTime(record.createdAt), style: AppText.caption),
              ],
            ),
            if (record.remarks != null && record.remarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.remarks!,
                style: AppText.caption.copyWith(color: AppColors.textTertiary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

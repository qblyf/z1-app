import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/employee_score_providers.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';

/// 红黑榜/积分排行页面
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  int _orderBy = 0; // 0=红榜(高到低) 1=黑榜(低到高)
  List<ScoreRanking> _rankings = [];
  ScoreStatistics? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(employeeScoreApiProvider);
      final orderBy = _orderBy == 0 ? 'desc' : 'asc';
      final rankings = await api.getScoreRanking(orderBy: orderBy);
      // also fetch stats
      ScoreStatistics? stats;
      try {
        final info = await api.getDepartmentScoreInfo();
        stats = ScoreStatistics.fromJson(info);
      } catch (_) {}
      setState(() {
        _rankings = rankings;
        _stats = stats;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('红黑榜'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 红黑榜切换
            _RankingTabBar(selected: _orderBy, onChanged: (v) {
              setState(() => _orderBy = v);
              _loadData();
            }),

            // 统计数据
            if (_stats != null) _StatsBar(stats: _stats!),

            // 排行列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _rankings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.chart_bar_square, size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 8),
                              Text('暂无排行数据', style: AppText.caption),
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
                                  (_, i) => _RankingCard(ranking: _rankings[i], index: i),
                                  childCount: _rankings.length,
                                ),
                              ),
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

/// 红黑榜切换栏
class _RankingTabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _RankingTabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              label: '红榜',
              icon: CupertinoIcons.star_fill,
              color: const Color(0xFFFF3B30),
              isActive: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: '黑榜',
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              color: const Color(0xFF8E8E93),
              isActive: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? color : AppColors.textTertiary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计栏
class _StatsBar extends StatelessWidget {
  final ScoreStatistics stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: '总积分',
              value: stats.totalScore.toString(),
              color: const Color(0xFF0A84FF),
            ),
          ),
          Container(width: 1, height: 36, color: CupertinoColors.systemGrey5),
          Expanded(
            child: _StatItem(
              label: '已发放',
              value: stats.totalGiven.toString(),
              color: const Color(0xFF30D158),
            ),
          ),
          Container(width: 1, height: 36, color: CupertinoColors.systemGrey5),
          Expanded(
            child: _StatItem(
              label: '剩余',
              value: stats.totalRemaining.toString(),
              color: const Color(0xFFFF9500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

/// 排行卡片
class _RankingCard extends StatelessWidget {
  final ScoreRanking ranking;
  final int index;

  const _RankingCard({required this.ranking, required this.index});

  @override
  Widget build(BuildContext context) {
    final isRed = ranking.isRed;
    final color = ranking.rankColor;
    final bgColor = color.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                ranking.rank.abs().toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 头像
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isRed ? const Color(0xFFFF3B30) : AppColors.textTertiary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (ranking.userName ?? '?').substring(0, 1),
                style: TextStyle(
                  color: isRed ? const Color(0xFFFF3B30) : AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.userName ?? '未知',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (ranking.departmentName != null)
                  Text(ranking.departmentName!, style: AppText.caption),
              ],
            ),
          ),

          // 积分
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isRed ? '+' : ''}${ranking.score}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text('分', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class StorekeeperDataPage extends ConsumerStatefulWidget {
  const StorekeeperDataPage({super.key});

  @override
  ConsumerState<StorekeeperDataPage> createState() => _StorekeeperDataPageState();
}

class _StorekeeperDataPageState extends ConsumerState<StorekeeperDataPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('店长助手'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {},
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 门店数据入口卡片
                    _MenuCard(
                      title: '门店数据',
                      subtitle: '门店排行、目标总览、员工销售',
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      color: const Color(0xFF30D158),
                      onTap: () => context.push('/storekeeper-data/store-ranking'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '目标总览',
                      subtitle: '主营销量、毛利任务进度',
                      icon: CupertinoIcons.flag_fill,
                      color: const Color(0xFFFF9500),
                      onTap: () => context.push('/storekeeper-data/target-glance'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '重点产品',
                      subtitle: '门店主推产品销量排行',
                      icon: CupertinoIcons.star_fill,
                      color: const Color(0xFF5E5CE6),
                      onTap: () => context.push('/storekeeper-data/main-products'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '员工业绩',
                      subtitle: '员工销售数据排行',
                      icon: CupertinoIcons.person_2_fill,
                      color: const Color(0xFFBF5AF2),
                      onTap: () => context.push('/storekeeper-data/employee-ranking'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '资金周转',
                      subtitle: '门店资金周转率统计',
                      icon: CupertinoIcons.money_dollar_circle_fill,
                      color: const Color(0xFF64D2FF),
                      onTap: () => context.push('/storekeeper-data/capital-turnover'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '经营分析',
                      subtitle: '月度经营数据综合分析',
                      icon: CupertinoIcons.chart_pie_fill,
                      color: const Color(0xFFFF6B6B),
                      onTap: () => context.push('/storekeeper-data/analyse-month'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: 'SPU排行',
                      subtitle: 'SPU销售排行榜',
                      icon: CupertinoIcons.arrow_up_right,
                      color: const Color(0xFFFFCC00),
                      onTap: () => context.push('/storekeeper-data/spu-ranking'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '区域对比',
                      subtitle: '大区数据对比分析',
                      icon: CupertinoIcons.arrow_2_squarepath,
                      color: const Color(0xFF00C7BE),
                      onTap: () => context.push('/storekeeper-data/area-compare'),
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      title: '月度经营分析',
                      subtitle: '类目配比与月度销售统计',
                      icon: CupertinoIcons.chart_pie_fill,
                      color: const Color(0xFFFF6B6B),
                      onTap: () => context.push('/storekeeper-data/analyse-month'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.subtitle),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

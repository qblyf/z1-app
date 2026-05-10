import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/stocktaking_api.dart';
import '../../models/stocktaking.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 盘库管理首页（方案网格）
/// 对应 PWA /pages/path-d/stocktaking.tsx
class StocktakingPage extends ConsumerStatefulWidget {
  const StocktakingPage({super.key});

  @override
  ConsumerState<StocktakingPage> createState() => _StocktakingPageState();
}

class _StocktakingPageState extends ConsumerState<StocktakingPage> {
  final StocktakingApi _api = StocktakingApi();
  List<StocktakingPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 只加载可用的方案
      final plans = await _api.planList(states: [StocktakingPlanState.available.value]);
      if (mounted) {
        setState(() {
          _plans = plans;
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
        middle: const Text('盘库管理'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.person_2, size: 22),
              onPressed: () => context.push(Routes.stocktakingDeliveryReceipt),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc_text),
              onPressed: () => context.push(Routes.stocktakingLogList),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _plans.isEmpty
                ? _buildEmptyState()
                : _buildPlanGrid(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.cube_box, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('暂无可用盘库方案', style: AppText.body),
          const SizedBox(height: 8),
          Text('请联系管理员配置', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildPlanGrid() {
    // 4列网格，参考PWA chunk(planList, 4)
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PlanCard(
                plan: _plans[i],
                onTap: () => context.push('/stocktaking/plan/${_plans[i].id}/warehouses'),
              ),
              childCount: _plans.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final StocktakingPlan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconUrl = plan.icon;
    // 根据方案产品目标确定颜色
    final targetColors = {
      1: const Color(0xFF0A84FF), // 仅标准
      2: const Color(0xFFBF5AF2), // 仅非标准
      3: const Color(0xFF30D158), // 标准与非标准
      4: const Color(0xFFFF9500), // 掌上回收
    };
    final color = targetColors[plan.productTarget.value] ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: iconUrl != null && iconUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: iconUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildIconPlaceholder(color),
                      errorWidget: (_, __, ___) => _buildIconPlaceholder(color),
                    )
                  : _buildIconPlaceholder(color),
            ),
            const SizedBox(height: 10),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                plan.title,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // 目标标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plan.productTargetLabel,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(Color color) {
    return Center(
      child: Icon(
        CupertinoIcons.cube_box_fill,
        size: 28,
        color: color,
      ),
    );
  }
}

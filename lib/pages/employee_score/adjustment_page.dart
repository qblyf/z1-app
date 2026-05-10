import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_score_providers.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 员工积分调整首页
class EmployeeScoreAdjustmentPage extends ConsumerWidget {
  const EmployeeScoreAdjustmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(currentUserScoreProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('积分管理'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.chart_bar),
          onPressed: () => context.push('/employee-score/ranking'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 积分余额卡片
              scoreAsync.when(
                data: (score) => _ScoreBalanceCard(score: score),
                loading: () => _ScoreBalanceCard.loading(),
                error: (_, __) => _ScoreBalanceCard.error(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 功能入口
              Text('功能菜单', style: AppText.label),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _MenuCard(
                      icon: CupertinoIcons.arrow_up_circle,
                      label: '积分发放',
                      color: AppColors.success,
                      onTap: () => context.push('/employee-score/distribution'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MenuCard(
                      icon: CupertinoIcons.arrow_down_circle,
                      label: '积分扣减',
                      color: AppColors.error,
                      onTap: () => context.push('/employee-score/management'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _MenuCard(
                      icon: CupertinoIcons.doc_text,
                      label: '积分申请',
                      color: AppColors.primary,
                      onTap: () => context.push('/employee-score/apply'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MenuCard(
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      label: '积分排行',
                      color: AppColors.warning,
                      onTap: () => context.push('/employee-score/ranking'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // 奖惩记录
              Text('奖惩记录', style: AppText.label),
              const SizedBox(height: AppSpacing.md),

              _MenuCard(
                icon: CupertinoIcons.exclamationmark_shield,
                label: '奖惩明细',
                color: AppColors.accent,
                onTap: () => context.push('/employee-score/reward-punishment-details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBalanceCard extends StatelessWidget {
  final CurrentUserScore? score;

  const _ScoreBalanceCard({this.score});

  factory _ScoreBalanceCard.loading() {
    return _ScoreBalanceCard(
      score: null,
    );
  }

  factory _ScoreBalanceCard.error() {
    return _ScoreBalanceCard(
      score: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.star_fill,
                color: CupertinoColors.white,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '我的积分',
                style: AppText.body.copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            score != null ? '${score!.getScores}' : '--',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ScoreItem(label: '已发放', value: score?.giveOutScores.toString() ?? '--'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

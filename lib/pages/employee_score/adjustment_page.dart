import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_score_providers.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';

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
                      color: const Color(0xFF30D158),
                      onTap: () => context.push('/employee-score/distribution'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MenuCard(
                      icon: CupertinoIcons.doc_text,
                      label: '申报管理',
                      color: const Color(0xFF0A84FF),
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
                      icon: CupertinoIcons.star,
                      label: '积分申报',
                      color: const Color(0xFFFF9500),
                      onTap: () => context.push('/employee-score/apply'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MenuCard(
                      icon: CupertinoIcons.chart_bar_square,
                      label: '红黑榜',
                      color: const Color(0xFFBF5AF2),
                      onTap: () => context.push('/employee-score/ranking'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // 近期发放记录
              Text('近期发放记录', style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              _RecentGiveLogSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 积分余额卡片
class _ScoreBalanceCard extends StatelessWidget {
  final CurrentUserScore? score;

  const _ScoreBalanceCard({this.score});

  factory _ScoreBalanceCard.loading() {
    return _ScoreBalanceCard();
  }

  factory _ScoreBalanceCard.error() {
    return const _ScoreBalanceCard();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.star_fill,
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '我的积分余额',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score?.getScores ?? '-'}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '可发放积分',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: CupertinoColors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${score?.giveOutScores ?? '-'}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '已发放积分',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 功能菜单卡片
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 近期发放记录
class _RecentGiveLogSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(employeeScoreApiProvider);

    return FutureBuilder<List<ScoreGiveLog>>(
      future: api.getGiveLogList(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: const Center(child: CupertinoActivityIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    color: AppColors.textTertiary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text('暂无发放记录', style: AppText.caption),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              ...snapshot.data!.map((log) => _GiveLogItem(log: log)),
            ],
          ),
        );
      },
    );
  }
}

class _GiveLogItem extends StatelessWidget {
  final ScoreGiveLog log;

  const _GiveLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF30D158).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                log.employeeName?.substring(0, 1) ?? '?',
                style: TextStyle(
                  color: const Color(0xFF30D158),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.employeeName ?? '未知员工',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${log.className ?? '积分'} · ${_formatTime(log.givenAt)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Text(
            '+${log.score}',
            style: TextStyle(
              color: const Color(0xFF30D158),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

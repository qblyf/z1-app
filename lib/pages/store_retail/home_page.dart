import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../api/member_api.dart';
import '../../models/user.dart';
import '../../models/store_retail.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 门店零售会员首页 Provider
final storeRetailMemberProvider =
    FutureProvider.family<Member, int>((ref, userIdent) async {
  final api = MemberApi();
  return api.getByIdent(userIdent);
});

/// 会员等级 Provider
final memberLevelListProvider = FutureProvider<List<MemberLevel>>((ref) async {
  final api = StoreRetailApi();
  return api.getMemberLevelList();
});

/// 会员零售订单数量
final memberRetailCountProvider =
    FutureProvider.family<Map<String, int>, int>((ref, userIdent) async {
  final api = StoreRetailApi();
  try {
    final orders = await api.getAllowAssociatedOrderList(customer: userIdent);
    // 统计各状态数量
    int pending = 0, completed = 0, total = orders.length;
    for (final o in orders) {
      final status = o['status'] as int? ?? 0;
      if (status < 3) {
        pending++;
      } else {
        completed++;
      }
    }
    return {'pending': pending, 'completed': completed, 'total': total};
  } catch (_) {
    return {'pending': 0, 'completed': 0, 'total': 0};
  }
});

/// 会员首页
class StoreRetailHomePage extends ConsumerWidget {
  final int userIdent;

  const StoreRetailHomePage({super.key, required this.userIdent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(storeRetailMemberProvider(userIdent));
    final levelAsync = ref.watch(memberLevelListProvider);
    final countAsync = ref.watch(memberRetailCountProvider(userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('会员服务'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.pencil),
          onPressed: () => context.push('/store-retail/member-info/$userIdent'),
        ),
      ),
      child: memberAsync.when(
        data: (member) => _buildContent(context, member, levelAsync, countAsync),
        loading: () => const LoadingWidget(message: '加载会员信息...'),
        error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Member member,
    AsyncValue<List<MemberLevel>> levelAsync,
    AsyncValue<Map<String, int>> countAsync,
  ) {
    final level = levelAsync.whenOrNull(data: (levels) {
          return MemberLevel.fromExperience(member.experience);
        }) ??
        MemberLevel.fromExperience(member.experience);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 会员卡片
          _MemberCard(member: member, level: level),

          const SizedBox(height: AppSpacing.md),

          // 快捷操作
          _QuickActions(userIdent: userIdent, member: member),

          const SizedBox(height: AppSpacing.md),

          // 零售订单统计
          _OrderStatsCard(
            userIdent: userIdent,
            countAsync: countAsync,
          ),

          const SizedBox(height: AppSpacing.md),

          // 会员详情入口
          _InfoSection(member: member),
        ],
      ),
    );
  }
}

/// 会员卡片
class _MemberCard extends StatelessWidget {
  final Member member;
  final MemberLevel level;

  const _MemberCard({required this.member, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            level.color,
            level.color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 头像
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: member.wxAcatar != null && member.wxAcatar!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          member.wxAcatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                        ),
                      )
                    : _buildAvatarFallback(),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.realName ?? '匿名顾客',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            level.name,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.mobilePhone ?? '',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // 积分
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.coin}',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '积分',
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '经验值',
                  value: '${member.experience}',
                ),
                _buildDivider(),
                _StatItem(
                  label: '等级',
                  value: level.name,
                ),
                _buildDivider(),
                _StatItem(
                  label: '注册时间',
                  value: _formatTime(member.joinTime),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Icon(
        CupertinoIcons.person_fill,
        size: 32,
        color: CupertinoColors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: CupertinoColors.white.withValues(alpha: 0.3),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month}/${dt.day}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// 快捷操作
class _QuickActions extends StatelessWidget {
  final int userIdent;
  final Member member;

  const _QuickActions({required this.userIdent, required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('快捷操作', style: AppText.subtitle),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.bag,
                label: '零售单',
                color: AppColors.primary,
                onTap: () => context.push('/store-retail/order/$userIdent'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.arrow_counterclockwise,
                label: '退货退款',
                color: const Color(0xFFFF9500),
                onTap: () => context.push('/store-retail/returns/$userIdent'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.ticket,
                label: '卡包',
                color: const Color(0xFF30D158),
                onTap: () => context.push('/store-retail/coupons/$userIdent'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.doc_text,
                label: '历史订单',
                color: const Color(0xFF5856D6),
                onTap: () => context.push('/store-retail/orders/$userIdent'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.tag,
                label: '标签管理',
                color: const Color(0xFFFF2D55),
                onTap: () => context.push(
                  '/store-retail/labels/$userIdent?name=${Uri.encodeComponent(member.realName ?? '')}',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.chart_bar,
                label: '销售偏好',
                color: const Color(0xFF5E5CE6),
                onTap: () => context.push(
                  '/store-retail/preference/$userIdent?name=${Uri.encodeComponent(member.realName ?? '')}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.cube_box,
                label: '回收订单',
                color: const Color(0xFF00C7BE),
                onTap: () => context.push('/store-retail/recycle-orders'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionCard(
                icon: CupertinoIcons.layers,
                label: '展位管理',
                color: const Color(0xFF5856D6),
                onTap: () => context.push('/store-management/booth'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            const SizedBox(width: AppSpacing.md),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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

/// 订单统计卡片
class _OrderStatsCard extends StatelessWidget {
  final int userIdent;
  final AsyncValue<Map<String, int>> countAsync;

  const _OrderStatsCard({required this.userIdent, required this.countAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('零售订单', style: AppText.subtitle),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                child: Text(
                  '查看全部',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => context.push('/store-retail/orders/$userIdent'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          countAsync.when(
            data: (counts) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OrderStatItem(label: '进行中', value: counts['pending'] ?? 0, color: const Color(0xFFFF9500)),
                _OrderStatItem(label: '已完成', value: counts['completed'] ?? 0, color: const Color(0xFF30D158)),
                _OrderStatItem(label: '共 ${counts['total'] ?? 0} 单', value: null, color: AppColors.textSecondary),
              ],
            ),
            loading: () => const Center(
              child: CupertinoActivityIndicator(),
            ),
            error: (_, __) => Text('加载失败', style: AppText.caption),
          ),
        ],
      ),
    );
  }
}

class _OrderStatItem extends StatelessWidget {
  final String label;
  final int? value;
  final Color color;

  const _OrderStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (value != null)
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          label,
          style: AppText.caption.copyWith(color: color),
        ),
      ],
    );
  }
}

/// 会员信息入口
class _InfoSection extends StatelessWidget {
  final Member member;

  const _InfoSection({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: CupertinoIcons.phone,
            label: '手机号',
            value: member.mobilePhone ?? '-',
          ),
          _divider(),
          _InfoRow(
            icon: CupertinoIcons.person,
            label: '性别',
            value: member.gender.label,
          ),
          _divider(),
          _InfoRow(
            icon: CupertinoIcons.envelope,
            label: '邮箱',
            value: member.email ?? '-',
          ),
          _divider(),
          _InfoRow(
            icon: CupertinoIcons.gift,
            label: '运营商',
            value: member.operator ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 52),
        color: AppColors.divider,
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: AppText.body),
        ],
      ),
    );
  }
}

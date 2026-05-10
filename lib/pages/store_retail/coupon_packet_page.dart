import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 会员卡包页 Provider
final memberCouponListProvider =
    FutureProvider.family<List<Coupon>, int>((ref, userIdent) async {
  final api = StoreRetailApi();
  return api.getMemberAvailableCoupons(userIdent: userIdent);
});

/// 会员卡包页
class CouponPacketPage extends ConsumerStatefulWidget {
  final int userIdent;

  const CouponPacketPage({super.key, required this.userIdent});

  @override
  ConsumerState<CouponPacketPage> createState() => _CouponPacketPageState();
}

class _CouponPacketPageState extends ConsumerState<CouponPacketPage> {
  int _filterState = 2; // 2=可用, 1=已失效, 3=已使用

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(memberCouponListProvider(widget.userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的卡包'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 状态筛选
            _FilterChips(selected: _filterState, onChanged: (v) {
              setState(() => _filterState = v);
              ref.invalidate(memberCouponListProvider(widget.userIdent));
            }),

            // 券列表
            Expanded(
              child: couponsAsync.when(
                data: (coupons) {
                  final filtered = coupons.where((c) => c.state == _filterState).toList();
                  if (filtered.isEmpty) {
                    return EmptyWidget(
                      message: _emptyMessage,
                      icon: CupertinoIcons.ticket,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _CouponCard(coupon: filtered[index]);
                    },
                  );
                },
                loading: () => const LoadingWidget(message: '加载卡包...'),
                error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _emptyMessage {
    switch (_filterState) {
      case 2: return '暂无可用优惠券';
      case 1: return '暂无失效优惠券';
      case 3: return '暂无已使用优惠券';
      default: return '暂无优惠券';
    }
  }
}

class _FilterChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (2, '可用'),
      (3, '已使用'),
      (1, '已失效'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: items.map((item) {
          final isActive = selected == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: EdgeInsets.only(right: item.$1 != 1 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isActive ? AppShadows.card : null,
                ),
                child: Center(
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      color: isActive ? CupertinoColors.white : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final isAvailable = coupon.state == 2;
    final accentColor = _getColor(coupon.type);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // 左侧金额区
          Container(
            width: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  coupon.formattedAmount,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  coupon.typeLabel,
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 右侧信息区
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          coupon.title,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? null : AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(coupon.state).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          coupon.stateLabel,
                          style: TextStyle(
                            color: _getStatusColor(coupon.state),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (coupon.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      coupon.description!,
                      style: AppText.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (coupon.minOrderAmount != null && coupon.minOrderAmount! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '满${(coupon.minOrderAmount! / 100).toStringAsFixed(0)}元可用',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(int type) {
    switch (type) {
      case 1: return const Color(0xFFFF6B6B); // 代金券
      case 2: return AppColors.primary; // 优惠券
      case 3: return const Color(0xFF5856D6); // 兑换券
      default: return AppColors.primary;
    }
  }

  Color _getStatusColor(int state) {
    switch (state) {
      case 2: return AppColors.accent;
      case 3: return AppColors.textTertiary;
      case 1: return CupertinoColors.destructiveRed;
      default: return AppColors.textSecondary;
    }
  }
}

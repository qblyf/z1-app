import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../models/order.dart';
import '../../models/coupon.dart';
import '../../api/member_api.dart';
import '../../api/order_api.dart';
import '../../api/coupon_api.dart';
import '../../api/member_level_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 会员详情页面
class MemberDetailPage extends ConsumerStatefulWidget {
  final int userIdent;

  const MemberDetailPage({super.key, required this.userIdent});

  @override
  ConsumerState<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends ConsumerState<MemberDetailPage> {
  Member? _member;
  List<Order> _orders = [];
  List<Coupon> _coupons = [];
  MemberLevel? _memberLevel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final memberApi = MemberApi();
      final orderApi = OrderApi();
      final couponApi = CouponApi();
      final levelApi = MemberLevelApi();

      final results = await Future.wait([
        memberApi.getByIdent(widget.userIdent),
        orderApi.getByUserAndGenre(userIdent: widget.userIdent),
        couponApi.getMemberCoupons(
          userIdents: [widget.userIdent],
          state: 2,
        ),
        levelApi.getList(),
      ]);

      final member = results[0] as Member;
      final orders = results[1] as List<Order>;
      final coupons = results[2] as List<Coupon>;
      final levels = results[3] as List<MemberLevel>;

      MemberLevel? level;
      for (final l in levels) {
        if (member.experience >= l.minExperience &&
            member.experience <= l.maxExperience) {
          level = l;
          break;
        }
      }

      setState(() {
        _member = member;
        _orders = orders;
        _coupons = coupons;
        _memberLevel = level;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('会员详情'),
        ),
        child: const LoadingWidget(message: '加载中...'),
      );
    }

    if (_error != null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('会员详情'),
        ),
        child: AppErrorWidget(
          message: _error!,
          onRetry: _loadData,
        ),
      );
    }

    if (_member == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('会员详情'),
        ),
        child: const AppErrorWidget(message: '未找到会员信息'),
      );
    }

    final member = _member!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('会员详情'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.pencil),
          onPressed: () {},
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _loadData),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // 会员信息卡片
                  _MemberInfoCard(member: member, memberLevel: _memberLevel),

                  // 基本信息
                  _buildSection('基本信息', children: [
                    _buildRow('手机号', member.mobilePhone ?? '-'),
                    _buildRow('性别', member.gender.label),
                    _buildRow('生日', member.birthDay ?? '-'),
                    _buildRow('邮箱', member.email ?? '-'),
                  ]),

                  // 会员等级
                  _buildSection('会员等级', children: [
                    _buildRow('等级', 'Lv.${member.grade} ${_memberLevel?.name ?? ''}'),
                    _buildRow('经验值', member.experience.toString()),
                    _buildRow('积分', member.coin.toString()),
                  ]),

                  // 购买偏好
                  _buildSection('购买偏好', children: [
                    _buildRow(
                      '上次购物',
                      member.lastBuyAt != null
                          ? DateTime.fromMillisecondsSinceEpoch(member.lastBuyAt! * 1000)
                              .toString()
                              .substring(0, 10)
                          : '从未购买',
                    ),
                    _buildActionRow(
                      '会员标签',
                      CupertinoIcons.tag,
                      () => context.push(
                        '/store-retail/labels/${widget.userIdent}?name=${Uri.encodeComponent(member.realName ?? '')}',
                      ),
                    ),
                    _buildActionRow(
                      '销售偏好',
                      CupertinoIcons.chart_bar,
                      () => context.push(
                        '/store-retail/preference/${widget.userIdent}?name=${Uri.encodeComponent(member.realName ?? '')}',
                      ),
                    ),
                  ]),

                  // 会员卡券
                  if (_coupons.isNotEmpty) ...[
                    _buildSection(
                      '可用卡券',
                      trailing: Text(
                        '共 ${_coupons.length} 张',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                      child: SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _coupons.length,
                          itemBuilder: (context, index) {
                            return _CouponCard(coupon: _coupons[index]);
                          },
                        ),
                      ),
                    ),
                  ],

                  // 订单记录
                  _buildSection(
                    '订单记录',
                    trailing: Text(
                      '共 ${_orders.length} 笔',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    child: _orders.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('暂无订单记录'),
                          )
                        : Column(
                            children: _orders.take(3).map((order) {
                              return _OrderItem(order: order);
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // 操作按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: CupertinoColors.systemGrey5.resolveFrom(context),
                            onPressed: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('提示'),
                                  content: const Text('回收加单功能开发中...'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('确定'),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              '回收加单',
                              style: TextStyle(color: CupertinoColors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('提示'),
                                  content: const Text('销售加单功能开发中...'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('确定'),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('销售加单'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title, {
    List<Widget>? children,
    Widget? trailing,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
        ),
        if (children != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(children: children),
          ),
        if (child != null) child,
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label, IconData icon, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: CupertinoColors.secondaryLabel)),
              ],
            ),
            Row(
              children: [
                Text('查看详情', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberInfoCard extends StatelessWidget {
  final Member member;
  final MemberLevel? memberLevel;

  const _MemberInfoCard({required this.member, this.memberLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.activeBlue,
            CupertinoColors.activeBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(36),
            ),
            child: member.wxAcatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.network(
                      member.wxAcatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          (member.realName?.isNotEmpty == true)
                              ? member.realName!.substring(0, 1)
                              : 'U',
                          style: const TextStyle(
                              fontSize: 28, color: CupertinoColors.activeBlue),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                    (member.realName?.isNotEmpty == true)
                        ? member.realName!.substring(0, 1)
                        : 'U',
                    style: const TextStyle(
                        fontSize: 28, color: CupertinoColors.activeBlue),
                  )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.realName ?? '未知',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      member.isSubscribed
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.question_circle,
                      color: CupertinoColors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      member.isSubscribed ? '已关注公众号' : '未关注公众号',
                      style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LevelBadge(
                      level: member.grade,
                      levelName: memberLevel?.levelIcon ?? '普通',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '积分 ${member.coin}',
                        style: const TextStyle(
                            color: CupertinoColors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final String levelName;

  const _LevelBadge({required this.level, required this.levelName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.star_fill,
              color: CupertinoColors.systemYellow, size: 16),
          const SizedBox(width: 4),
          Text(
            levelName,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.activeOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.activeOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            coupon.formattedAmount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            coupon.title,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            coupon.typeLabel,
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final Order order;

  const _OrderItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  order.genreLabel,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(amount: order.totalAmount, fontSize: 14),
              const SizedBox(height: 4),
              StatusBadge(
                label: order.statusLabel,
                color: _getStatusColor(order.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return CupertinoColors.activeOrange;
      case 2:
        return CupertinoColors.activeBlue;
      case 3:
        return CupertinoColors.systemPurple;
      case 4:
        return CupertinoColors.activeGreen;
      case 5:
        return CupertinoColors.systemGrey;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

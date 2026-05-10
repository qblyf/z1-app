import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/calendar_provider.dart';
import '../api/approval_api.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';

/// 待审批数量
final pendingApprovalCountProvider = FutureProvider<int>((ref) async {
  final api = ApprovalApi();
  final pending = await api.getPending();
  return pending.length;
});

/// 待处理订单数量
final pendingOrderCountProvider = FutureProvider<int>((ref) async {
  return 0; // 需要后端提供计数接口
});

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // token 检查由 router redirect 处理，这里不需要额外操作
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF5E5CE6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Z',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '掌上高远',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppShadows.card,
            ),
            child: const Icon(
              CupertinoIcons.bell,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          onPressed: () {
            context.push(Routes.noticeCenter);
          },
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(currentUserProvider);
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户信息卡片
                    userAsync.when(
                      data: (user) => _UserInfoCard(user: user),
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CupertinoActivityIndicator()),
                      ),
                      error: (e, st) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.systemRed)),
                            const SizedBox(height: 8),
                            CupertinoButton(
                              child: const Text('点击重新登录'),
                              onPressed: () => context.go(Routes.login),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 快捷功能标题
                    _SectionHeader(title: '快捷功能'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // 快捷功能网格（只显示前6项，剩余通过"更多功能"访问）
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => _buildQuickAction(context, index),
                ),
              ),
            ),
            // 更多功能按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => _showAllFeaturesSheet(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '更多功能（共${_quickActions.length}个）',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 待办事项
                    _SectionHeader(title: '待办事项'),
                    const SizedBox(height: 12),
                    _TodoList(isAuthenticated: userAsync.value != null),
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

class _UserInfoCard extends StatelessWidget {
  final Member? user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          UserAvatar(
            name: user?.realName,
            avatarUrl: user?.wxAcatar,
            size: 60,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.realName ?? '未登录',
                  style: AppText.subtitle,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.phone,
                      size: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user?.mobilePhone ?? '',
                      style: AppText.caption.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              CupertinoIcons.barcode_viewfinder,
              color: AppColors.accent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷功能数据
final _quickActions = <_QuickActionDef>[
  _QuickActionDef(CupertinoIcons.person_2, '会员管理', AppColors.primary, Routes.memberManagement, null),
  _QuickActionDef(CupertinoIcons.person_2_fill, '专属导购', const Color(0xFF5E5CE6), Routes.exclusiveShoppingGuideMyCustomer, null),
  _QuickActionDef(CupertinoIcons.cube_box, '库存分配', AppColors.accent, Routes.stockDistribution, null),
  _QuickActionDef(CupertinoIcons.calendar, '我的行事历', const Color(0xFFFF9F0A), Routes.calendar, null),
  _QuickActionDef(CupertinoIcons.bag, '商城订单', const Color(0xFFBF5AF2), Routes.mallOrderList, null),
  _QuickActionDef(CupertinoIcons.bolt_fill, '秒杀订单', const Color(0xFFFF3B30), Routes.flashSaleOrderList, 'NEW'),
  _QuickActionDef(CupertinoIcons.time, '预订订单', const Color(0xFF5856D6), Routes.preSaleOrderList, 'NEW'),
  _QuickActionDef(CupertinoIcons.chart_bar, '销售数据', const Color(0xFF64D2FF), Routes.salespersonData, null),
  _QuickActionDef(CupertinoIcons.doc_text, '审批中心', AppColors.error, Routes.approvalCenter, null),
  _QuickActionDef(CupertinoIcons.cart, '门店零售', const Color(0xFFFF6B6B), Routes.storeRetailEntry, 'HOT'),
  _QuickActionDef(CupertinoIcons.star_fill, '员工积分', const Color(0xFFFF9500), Routes.employeeScore, null),
  _QuickActionDef(CupertinoIcons.doc_text_fill, '收银日报', const Color(0xFF5E5CE6), Routes.cashierDailyReportList, null),
  _QuickActionDef(CupertinoIcons.cube_box, '采购订单', const Color(0xFF30D158), Routes.purchaseOrderList, null),
  _QuickActionDef(CupertinoIcons.arrow_right_arrow_left, '调拨单', const Color(0xFFBF5AF2), Routes.transferOrderEntry, null),
  _QuickActionDef(CupertinoIcons.doc_text, '我的发票', const Color(0xFFFF9F0A), Routes.myInvoiceList, null),
  _QuickActionDef(CupertinoIcons.doc_text_fill, '发票助手', const Color(0xFF5856D6), Routes.invoiceAssistantTaxIdQuery, null),
  _QuickActionDef(CupertinoIcons.cube_box_fill, '库存盘点', const Color(0xFF64D2FF), Routes.stocktakingPlan, null),
  _QuickActionDef(CupertinoIcons.map, '门店巡店', const Color(0xFF30D158), Routes.storeInspectionList, null),
  _QuickActionDef(CupertinoIcons.tray, '报货单', const Color(0xFFFF6B6B), Routes.goodsRequestList, null),
  _QuickActionDef(CupertinoIcons.list_bullet, '岗位任务', const Color(0xFFBF5AF2), Routes.taskManagement, null),
  _QuickActionDef(CupertinoIcons.person_2_fill, '客流统计', const Color(0xFFFF9500), Routes.passengerFlowList, null),
  _QuickActionDef(CupertinoIcons.money_dollar_circle, '差异调整', const Color(0xFF30D158), Routes.priceDifferenceList, null),
  _QuickActionDef(CupertinoIcons.chart_bar_alt_fill, '销售查询', const Color(0xFFFF3B30), Routes.salesList, null),
  _QuickActionDef(CupertinoIcons.arrow_right_arrow_left, '标品调拨', const Color(0xFF5E5CE6), Routes.standardTransferList, null),
  _QuickActionDef(CupertinoIcons.tag, '调价单', const Color(0xFF30D158), Routes.priceAdjustmentList, null),
  _QuickActionDef(CupertinoIcons.chart_bar_square, '店长助手', const Color(0xFFFF9500), Routes.storekeeperData, null),
  _QuickActionDef(CupertinoIcons.tickets, '我的卡券', const Color(0xFFFF3B30), Routes.couponList, null),
  _QuickActionDef(CupertinoIcons.money_dollar_circle_fill, '财务支出', const Color(0xFF5E5CE6), Routes.financialExpenseList, null),
  _QuickActionDef(CupertinoIcons.cube_box_fill, '库存价格', const Color(0xFF64D2FF), Routes.inventoryPriceList, null),
  _QuickActionDef(CupertinoIcons.wrench, '维修单', const Color(0xFFFF6B6B), Routes.repairOrderList, null),
  _QuickActionDef(CupertinoIcons.calendar_badge_plus, '国补预约', const Color(0xFF30D158), Routes.appointmentBookingList, null),
  _QuickActionDef(CupertinoIcons.bell_fill, '通知中心', const Color(0xFFFF9500), Routes.noticeCenter, null),
  _QuickActionDef(CupertinoIcons.doc_on_doc, '会计凭证', const Color(0xFFBF5AF2), Routes.accountingVoucherList, null),
  _QuickActionDef(CupertinoIcons.gift, '积分兑换', const Color(0xFF30D158), Routes.pointsRedeemOrderList, null),
  _QuickActionDef(CupertinoIcons.layers, '展位管理', const Color(0xFF5856D6), Routes.boothList, null),
  _QuickActionDef(CupertinoIcons.gift_fill, '客户生日', const Color(0xFFFF9500), Routes.customerBirthday, null),
  _QuickActionDef(CupertinoIcons.share_up, '商城活动', const Color(0xFF5E5CE6), Routes.mallActivity, null),
  _QuickActionDef(CupertinoIcons.doc_text, '盘库结果查询', const Color(0xFF30D158), Routes.stocktakingLogList, null),
  _QuickActionDef(CupertinoIcons.chart_bar_square, '最新盘库结果', const Color(0xFF64D2FF), Routes.stocktakingDashboard, null),
  _QuickActionDef(CupertinoIcons.person_2_fill, '盘库交接班', const Color(0xFFFF9500), Routes.stocktakingDeliveryReceipt, null),
  _QuickActionDef(CupertinoIcons.tag_fill, '商品报价单', const Color(0xFFFF2D55), Routes.productQuotation, null),
  _QuickActionDef(CupertinoIcons.barcode_viewfinder, '序列号搜索', const Color(0xFF30D158), Routes.serialSearch, null),
  _QuickActionDef(CupertinoIcons.doc_on_doc, '支付附件', const Color(0xFFFF9500), Routes.paymentRecordAttachments, null),
  _QuickActionDef(CupertinoIcons.doc_text_fill, '调拨草稿', const Color(0xFFBF5AF2), Routes.standardTransferDraft, null),
  _QuickActionDef(CupertinoIcons.person_2, '抄送我的', const Color(0xFF64D2FF), Routes.calendarSendList, null),
  _QuickActionDef(CupertinoIcons.checkmark_shield, '待验收', const Color(0xFFFF9F0A), Routes.calendarAllowCheckList, null),
  _QuickActionDef(CupertinoIcons.clock, '已过期', const Color(0xFFFF3B30), Routes.calendarExpiredList, null),
];

Widget _buildQuickAction(BuildContext context, int index) {
  final def = _quickActions[index];
  return QuickActionCard(
    icon: def.icon,
    label: def.label,
    color: def.color,
    badge: def.badge,
    onTap: () {
      if (def.isPush) {
        context.push(def.route);
      } else {
        context.go(def.route);
      }
    },
  );
}

/// 显示所有快捷功能面板
void _showAllFeaturesSheet(BuildContext context) {
  showCupertinoModalPopup(
    context: context,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.85,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 顶部拖动条和标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '全部功能',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_quickActions.length}个',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 28,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(ctx),
                  ),
                ),
              ],
            ),
          ),
          // 功能网格（可滚动）
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _quickActions.length,
              itemBuilder: (context, index) {
                final def = _quickActions[index];
                return QuickActionCard(
                  icon: def.icon,
                  label: def.label,
                  color: def.color,
                  badge: def.badge,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (def.isPush) {
                      context.push(def.route);
                    } else {
                      context.go(def.route);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuickActionDef {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final String? badge;
  final bool isPush;

  const _QuickActionDef(
    this.icon,
    this.label,
    this.color,
    this.route,
    this.badge, {
    this.isPush = false,
  });
}

class _TodoList extends ConsumerWidget {
  final bool isAuthenticated;

  const _TodoList({required this.isAuthenticated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只在已认证时才加载待办数据
    final pendingCheckAsync = isAuthenticated ? ref.watch(pendingCheckCalendarProvider) : const AsyncValue<List>.data([]);
    final pendingApprovalAsync = isAuthenticated ? ref.watch(pendingApprovalCountProvider) : const AsyncValue<int>.data(0);

    final pendingCalendar = pendingCheckAsync.when(
      data: (list) => list.length,
      loading: () => -1,
      error: (_, __) => 0,
    );

    final pendingApproval = pendingApprovalAsync.when(
      data: (count) => count,
      loading: () => -1,
      error: (_, __) => 0,
    );

    final todos = [
      _TodoItem(
        title: '待验收行事历',
        count: pendingCalendar,
        color: const Color(0xFFFF9F0A),
        onTap: () => context.go(Routes.calendar),
      ),
      _TodoItem(
        title: '待审批',
        count: pendingApproval,
        color: AppColors.error,
        onTap: () => context.go(Routes.approvalCenter),
      ),
    ];

    return Column(
      children: todos.map((todo) {
        final badgeColor = todo.color;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: CupertinoListTile(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: todo.count < 0
                    ? CupertinoActivityIndicator(
                        radius: 10,
                        color: badgeColor,
                      )
                    : Text(
                        '${todo.count}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
              ),
            ),
            title: Text(
              todo.title,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            trailing: Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            onTap: todo.onTap,
          ),
        );
      }).toList(),
    );
  }
}

class _TodoItem {
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  _TodoItem({
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  // ignore: unused_element
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.subtitle),
          if (actionLabel != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppText.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

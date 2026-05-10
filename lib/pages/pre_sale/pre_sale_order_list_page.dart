import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/pre_sale_order_api.dart';
import '../../models/pre_sale_order.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 预售订单列表页
class PreSaleOrderListPage extends ConsumerStatefulWidget {
  const PreSaleOrderListPage({super.key});

  @override
  ConsumerState<PreSaleOrderListPage> createState() =>
      _PreSaleOrderListPageState();
}

class _PreSaleOrderListPageState
    extends ConsumerState<PreSaleOrderListPage> {
  final PreSaleOrderApi _api = PreSaleOrderApi();

  List<PreSaleOrder> _allOrders = [];
  bool _isLoading = false;
  int? _selectedStatusIndex;

  /// 状态标签
  static const List<_StatusTab> _statusTabs = [
    _StatusTab(label: '全部', value: null),
    _StatusTab(label: '未支付', value: 'unpaid'),
    _StatusTab(label: '已支付', value: 'paid'),
    _StatusTab(label: '已完成', value: 'completed'),
    _StatusTab(label: '退款/售后', value: 'apply-refund'),
    _StatusTab(label: '已取消', value: 'canceled'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      // 获取当前用户部门ID进行过滤
      final user = ref.read(currentUserProvider).value;
      final deptId = user?.deptId;

      final orders = await _api.list(
        limit: 200,
        departments: deptId != null ? [deptId] : null,
      );
      // 按更新时间倒序，与 PWA 保持一致
      orders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PreSaleOrder> get _filteredOrders {
    final selectedTab = _statusTabs[_selectedStatusIndex ?? 0];
    if (selectedTab.value == null) return _allOrders;

    return _allOrders.where((order) {
      if (selectedTab.value == 'paid') {
        // 已支付：paid状态且无商城单号
        return order.status == 'paid' && order.mallOrderNumber == null;
      }
      if (selectedTab.value == 'completed') {
        // 已完成：paid状态且有商城单号
        return order.status == 'paid' && order.mallOrderNumber != null;
      }
      return order.status == selectedTab.value;
    }).toList();
  }

  Map<String, int> get _counts {
    int unpaid = 0, paid = 0, completed = 0, refund = 0, canceled = 0;
    for (final order in _allOrders) {
      if (order.status == 'unpaid') {
        unpaid++;
      } else if (order.status == 'paid' && order.mallOrderNumber == null) {
        paid++;
      } else if (order.status == 'paid' && order.mallOrderNumber != null) {
        completed++;
      } else if (order.status == 'apply-refund' ||
          order.status == 'refunded') {
        refund++;
      } else if (order.status == 'canceled') {
        canceled++;
      }
    }
    return {
      'total': _allOrders.length,
      'unpaid': unpaid,
      'paid': paid,
      'completed': completed,
      'refund': refund,
      'canceled': canceled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final filteredOrders = _filteredOrders;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
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
        middle: const Text('预订订单'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 状态标签栏
            Container(
              color: CupertinoColors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_statusTabs.length, (index) {
                    final tab = _statusTabs[index];
                    final isSelected =
                        (_selectedStatusIndex ?? 0) == index;
                    int count = 0;
                    if (index == 0) count = counts['total'] ?? 0;
                    if (index == 1) count = counts['unpaid'] ?? 0;
                    if (index == 2) count = counts['paid'] ?? 0;
                    if (index == 3) count = counts['completed'] ?? 0;
                    if (index == 4) count = counts['refund'] ?? 0;
                    if (index == 5) count = counts['canceled'] ?? 0;

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedStatusIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF0A84FF)
                                  : CupertinoColors.white,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          '${tab.label}${count > 0 ? '($count)' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF0A84FF)
                                : const Color(0xFF636366),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // 列表
            Expanded(
              child: _isLoading && _allOrders.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : _buildList(filteredOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.cube_box,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('暂无预订订单', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildList(List<PreSaleOrder> orders) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PreSaleOrderCard(
                    order: order,
                    onTap: () {
                      context.push('/pre-sale/order/detail/${order.id}');
                    },
                  ),
                );
              },
              childCount: orders.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTab {
  final String label;
  final String? value;

  const _StatusTab({required this.label, this.value});
}

/// 预售订单卡片
class _PreSaleOrderCard extends StatelessWidget {
  final PreSaleOrder order;
  final VoidCallback onTap;

  const _PreSaleOrderCard({
    required this.order,
    required this.onTap,
  });

  Color get _statusColor {
    switch (order.statusEnum) {
      case PreSaleOrderStatus.unpaid:
        return const Color(0xFFFF9500);
      case PreSaleOrderStatus.paid:
        return order.mallOrderNumber != null
            ? const Color(0xFF34C759)
            : const Color(0xFF007AFF);
      case PreSaleOrderStatus.completed:
        return const Color(0xFF34C759);
      case PreSaleOrderStatus.applyRefund:
        return const Color(0xFFFF3B30);
      case PreSaleOrderStatus.refunded:
        return const Color(0xFF8E8E93);
      case PreSaleOrderStatus.canceled:
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String get _statusDisplayText {
    switch (order.statusEnum) {
      case PreSaleOrderStatus.paid:
        return order.mallOrderNumber != null ? '已完成' : '已支付';
      default:
        return order.statusLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(
      order.createdAt * 1000,
    );
    final timeStr =
        '${createdTime.month}/${createdTime.day} ${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '›',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),
            // 描述信息
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.describe != null && order.describe!.isNotEmpty)
                    Text(
                      order.describe!,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      '活动ID: ${order.activity}',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(label: '订金', value: '¥${order.amountYuan}'),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: '可抵扣',
                        value: '¥${order.totalAmountYuan}',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: '备注',
                        value: order.emplRemarks != null ? '已备注' : '未备注',
                        highlight: order.emplRemarks != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),
            // 底部
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Text(timeStr, style: AppText.caption),
                  const Spacer(),
                  // 预订购买标签
                  if (order.canBuy)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF0A84FF),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '预订购买',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0A84FF),
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 12,
              color: highlight ? const Color(0xFF0A84FF) : const Color(0xFF8E8E93),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: highlight ? const Color(0xFF0A84FF) : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

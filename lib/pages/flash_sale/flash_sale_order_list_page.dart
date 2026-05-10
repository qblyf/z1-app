import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/flash_sale_order_api.dart';
import '../../api/member_api.dart';
import '../../models/flash_sale_order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 秒杀订单列表页
class FlashSaleOrderListPage extends ConsumerStatefulWidget {
  const FlashSaleOrderListPage({super.key});

  @override
  ConsumerState<FlashSaleOrderListPage> createState() =>
      _FlashSaleOrderListPageState();
}

class _FlashSaleOrderListPageState
    extends ConsumerState<FlashSaleOrderListPage> {
  final FlashSaleOrderApi _api = FlashSaleOrderApi();
  final _searchController = TextEditingController();

  List<FlashSaleOrder> _allOrders = [];
  bool _isLoading = false;
  String _phone = '';

  /// 状态标签列表
  static const List<_StatusTab> _statusTabs = [
    _StatusTab(label: '未支付', value: 'unpaid'),
    _StatusTab(label: '已支付', value: 'completed'),
    _StatusTab(label: '已完成', value: 'completed'),
    _StatusTab(label: '退款/售后', value: 'apply-refund'),
    _StatusTab(label: '已取消', value: 'canceled'),
  ];

  int _selectedTabIndex = 0;
  _StatusTab get _currentTab => _statusTabs[_selectedTabIndex];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      // 搜索手机号对应的会员
      List<int>? customers;
      if (_phone.isNotEmpty) {
        final memberApi = MemberApi();
        try {
          final members = await memberApi.getByPhones([_phone]);
          if (members.isNotEmpty) {
            customers = members.map((m) => m.userIdent).toList();
          }
        } catch (_) {}
      }

      final orders = await _api.empList(
        customers: customers,
        limit: 200,
      );

      // 按状态分组筛选
      final grouped = _groupByStatus(orders);

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

  Map<String, List<FlashSaleOrder>> _groupByStatus(List<FlashSaleOrder> orders) {
    final groups = <String, List<FlashSaleOrder>>{
      'unpaid': [],
      'completed_paid': [],
      'completed': [],
      'refund': [],
      'canceled': [],
    };

    for (final order in orders) {
      if (order.status == FlashSaleOrderStatus.unpaid.value) {
        groups['unpaid']!.add(order);
      } else if (order.status == FlashSaleOrderStatus.canceled.value) {
        groups['canceled']!.add(order);
      } else if (order.status == FlashSaleOrderStatus.applyRefund.value ||
          order.status == FlashSaleOrderStatus.refunded.value) {
        groups['refund']!.add(order);
      } else if (order.status == FlashSaleOrderStatus.completed.value) {
        // 已完成中区分已处理和未处理
        groups['completed']!.add(order);
      }
    }

    // 修正: "已支付"实际上就是completed状态(未转商城单的)
    groups['completed_paid'] = groups['completed']!;

    return groups;
  }

  List<FlashSaleOrder> get _filteredOrders {
    final grouped = _groupByStatus(_allOrders);
    switch (_selectedTabIndex) {
      case 0:
        return grouped['unpaid'] ?? [];
      case 1:
        return grouped['completed_paid'] ?? [];
      case 2:
        return grouped['completed'] ?? [];
      case 3:
        return grouped['refund'] ?? [];
      case 4:
        return grouped['canceled'] ?? [];
      default:
        return [];
    }
  }

  Map<String, int> get _counts {
    final grouped = _groupByStatus(_allOrders);
    return {
      'unpaid': grouped['unpaid']?.length ?? 0,
      'paid': grouped['completed_paid']?.length ?? 0,
      'completed': grouped['completed']?.length ?? 0,
      'refund': grouped['refund']?.length ?? 0,
      'canceled': grouped['canceled']?.length ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final filteredOrders = _filteredOrders;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('秒杀订单'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: '输入手机号搜索',
                      onSubmitted: (_) {
                        setState(() => _phone = _searchController.text.trim());
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: const Color(0xFF0A84FF),
                    borderRadius: BorderRadius.circular(18),
                    minSize: 32,
                    onPressed: () {
                      setState(
                          () => _phone = _searchController.text.trim());
                      _loadData();
                    },
                    child: const Text(
                      '查询',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            // 状态标签栏
            Container(
              color: CupertinoColors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_statusTabs.length, (index) {
                    final tab = _statusTabs[index];
                    final isSelected = _selectedTabIndex == index;
                    int count = 0;
                    if (index == 0) count = counts['unpaid'] ?? 0;
                    if (index == 1) count = counts['paid'] ?? 0;
                    if (index == 2) count = counts['completed'] ?? 0;
                    if (index == 3) count = counts['refund'] ?? 0;
                    if (index == 4) count = counts['canceled'] ?? 0;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = index),
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
          Text('暂无订单', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildList(List<FlashSaleOrder> orders) {
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
                  child: _FlashSaleOrderCard(
                    order: order,
                    showProcessTag: _selectedTabIndex == 2,
                    onTap: () {
                      context.push('/flash-sale/order/detail/${order.id}');
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
  final String value;

  const _StatusTab({required this.label, required this.value});
}

/// 秒杀订单卡片
class _FlashSaleOrderCard extends StatelessWidget {
  final FlashSaleOrder order;
  final VoidCallback onTap;
  final bool showProcessTag;

  const _FlashSaleOrderCard({
    required this.order,
    required this.onTap,
    this.showProcessTag = false,
  });

  Color get _statusColor {
    switch (order.statusEnum) {
      case FlashSaleOrderStatus.unpaid:
        return const Color(0xFFFF9500);
      case FlashSaleOrderStatus.completed:
        return const Color(0xFF34C759);
      case FlashSaleOrderStatus.canceled:
        return const Color(0xFF8E8E93);
      case FlashSaleOrderStatus.applyRefund:
        return const Color(0xFFFF3B30);
      case FlashSaleOrderStatus.refunded:
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(
      order.createdAt * 1000,
    );
    final timeStr =
        '${createdTime.month}/${createdTime.day} ${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}';

    // 已完成状态的额外标签
    final bool isProcessed =
        order.status == FlashSaleOrderStatus.completed.value &&
            order.mallOrder != null;
    final bool isUnprocessed =
        order.status == FlashSaleOrderStatus.completed.value &&
            order.mallOrder == null;

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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _statusColor,
                          ),
                        ),
                        if (showProcessTag && isProcessed) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '已处理',
                              style: TextStyle(
                                fontSize: 10,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                        if (showProcessTag && isUnprocessed) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '未处理',
                              style: TextStyle(
                                fontSize: 10,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
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
            // 商品信息
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '商品ID: ${order.skuId}',
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (order.remarks != null &&
                            order.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.remarks!,
                            style: AppText.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${order.amountYuan}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(timeStr, style: AppText.caption),
                    ],
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

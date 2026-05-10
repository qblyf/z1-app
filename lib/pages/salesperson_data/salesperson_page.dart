import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/commission_api.dart';
import '../../api/sales_data_api.dart';
import '../../api/order_api.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 销售数据 API Provider
final salesDataApiProvider = Provider<SalesDataApi>((ref) => SalesDataApi());

/// 今日统计 Provider
final todayStatisticProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(salesDataApiProvider);
  return api.getTodayStatistic();
});

/// 本月统计 Provider
final monthStatisticProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(salesDataApiProvider);
  return api.getMonthStatistic();
});

/// 近期订单 Provider
final recentOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.read(salesDataApiProvider);
  return api.getRecentOrders(limit: 10);
});

/// 回收订单 Provider
final recycleOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.read(salesDataApiProvider);
  return api.getRecycleOrders(limit: 20);
});

/// 营业员排行 Provider
final sellerRankingProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(salesDataApiProvider);
  return api.getSellerRanking();
});

/// 销售人员数据页面
class SalespersonPage extends ConsumerStatefulWidget {
  const SalespersonPage({super.key});

  @override
  ConsumerState<SalespersonPage> createState() => _SalespersonPageState();
}

class _SalespersonPageState extends ConsumerState<SalespersonPage> {
  int _selectedIndex = 0;
  final _tabs = ['订单统计', '回收订单', '业绩排行'];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('销售数据'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedIndex,
                  children: {
                    for (int i = 0; i < _tabs.length; i++)
                      i: Text(_tabs[i], style: const TextStyle(fontSize: 13)),
                  },
                  onValueChanged: (index) {
                    if (index == null) return;
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),
            Expanded(
              child: [
                const _SalesOrderTab(),
                const _RecycleOrderTab(),
                const _RankingTab(),
              ][_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesOrderTab extends ConsumerWidget {
  const _SalesOrderTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayStatisticProvider);
    final monthAsync = ref.watch(monthStatisticProvider);
    final ordersAsync = ref.watch(recentOrdersProvider);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(todayStatisticProvider);
            ref.invalidate(monthStatisticProvider);
            ref.invalidate(recentOrdersProvider);
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                todayAsync.when(
                  data: (today) => _buildTodayStats(today),
                  loading: () => const _LoadingStatsCard(),
                  error: (e, _) => _ErrorStatsCard(message: e.toString()),
                ),
                const SizedBox(height: 12),
                monthAsync.when(
                  data: (month) => _buildMonthStats(month),
                  loading: () => const _LoadingStatsCard(),
                  error: (e, _) => _ErrorStatsCard(message: e.toString()),
                ),
                const SizedBox(height: 24),
                const Text(
                  '近期订单',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ordersAsync.when(
                  data: (orders) => _RecentOrderList(orders: orders),
                  loading: () =>
                      const LoadingWidget(message: '加载中...'),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(Map<String, dynamic> today) {
    final orderCount = today['orderCount'] ?? today['order_count'] ?? 0;
    final salesAmount = today['salesAmount'] ??
        today['sales_amount'] ??
        today['revenueAmount'] ??
        0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: '今日订单',
            value: orderCount.toString(),
            icon: CupertinoIcons.doc_text,
            color: CupertinoColors.activeBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: '今日销售额',
            value: _formatAmount(salesAmount),
            icon: CupertinoIcons.money_dollar_circle,
            color: CupertinoColors.activeGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthStats(Map<String, dynamic> month) {
    final orderCount = month['orderCount'] ?? month['order_count'] ?? 0;
    final salesAmount = month['salesAmount'] ??
        month['sales_amount'] ??
        month['revenueAmount'] ??
        0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: '本月订单',
            value: orderCount.toString(),
            icon: CupertinoIcons.calendar,
            color: CupertinoColors.activeOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: '本月销售额',
            value: _formatAmount(salesAmount),
            icon: CupertinoIcons.chart_bar_alt_fill,
            color: CupertinoColors.systemPurple,
          ),
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount is int) {
      return '¥${(amount / 100).toStringAsFixed(0)}';
    }
    return '¥0';
  }
}

class _LoadingStatsCard extends StatelessWidget {
  const _LoadingStatsCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 2; i++) ...[
          Expanded(
            child: Container(
              height: 100,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CupertinoActivityIndicator()),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorStatsCard extends StatelessWidget {
  final String message;

  const _ErrorStatsCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 2; i++) ...[
          Expanded(
            child: Container(
              height: 100,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '加载失败',
                  style: TextStyle(color: CupertinoColors.destructiveRed.resolveFrom(context)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderList extends StatelessWidget {
  final List<Order> orders;

  const _RecentOrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyWidget(
        message: '暂无近期订单',
        icon: CupertinoIcons.doc_text,
      );
    }

    return Column(
      children: orders.map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () =>
                context.push('/salesperson-data/order/${order.orderNumber}'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.black,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(order.createdAt),
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
                    AmountText(amount: order.totalAmount),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: order.statusLabel,
                      color: _getStatusColor(order.status),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(int unix) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.month}-${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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

class _RecycleOrderTab extends ConsumerWidget {
  const _RecycleOrderTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(recycleOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyWidget(
            message: '暂无回收订单',
            icon: CupertinoIcons.arrow_3_trianglepath,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(recycleOrdersProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _RecycleOrderCard(order: orders[index]),
                  childCount: orders.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(recycleOrdersProvider),
      ),
    );
  }
}

class _RecycleOrderCard extends StatelessWidget {
  final Order order;

  const _RecycleOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              StatusBadge(
                label: _getRecycleStatusLabel(order.status),
                color: _getRecycleStatusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (order.userName != null) ...[
                Icon(
                  CupertinoIcons.person,
                  size: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                const SizedBox(width: 4),
                Text(
                  order.userName!,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(
                CupertinoIcons.clock,
                size: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(order.createdAt),
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('回收金额'),
              AmountText(amount: order.totalAmount),
            ],
          ),
        ],
      ),
    );
  }

  String _getRecycleStatusLabel(int status) {
    switch (status) {
      case 1:
        return '未打款';
      case 2:
        return '已打款';
      case 3:
        return '已撤销';
      default:
        return '未知';
    }
  }

  Color _getRecycleStatusColor(int status) {
    switch (status) {
      case 1:
        return CupertinoColors.activeOrange;
      case 2:
        return CupertinoColors.activeGreen;
      case 3:
        return CupertinoColors.systemGrey;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _formatTime(int unix) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.month}-${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _RankingTab extends ConsumerWidget {
  const _RankingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(sellerRankingProvider);

    return rankingAsync.when(
      data: (rankings) {
        if (rankings.isEmpty) {
          return const EmptyWidget(
            message: '暂无排行数据',
            icon: CupertinoIcons.chart_bar,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(sellerRankingProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = rankings[index];
                    return _RankingCard(
                      rank: index + 1,
                      name: item['sellerName'] ?? item['name'] ?? '未知',
                      orderCount:
                          item['orderCount'] ?? item['order_count'] ?? 0,
                      amount: item['salesAmount'] ?? item['sales_amount'] ?? 0,
                    );
                  },
                  childCount: rankings.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(sellerRankingProvider),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final String name;
  final int orderCount;
  final int amount;

  const _RankingCard({
    required this.rank,
    required this.name,
    required this.orderCount,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    IconData? rankIcon;

    switch (rank) {
      case 1:
        rankColor = CupertinoColors.systemYellow;
        rankIcon = CupertinoIcons.star_fill;
        break;
      case 2:
        rankColor = CupertinoColors.systemGrey;
        rankIcon = CupertinoIcons.star_fill;
        break;
      case 3:
        rankColor = CupertinoColors.systemOrange;
        rankIcon = CupertinoIcons.star_fill;
        break;
      default:
        rankColor = CupertinoColors.systemGrey;
        rankIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.black,
                  ),
                ),
                Text(
                  '订单: $orderCount 单',
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
              AmountText(amount: amount, fontSize: 16),
              const SizedBox(height: 4),
              Text(
                '销售额',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 销售订单详情页面
class SalespersonOrderInfoPage extends ConsumerWidget {
  final String orderNumber;

  const SalespersonOrderInfoPage(
      {super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(orderNumber));

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('订单详情'),
      ),
      child: orderAsync.when(
        data: (order) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 状态卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        color: _getStatusColor(order.status),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 订单信息
                _buildSection('订单信息', [
                  _buildInfoRow('订单编号', order.orderNumber),
                  _buildInfoRow('订单类型', order.genreLabel),
                  _buildInfoRow(
                      '下单时间', DateTimeText(unix: order.createdAt)),
                  if (order.departmentName != null)
                    _buildInfoRow('门店', order.departmentName!),
                  if (order.userName != null)
                    _buildInfoRow('客户', order.userName!),
                  if (order.userPhone != null)
                    _buildInfoRow('手机', order.userPhone!),
                ]),

                // 商品信息
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '商品信息',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                CupertinoIcons.photo),
                                      ),
                                    )
                                  : const Icon(CupertinoIcons.photo),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? '商品',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (item.skuName != null)
                                    Text(
                                      item.skuName!,
                                      style: TextStyle(
                                          color: CupertinoColors
                                              .secondaryLabel
                                              .resolveFrom(context),
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AmountText(amount: item.price, fontSize: 14),
                                Text(
                                  'x${item.quantity}',
                                  style: TextStyle(
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],

                // 金额信息
                const SizedBox(height: 16),
                _buildSection('金额信息', [
                  _buildInfoRow(
                    '订单金额',
                    AmountText(amount: order.totalAmount),
                  ),
                  if (order.discountAmount != null)
                    _buildInfoRow(
                      '优惠',
                      AmountText(amount: -order.discountAmount!),
                    ),
                  _buildInfoRow(
                    '实付款',
                    AmountText(
                      amount: order.actualAmount ?? order.totalAmount,
                      fontSize: 18,
                    ),
                  ),
                ]),

                // 支付明细
                const SizedBox(height: 16),
                _buildPaymentSection(context, ref),

                // 积分变动
                const SizedBox(height: 16),
                _buildCoinSection(ref),

                // 提成信息
                const SizedBox(height: 16),
                _buildCommissionSection(ref),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: '加载中...'),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 64,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
          value is Widget
              ? value
              : Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // 支付明细
  // ═══════════════════════════════════════
  Widget _buildPaymentSection(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(_orderPaymentDetailProvider(orderNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('支付明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无支付记录', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                );
              }
              return Column(
                children: payments.asMap().entries.map((entry) {
                  final p = entry.value;
                  final isLast = entry.key == payments.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(
                        bottom: BorderSide(color: CupertinoColors.systemGrey5.withValues(alpha: 0.5), width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.paymentTypeName ?? '支付方式${p.paymentTypeID}', style: const TextStyle(fontSize: 14)),
                            if (p.platformNumber != null)
                              Text('单号: ${p.platformNumber}', style: const TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel)),
                          ],
                        ),
                        AmountText(amount: p.amount, fontSize: 14),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(16), child: CupertinoActivityIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 积分变动
  // ═══════════════════════════════════════
  Widget _buildCoinSection(WidgetRef ref) {
    final coinAsync = ref.watch(_orderCoinChangeProvider(orderNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('积分变动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: coinAsync.when(
            data: (coin) {
              if (coin == null) {
                return const Text('暂无积分变动', style: TextStyle(color: CupertinoColors.secondaryLabel));
              }
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('积分增加', style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel)),
                      Text('+${coin.increase}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.activeGreen)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('积分扣减', style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel)),
                      Text('-${coin.decrease}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.destructiveRed)),
                    ],
                  ),
                ],
              );
            },
            loading: () => const CupertinoActivityIndicator(),
            error: (e, _) => Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 提成信息
  // ═══════════════════════════════════════
  Widget _buildCommissionSection(WidgetRef ref) {
    final commissionAsync = ref.watch(_orderCommissionProvider(orderNumber));
    final productCommAsync = ref.watch(_productCommissionProvider(orderNumber));
    final serviceCommAsync = ref.watch(_serviceCommissionProvider(orderNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('提成信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: commissionAsync.when(
            data: (commissions) {
              if (commissions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无提成数据', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                );
              }
              final commission = commissions.first;
              return Column(
                children: [
                  // 订单提成
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: CupertinoColors.systemGrey5.withValues(alpha: 0.5), width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('订单提成', style: TextStyle(fontSize: 14)),
                        Text(
                          _formatFen(commission.price),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: commission.price >= 0 ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 总提成
                  if (commission.totalCommissionPrice != null && commission.totalCommissionPrice != 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('总提成', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            _formatFen(commission.totalCommissionPrice!),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('提成数据加载失败', style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
            ),
          ),
        ),

        // 商品提成列表
        const SizedBox(height: 12),
        const Text('商品提成', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        productCommAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('暂无商品提成', style: TextStyle(color: CupertinoColors.secondaryLabel)),
              );
            }
            return Column(
              children: products.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final isLast = i == products.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    border: isLast ? null : Border(
                      bottom: BorderSide(color: CupertinoColors.systemGrey5.withValues(alpha: 0.5), width: 0.5),
                    ),
                    borderRadius: isLast ? BorderRadius.circular(12) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '商品 #${p.productID ?? '未知'}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (p.serial != null && p.serial!.isNotEmpty)
                              Text(
                                '串号: ${p.serial}',
                                style: const TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatFen(p.discountCent),
                            style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                          ),
                          Text(
                            p.price >= 0 ? '+${_formatFen(p.price)}' : _formatFen(p.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: p.price >= 0 ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => const SizedBox.shrink(),
        ),

        // 服务提成列表
        const SizedBox(height: 12),
        const Text('服务提成', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        serviceCommAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('暂无服务提成', style: TextStyle(color: CupertinoColors.secondaryLabel)),
              );
            }
            return Column(
              children: services.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final isLast = i == services.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    border: isLast ? null : Border(
                      bottom: BorderSide(color: CupertinoColors.systemGrey5.withValues(alpha: 0.5), width: 0.5),
                    ),
                    borderRadius: isLast ? BorderRadius.circular(12) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '服务 #${s.serviceID ?? '未知'}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (s.sn != null && s.sn!.isNotEmpty)
                              Text(
                                '绑定串号: ${s.sn}',
                                style: const TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatFen(s.discountCent),
                            style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                          ),
                          Text(
                            s.price >= 0 ? '+${_formatFen(s.price)}' : _formatFen(s.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: s.price >= 0 ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatFen(int fen) {
    if (fen >= 0) {
      return '¥${(fen / 100).toStringAsFixed(2)}';
    }
    return '-¥${((-fen) / 100).toStringAsFixed(2)}';
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

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return CupertinoIcons.creditcard;
      case 2:
        return CupertinoIcons.cube_box;
      case 3:
        return CupertinoIcons.car;
      case 4:
        return CupertinoIcons.checkmark_circle_fill;
      case 5:
        return CupertinoIcons.xmark_circle;
      default:
        return CupertinoIcons.question_circle;
    }
  }
}

/// 销售订单详情 Provider
final _orderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderNumber) async {
  final api = OrderApi();
  return api.getDetail(orderNumber);
});

/// 订单支付明细 Provider
final _orderPaymentDetailProvider =
    FutureProvider.family<List<OrderPaymentDetail>, String>((ref, orderNumber) async {
  return OrderApi().getPaymentDetailListByOrder(orderNumber);
});

/// 订单积分变动 Provider
final _orderCoinChangeProvider =
    FutureProvider.family<OrderCoinChange?, String>((ref, orderNumber) async {
  return OrderApi().getCoinDetailByOrder(orderNumber);
});

/// 订单提成 Provider
final _orderCommissionProvider = FutureProvider.family<List<CommissionOrderItem>, String>((ref, orderNumber) async {
  final api = CommissionApi();
  final now = DateTime.now();
  return api.getOrderCommission(
    orderNumber: orderNumber,
    minCreatedAt: DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: now.millisecondsSinceEpoch ~/ 1000,
  );
});

/// 订单商品提成 Provider
final _productCommissionProvider = FutureProvider.family<List<CommissionProductItem>, String>((ref, orderNumber) async {
  final api = CommissionApi();
  final now = DateTime.now();
  return api.getProductCommission(
    orderNumber: orderNumber,
    minCreatedAt: DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: now.millisecondsSinceEpoch ~/ 1000,
  );
});

/// 订单服务提成 Provider
final _serviceCommissionProvider = FutureProvider.family<List<CommissionServiceItem>, String>((ref, orderNumber) async {
  final api = CommissionApi();
  final now = DateTime.now();
  return api.getServiceCommission(
    orderNumber: orderNumber,
    minCreatedAt: DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: now.millisecondsSinceEpoch ~/ 1000,
  );
});

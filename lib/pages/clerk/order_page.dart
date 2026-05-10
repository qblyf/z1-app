import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 订单页面
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  int _currentIndex = 0;
  final _tabs = ['全部', '销售', '网销', '批发', '维修', '回收'];

  @override
  void initState() {
    super.initState();
    // 延迟到 widget 树构建完成后加载，避免 "modify provider during build" 错误
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    await ref.read(orderListProvider.notifier).loadOrders(refresh: true);
  }

  String? _getGenreByIndex(int index) {
    switch (index) {
      case 1:
        return 'shopSale';
      case 2:
        return 'netSale';
      case 3:
        return 'outSale';
      case 4:
        return 'serviceSale';
      case 5:
        return 'recycleOrder';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('订单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {},
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 分段选择器
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _currentIndex,
                  children: {
                    for (int i = 0; i < _tabs.length; i++)
                      i: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _tabs[i],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  },
                  onValueChanged: (index) {
                    if (index == null) return;
                    setState(() => _currentIndex = index);
                    final genre = _getGenreByIndex(index);
                    ref.read(orderListProvider.notifier).loadOrders(
                          genre: genre,
                          refresh: true,
                        );
                  },
                ),
              ),
            ),

            // 订单列表
            Expanded(
              child: _OrderListView(
                onRefresh: _loadOrders,
                onLoadMore: () {
                  ref.read(orderListProvider.notifier).loadMore();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderListView extends ConsumerWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  const _OrderListView({
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderListProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyWidget(
            message: '暂无订单',
            icon: CupertinoIcons.doc_text,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: onRefresh),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= orders.length) return null;
                    return _OrderCard(order: orders[index]);
                  },
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
        onRetry: onRefresh,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

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
          // 订单头部
          Row(
            children: [
              Text(
                order.orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: order.genreLabel,
                color: _getGenreColor(order.genre),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 门店信息
          if (order.departmentName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.building_2_fill,
                    size: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.departmentName!,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // 时间
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 4),
              DateTimeText(unix: order.createdAt, format: 'MM-dd HH:mm'),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // 订单金额
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: order.statusLabel,
                color: _getStatusColor(order.status),
              ),
              AmountText(amount: order.totalAmount),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGenreColor(String genre) {
    switch (genre) {
      case 'shopSale':
        return CupertinoColors.activeBlue;
      case 'netSale':
        return CupertinoColors.systemPurple;
      case 'outSale':
        return CupertinoColors.activeOrange;
      case 'serviceSale':
        return CupertinoColors.systemTeal;
      case 'recycleOrder':
        return CupertinoColors.activeGreen;
      default:
        return CupertinoColors.systemGrey;
    }
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

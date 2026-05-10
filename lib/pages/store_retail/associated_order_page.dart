import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 可加单订单列表 Provider
final associatedOrdersProvider =
    FutureProvider.family<List<MallOrder>, int>((ref, userIdent) async {
  final api = StoreRetailApi();
  return api.getAllowAssociatedOrderList(customer: userIdent).then(
        (list) => list.map((o) => MallOrder.fromJson(o)).toList().toList(),
      );
});

/// 加单页（查询顾客历史订单，选择一个继续下单）
class AssociatedOrderPage extends ConsumerWidget {
  final int userIdent;

  const AssociatedOrderPage({super.key, required this.userIdent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(associatedOrdersProvider(userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('订单查询/加单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return EmptyWidget(
                message: '暂无历史订单',
                icon: CupertinoIcons.doc_text,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _AssociatedOrderCard(
                  order: order,
                  onTap: () => context.push(
                    '/store-retail/order/$userIdent?assoc=${order.number}',
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(message: '加载订单...'),
          error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
        ),
      ),
    );
  }
}

class _AssociatedOrderCard extends StatelessWidget {
  final MallOrder order;
  final VoidCallback onTap;

  const _AssociatedOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.number,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                StatusBadge(
                  label: order.statusEnum.label,
                  color: order.statusEnum.color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.products.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: order.products.take(4).map((p) {
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: p.thumbnail != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              p.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                CupertinoIcons.cube_box,
                                size: 20,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.cube_box,
                            size: 20,
                            color: CupertinoColors.systemGrey,
                          ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.formattedCreatedAt,
                  style: AppText.caption,
                ),
                Row(
                  children: [
                    Text(
                      '¥${(order.orderAmount / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '加单',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

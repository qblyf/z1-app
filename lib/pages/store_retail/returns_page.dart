import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 可退货订单列表 Provider
final returnableOrdersProvider =
    FutureProvider.family<List<MallOrder>, int>((ref, userIdent) async {
  final api = StoreRetailApi();
  // 获取已完成或已发货的订单（可以退货）
  try {
    final orders = await api.getAllowAssociatedOrderList(customer: userIdent);
    return orders.map((o) => MallOrder.fromJson(o)).toList();
  } catch (_) {
    return [];
  }
});

/// 退货退款页
class ReturnsPage extends ConsumerStatefulWidget {
  final int userIdent;

  const ReturnsPage({super.key, required this.userIdent});

  @override
  ConsumerState<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends ConsumerState<ReturnsPage> {
  MallOrder? _selectedOrder;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(returnableOrdersProvider(widget.userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('退货退款'),
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
                message: '暂无可退货的订单',
                icon: CupertinoIcons.arrow_counterclockwise,
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _ReturnableOrderCard(
                        order: order,
                        isSelected: _selectedOrder?.number == order.number,
                        onTap: () => setState(() => _selectedOrder = order),
                      );
                    },
                  ),
                ),
                if (_selectedOrder != null)
                  _ReturnForm(
                    order: _selectedOrder!,
                    onSubmit: _handleReturn,
                    isSubmitting: _isSubmitting,
                  ),
              ],
            );
          },
          loading: () => const LoadingWidget(message: '加载订单...'),
          error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
        ),
      ),
    );
  }

  Future<void> _handleReturn({
    required String orderNumber,
    required Map<String, dynamic> info,
    String? remarks,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      final api = StoreRetailApi();
      final success = await api.mallOrderBack(
        mallOrderNumber: orderNumber,
        info: info,
        remarks: remarks,
      );
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.xmark_circle_fill,
                color: success ? AppColors.accent : CupertinoColors.destructiveRed,
              ),
              const SizedBox(width: 8),
              Text(success ? '退货申请已提交' : '提交失败'),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () {
                Navigator.pop(ctx);
                if (success) context.pop();
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('提交失败'),
            content: Text('网络错误: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ReturnableOrderCard extends StatelessWidget {
  final MallOrder order;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReturnableOrderCard({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : CupertinoColors.systemGrey5,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.elevated : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '订单号: ${order.number}',
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
              ...order.products.take(3).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: p.thumbnail != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(p.thumbnail!,
                                      fit: BoxFit.cover),
                                )
                              : const Icon(
                                  CupertinoIcons.cube_box,
                                  size: 20,
                                  color: CupertinoColors.systemGrey,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.displayName,
                            style: AppText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'x${p.qty}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(order.createdAt),
                  style: AppText.caption,
                ),
                Text(
                  '实付: ¥${(order.orderAmount / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ReturnForm extends StatefulWidget {
  final MallOrder order;
  final Future<void> Function({
    required String orderNumber,
    required Map<String, dynamic> info,
    String? remarks,
  }) onSubmit;
  final bool isSubmitting;

  const _ReturnForm({
    required this.order,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  State<_ReturnForm> createState() => _ReturnFormState();
}

class _ReturnFormState extends State<_ReturnForm> {
  final _remarkController = TextEditingController();
  final Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    // 默认全选
    for (final p in widget.order.products) {
      final id = p.productId ?? p.skuId;
      _selectedProductIds.add(id);
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选择退货商品', style: AppText.label),
            const SizedBox(height: 8),
            ...widget.order.products.map((p) {
              final id = p.skuId;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedProductIds.contains(id)) {
                      _selectedProductIds.remove(id);
                    } else {
                      _selectedProductIds.add(id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _selectedProductIds.contains(id)
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        color: _selectedProductIds.contains(id)
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.displayName,
                          style: AppText.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('x${p.qty}', style: AppText.caption),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _remarkController,
              placeholder: '退货原因（选填）',
              padding: const EdgeInsets.all(12),
              maxLines: 2,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              onPressed: _selectedProductIds.isEmpty || widget.isSubmitting
                  ? null
                  : () => widget.onSubmit(
                        orderNumber: widget.order.number,
                        info: {
                          'productIDs': _selectedProductIds.toList(),
                        },
                        remarks: _remarkController.text.trim().isNotEmpty
                            ? _remarkController.text.trim()
                            : null,
                      ),
              child: widget.isSubmitting
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : Text('提交退货申请'),
            ),
          ],
        ),
      ),
    );
  }
}

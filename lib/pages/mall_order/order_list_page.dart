import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/order_api.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 商城订单列表页面
/// 支持零售单 / 回收单 / 售后单 三种类型
class MallOrderListPage extends ConsumerStatefulWidget {
  const MallOrderListPage({super.key});

  @override
  ConsumerState<MallOrderListPage> createState() => _MallOrderListPageState();
}

class _MallOrderListPageState extends ConsumerState<MallOrderListPage> {
  /// 订单类型: 0=零售单, 1=回收单, 2=售后单
  int _orderTypeIndex = 0;
  /// 状态筛选: null=全部, 0=待付款, 1=待发货, 2=待收货, 3=已完成, 4=已取消
  int? _statusIndex;

  final _orderTypeLabels = ['零售单', '回收单', '售后单'];
  final _statusLabels = ['全部', '待付款', '待发货', '待收货', '已完成', '已取消'];

  /// 零售单状态映射到API状态值
  int? _getMallStatusForIndex(int? idx) {
    if (idx == null || idx == 0) return null;
    return idx - 1; // 0=全部, 1=待付款(0), 2=待发货(1), 3=待收货(2), 4=已完成(3), 5=已取消(4)
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: const Text('商城订单', style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add, size: 24),
          onPressed: () => _showOrderTypeMenu(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 订单类型选择
            _buildTypeSelector(),
            // 状态筛选
            _buildStatusFilter(),
            // 订单列表
            Expanded(
              child: _MallOrderListContent(
                orderTypeIndex: _orderTypeIndex,
                statusIndex: _statusIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: List.generate(_orderTypeLabels.length, (i) {
          final isSelected = _orderTypeIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _orderTypeIndex = i;
                _statusIndex = 0;
                _loadOrders();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0x00000000),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _orderTypeLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(_statusLabels.length, (i) {
          final isSelected = (_statusIndex ?? 0) == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _statusIndex = i;
                _loadOrders();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0x00000000),
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusLabels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _loadOrders() {
    final notifier = ref.read(mallOrderListProvider.notifier);
    notifier.setStatus(_getMallStatusForIndex(_statusIndex));
  }

  void _showOrderTypeMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('新建订单'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('零售单'),
            onPressed: () {
              Navigator.pop(ctx);
              _createRetailOrder(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('回收单'),
            onPressed: () {
              Navigator.pop(ctx);
              _showTip(context, '回收单功能开发中');
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('售后单'),
            onPressed: () {
              Navigator.pop(ctx);
              _showTip(context, '售后单功能开发中');
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text('取消'),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _createRetailOrder(BuildContext context) {
    // TODO: 跳转到代下单页面
    _showTip(context, '代下单功能开发中，请从会员详情页进入');
  }

  void _showTip(BuildContext context, String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

/// 商城订单列表内容
class _MallOrderListContent extends ConsumerStatefulWidget {
  final int orderTypeIndex;
  final int? statusIndex;

  const _MallOrderListContent({
    required this.orderTypeIndex,
    required this.statusIndex,
  });

  @override
  ConsumerState<_MallOrderListContent> createState() => _MallOrderListContentState();
}

class _MallOrderListContentState extends ConsumerState<_MallOrderListContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void didUpdateWidget(_MallOrderListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderTypeIndex != widget.orderTypeIndex ||
        oldWidget.statusIndex != widget.statusIndex) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    final notifier = ref.read(mallOrderListProvider.notifier);
    // 切换类型
    final type = MallOrderType.values[widget.orderTypeIndex];
    notifier.setType(type);
    // 切换状态
    int? status;
    if (widget.statusIndex != null && widget.statusIndex! > 0) {
      status = widget.statusIndex! - 1;
    }
    notifier.setStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(mallOrderListProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return EmptyWidget(
            message: _getEmptyMessage(),
            icon: CupertinoIcons.bag,
          );
        }
        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => ref.read(mallOrderListProvider.notifier).refresh()),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = orders[index];
                    return _MallOrderCard(
                      order: order,
                      onTap: () => context.push('/mall-order/${order.number}'),
                    );
                  },
                  childCount: orders.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: _loadOrders,
      ),
    );
  }

  String _getEmptyMessage() {
    switch (widget.orderTypeIndex) {
      case 0:
        return '暂无零售订单';
      case 1:
        return '暂无回收订单';
      case 2:
        return '暂无售后订单';
      default:
        return '暂无订单';
    }
  }
}

/// 商城订单卡片
class _MallOrderCard extends StatelessWidget {
  final MallOrder order;
  final VoidCallback onTap;

  const _MallOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order.statusInfo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // 头部：订单编号 + 状态
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: status.label, color: status.color),
                ],
              ),
            ),

            // 商品信息
            if (order.products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    ...order.products.take(2).map((p) => _buildProductRow(context, p)),
                    if (order.products.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              '共 ${order.products.length} 件商品',
                              style: AppText.caption.copyWith(
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // 底部：金额 + 时间
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.formattedCreatedAt,
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '实付: ${order.formattedAmount}',
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (order.discountAmount < order.orderAmount)
                        Text(
                          '原价: ${order.formattedOrderAmount}',
                          style: AppText.caption.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
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

  Widget _buildProductRow(BuildContext context, MallOrderProduct p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: p.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.thumbnail!, fit: BoxFit.cover),
                  )
                : const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.skuName ?? p.productName ?? '商品',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'x${p.qty}',
                  style: AppText.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            p.subtotal,
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 商城订单详情页面
class MallOrderDetailPage extends ConsumerStatefulWidget {
  final String orderNumber;

  const MallOrderDetailPage({super.key, required this.orderNumber});

  @override
  ConsumerState<MallOrderDetailPage> createState() => _MallOrderDetailPageState();
}

class _MallOrderDetailPageState extends ConsumerState<MallOrderDetailPage> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(mallOrderDetailProvider(widget.orderNumber));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('订单详情', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      child: detailAsync.when(
        data: (order) => _MallOrderDetailView(
          order: order,
          onConfirmPay: () => _confirmPay(context, order),
          onShip: () => _shipOrder(context, order),
          onConfirmReceive: () => _confirmReceive(context, order),
          onCancel: () => _cancelOrder(context, order),
        ),
        loading: () => const LoadingWidget(message: '加载中...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(mallOrderDetailProvider(widget.orderNumber)),
        ),
      ),
    );
  }

  void _confirmPay(BuildContext context, MallOrder order) {
    _showTip(context, '请在订单详情页完成支付');
  }

  void _shipOrder(BuildContext context, MallOrder order) {
    final expressNameController = TextEditingController();
    final expressNumberController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('发货'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(controller: expressNameController, placeholder: '快递名称'),
            const SizedBox(height: 8),
            CupertinoTextField(controller: expressNumberController, placeholder: '快递单号'),
          ],
        ),
        actions: [
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            child: const Text('确认发货'),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(orderApiProvider);
              final ok = await api.mallOrderShipped(
                order.number,
                expressName: expressNameController.text.isNotEmpty ? expressNameController.text : null,
                expressNumber: expressNumberController.text.isNotEmpty ? expressNumberController.text : null,
              );
              if (ok) ref.invalidate(mallOrderDetailProvider(widget.orderNumber));
            },
          ),
        ],
      ),
    );
  }

  void _confirmReceive(BuildContext context, MallOrder order) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认收货'),
        content: const Text('确认用户已收到货物？'),
        actions: [
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            child: const Text('确认'),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(orderApiProvider);
              final ok = await api.mallOrderConfirmReceived(order.number);
              if (ok) ref.invalidate(mallOrderDetailProvider(widget.orderNumber));
            },
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context, MallOrder order) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('取消订单'),
        content: Text('确定取消订单 ${order.number}？'),
        actions: [
          CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('确认取消'),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(orderApiProvider);
              bool ok;
              if (order.status == 0) {
                ok = await api.mallOrderUnpaidCancel(order.number);
              } else if (order.status == 1) {
                ok = await api.mallOrderPaidCancel(order.number);
              } else {
                return;
              }
              if (ok) {
                ref.invalidate(mallOrderDetailProvider(widget.orderNumber));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showTip(BuildContext context, String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(ctx))],
      ),
    );
  }
}

class _MallOrderDetailView extends StatelessWidget {
  final MallOrder order;
  final VoidCallback onConfirmPay;
  final VoidCallback onShip;
  final VoidCallback onConfirmReceive;
  final VoidCallback onCancel;

  const _MallOrderDetailView({
    required this.order,
    required this.onConfirmPay,
    required this.onShip,
    required this.onConfirmReceive,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = order.statusInfo;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 状态卡片
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(order.status), color: status.color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.label,
                        style: AppText.subtitle.copyWith(color: status.color),
                      ),
                      Text(
                        _getStatusHint(order.status),
                        style: AppText.caption.copyWith(
                          color: status.color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 收货信息
          if (order.addressName != null || order.addressDetail != null)
            _buildSection('收货信息', [
              if (order.addressName != null)
                _buildInfoRow('收货人', order.addressName!),
              if (order.addressPhone != null)
                _buildInfoRow('电话', order.addressPhone!),
              if (order.addressDetail != null)
                _buildInfoRow('地址', order.addressDetail!),
            ]),

          // 商品信息
          _buildSection('商品信息', [
            ...order.products.map((p) => _buildProductRow(context, p)),
            Container(height: 0.5, color: AppColors.divider),
            // 价格明细
            _buildPriceRow('商品总额', order.formattedOrderAmount, null),
            if (order.freightAmount != null && order.freightAmount! > 0)
              _buildPriceRow('运费', '¥${(order.freightAmount! / 100).toStringAsFixed(2)}', null),
            if (order.couponAmount != null && order.couponAmount! > 0)
              _buildPriceRow('优惠券', '-¥${(order.couponAmount! / 100).toStringAsFixed(2)}', const Color(0xFFFF9500)),
            if (order.coinAmount != null && order.coinAmount! > 0)
              _buildPriceRow('积分抵扣', '-¥${(order.coinAmount! / 100).toStringAsFixed(2)}', const Color(0xFFFF9500)),
            if (order.discountAmount < order.orderAmount)
              _buildPriceRow('折扣', '-¥${((order.orderAmount - order.discountAmount) / 100).toStringAsFixed(2)}', const Color(0xFFFF9500)),
            Container(height: 0.5, color: AppColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('实付金额', style: AppText.subtitle),
                Text(order.formattedAmount, style: AppText.subtitle.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ]),

          // 优惠券信息
          if (order.couponAmount != null && order.couponAmount! > 0)
            _buildSection('优惠信息', [
              _buildInfoRow('优惠券', order.couponTitle ?? '已使用优惠券'),
              _buildInfoRow('优惠金额', '-¥${(order.couponAmount! / 100).toStringAsFixed(2)}'),
            ]),

          // 导购信息
          if (order.employeeName != null)
            _buildSection('导购信息', [
              _buildInfoRow('导购', order.employeeName!),
              if (order.assistantName != null)
                _buildInfoRow('助理', order.assistantName!),
            ]),

          // 快递信息
          if (order.expressName != null || order.expressNumber != null)
            _buildSection('快递信息', [
              if (order.expressName != null) _buildInfoRow('快递公司', order.expressName!),
              if (order.expressNumber != null) _buildInfoRow('快递单号', order.expressNumber!),
            ]),

          // 订单信息
          _buildSection('订单信息', [
            _buildInfoRow('订单编号', order.number),
            _buildInfoRow('下单时间', order.formattedCreatedAt),
            if (order.departmentName != null)
              _buildInfoRow('所属门店', order.departmentName!),
            if (order.channel != null)
              _buildInfoRow('销售渠道', order.channel!),
            if (order.invoiceNumber != null)
              _buildInfoRow('发票号', order.invoiceNumber!),
            if (order.cancelReason != null && order.cancelReason!.isNotEmpty)
              _buildInfoRow('取消原因', order.cancelReason!),
          ]),

          // 备注
          if (order.remark != null && order.remark!.isNotEmpty)
            _buildSection('备注', [
              _buildInfoRow('', order.remark!),
            ]),

          const SizedBox(height: AppSpacing.xl),

          // 操作按钮
          _buildActions(context, order),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.subtitle),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
              ),
            ),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          Text(
            value,
            style: AppText.body.copyWith(
              color: valueColor ?? CupertinoColors.label.resolveFrom(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, MallOrderProduct p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: p.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.thumbnail!, fit: BoxFit.cover),
                  )
                : const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.skuName ?? '商品', style: AppText.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('x${p.qty}', style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              ],
            ),
          ),
          Text(p.subtotal, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, MallOrder order) {
    // 根据订单状态显示不同操作按钮
    switch (order.status) {
      case 0: // 待付款
        return _ActionButtons([
          _Action('取消订单', AppColors.error, onCancel),
          _Action('确认付款', AppColors.primary, onConfirmPay),
        ]);
      case 1: // 已付款待发货
        return _ActionButtons([
          _Action('发货', AppColors.primary, onShip),
        ]);
      case 2: // 已发货待收货
        return _ActionButtons([
          _Action('确认收货', AppColors.accent, onConfirmReceive),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return CupertinoIcons.clock;
      case 1:
        return CupertinoIcons.cube_box;
      case 2:
        return CupertinoIcons.cube_box_fill;
      case 3:
        return CupertinoIcons.checkmark_circle_fill;
      case 4:
        return CupertinoIcons.xmark_circle_fill;
      default:
        return CupertinoIcons.info_circle;
    }
  }

  String _getStatusHint(int status) {
    switch (status) {
      case 0:
        return '请尽快完成付款';
      case 1:
        return '商家准备发货中';
      case 2:
        return '商品运输中，请注意查收';
      case 3:
        return '交易已完成';
      case 4:
        return '订单已取消';
      default:
        return '';
    }
  }
}

class _Action {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.label, this.color, this.onTap);
}

class _ActionButtons extends StatelessWidget {
  final List<_Action> actions;
  const _ActionButtons(this.actions);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: actions.first == a ? 0 : 8,
              right: actions.last == a ? 0 : 8,
            ),
            child: CupertinoButton(
              color: a.color,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: a.onTap,
              child: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 商城订单详情 Provider
final mallOrderDetailProvider = FutureProvider.family<MallOrder, String>((ref, orderNumber) async {
  final api = OrderApi();
  return api.getMallOrderDetail(orderNumber);
});

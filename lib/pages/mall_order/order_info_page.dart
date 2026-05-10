import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/label_api.dart';
import '../../api/order_api.dart';
import '../../models/label.dart';
import '../../models/order.dart';
import '../../models/discount_log.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'select_sales_channel_sheet.dart';

/// 商城订单详情 Provider（完整版，含网销订单）
final _mallOrderFullDetailProvider = FutureProvider.family<MallOrderFullDetail, String>((ref, orderNumber) async {
  final api = OrderApi();
  return api.getNewOrderDetailByMallNumber(orderNumber);
});

/// 商城订单详情页（完整版）
/// 路由：/mall-order/order-info/:orderNumber
class OrderInfoPage extends ConsumerStatefulWidget {
  final String orderNumber;

  const OrderInfoPage({super.key, required this.orderNumber});

  @override
  ConsumerState<OrderInfoPage> createState() => _OrderInfoPageState();
}

class _OrderInfoPageState extends ConsumerState<OrderInfoPage> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(_mallOrderFullDetailProvider(widget.orderNumber));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: const Text('订单详情', style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis, size: 24),
          onPressed: () => _showActionSheet(context),
        ),
      ),
      child: detailAsync.when(
        data: (detail) => _OrderInfoView(
          detail: detail,
          onConfirmPay: () => _confirmPay(context, detail.mallOrder),
          onShip: () => _shipOrder(context, detail.mallOrder),
          onConfirmReceive: () => _confirmReceive(context, detail.mallOrder),
          onCancel: () => _cancelOrder(context, detail.mallOrder),
          onViewPayment: () => _viewPayment(context, detail.mallOrder.number),
        ),
        loading: () => const LoadingWidget(message: '加载中...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_mallOrderFullDetailProvider(widget.orderNumber)),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Text('查看支付记录'),
            onPressed: () {
              Navigator.pop(ctx);
              _viewPayment(context, widget.orderNumber);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('联系顾客'),
            onPressed: () {
              Navigator.pop(ctx);
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
              final api = OrderApi();
              final ok = await api.mallOrderShipped(
                order.number,
                expressName: expressNameController.text.isNotEmpty ? expressNameController.text : null,
                expressNumber: expressNumberController.text.isNotEmpty ? expressNumberController.text : null,
              );
              if (ok) ref.invalidate(_mallOrderFullDetailProvider(widget.orderNumber));
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
              final api = OrderApi();
              final ok = await api.mallOrderConfirmReceived(order.number);
              if (ok) ref.invalidate(_mallOrderFullDetailProvider(widget.orderNumber));
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
              final api = OrderApi();
              bool ok;
              if (order.status == 0) {
                ok = await api.mallOrderUnpaidCancel(order.number);
              } else if (order.status == 1) {
                ok = await api.mallOrderPaidCancel(order.number);
              } else {
                return;
              }
              if (ok) {
                ref.invalidate(_mallOrderFullDetailProvider(widget.orderNumber));
              }
            },
          ),
        ],
      ),
    );
  }

  void _viewPayment(BuildContext context, String orderNumber) {
    context.push('/mall-order/payment-record-attachment/$orderNumber');
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

/// 商城订单详情视图
class _OrderInfoView extends ConsumerStatefulWidget {
  final MallOrderFullDetail detail;
  final VoidCallback onConfirmPay;
  final VoidCallback onShip;
  final VoidCallback onConfirmReceive;
  final VoidCallback onCancel;
  final VoidCallback onViewPayment;

  const _OrderInfoView({
    required this.detail,
    required this.onConfirmPay,
    required this.onShip,
    required this.onConfirmReceive,

    required this.onCancel,
    required this.onViewPayment,
  });

  MallOrder get order => detail.mallOrder;

  @override
  ConsumerState<_OrderInfoView> createState() => _OrderInfoViewState();
}

class _OrderInfoViewState extends ConsumerState<_OrderInfoView> {
  int? _localSalesChannel;
  List<int> _localLabelIDs = [];
  List<OrderLabel> _availableLabels = [];
  bool _labelsLoading = false;
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localSalesChannel = widget.detail.mallOrder.salesChannel;
    _localLabelIDs = List.from(widget.detail.mallOrder.labelIDs ?? []);
    _remarkController.text = widget.detail.mallOrder.remark ?? '';
    _loadLabels();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadLabels() async {
    setState(() => _labelsLoading = true);
    try {
      final labels = await LabelApi().listOrderLabels();
      if (mounted) setState(() => _availableLabels = labels);
    } catch (_) {
      // ignore errors
    } finally {
      if (mounted) setState(() => _labelsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final order = widget.order;
    final status = order.statusInfo;

    // 折扣审批详情
    final discountApprovalAsync = ref.watch(
      discountApprovalProvider(detail.discountApprovalZID),
    );

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

          // 订单来源（仅待支付订单可编辑）
          if (order.statusInfo == MallOrderStatusEnum.pending)
            _buildSalesChannelSection(context),

          // 标签与备注（待支付/部分支付可编辑）
          if (order.statusInfo == MallOrderStatusEnum.pending ||
              order.statusInfo == MallOrderStatusEnum.paidNotShip)
            _buildLabelRemarkSection(context),

          // 折扣审批状态（仅待支付/部分支付且有折扣审批ZID时显示）
          if (detail.needsDiscountApproval && detail.hasDiscountApproval)
            discountApprovalAsync.when(
              data: (logs) => logs.isNotEmpty
                  ? _buildDiscountApprovalSection(context, logs, ref)
                  : const SizedBox.shrink(),
              loading: () => _buildSection('折扣审批', [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CupertinoActivityIndicator(),
                ),
              ]),
              error: (_, __) => const SizedBox.shrink(),
            ),

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

          // 会员信息
          if (order.customerName != null || order.customerPhone != null)
            _buildSection('会员信息', [
              if (order.customerName != null)
                _buildInfoRow('会员姓名', order.customerName!),
              if (order.customerPhone != null)
                _buildInfoRow('会员电话', order.customerPhone!),
            ]),

          // 商品信息
          _buildSection('商品信息', [
            ...order.products.map((p) => _buildProductRow(context, p)),
            // 网销订单商品
            if (detail.netSaleOrder.isNotEmpty) ...[
              ...detail.netSaleOrder.map((ns) {
                final giveaways = ns.giveaways;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ns.orderInfo?.orderNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          '网销订单 ${ns.orderInfo!.orderNumber}',
                          style: AppText.caption.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ...ns.productInfo.map((p) => _buildNetSaleProductRow(context, p)),
                    if (ns.serviceInfo.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('服务', style: AppText.caption),
                      ),
                      ...ns.serviceInfo.map((s) => _buildServiceRow(context, s)),
                    ],
                    if (giveaways.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text('赠品', style: AppText.caption.copyWith(color: const Color(0xFFFF9500))),
                      ),
                      ...giveaways.map((g) => _buildGiveawayRow(g)),
                    ],
                  ],
                );
              }),
            ],
            Container(height: 0.5, color: AppColors.divider),
            // 价格明细
            _buildPriceRow(context, '商品总额', order.formattedOrderAmount, null),
            if (order.freightAmount != null && order.freightAmount! > 0)
              _buildPriceRow(context, '运费', '¥${(order.freightAmount! / 100).toStringAsFixed(2)}', null),
            if (order.couponAmount != null && order.couponAmount! > 0)
              _buildPriceRow(context, '优惠券', '-¥${(order.couponAmount! / 100).toStringAsFixed(2)}', const Color(0xFFFF9500)),
            if (order.coinAmount != null && order.coinAmount! > 0)
              _buildPriceRow(context, '积分抵扣', '-¥${(order.coinAmount! / 100).toStringAsFixed(2)}', const Color(0xFFFF9500)),
            if (order.discountAmount < order.orderAmount)
              _buildPriceRow(context, '折扣', '-¥${((order.orderAmount - order.discountAmount) / 100).toStringAsFixed(2)}', const Color(0xFFFF9500)),
            Container(height: 0.5, color: AppColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('实付金额', style: AppText.subtitle),
                Text(order.formattedAmount, style: AppText.subtitle.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ]),

          // 网销退货订单
          if (detail.netSaleBackOrder.isNotEmpty)
            _buildSection('退货订单', [
              ...detail.netSaleBackOrder.map((back) {
                final orderNum = back.orderInfo?.orderNumber ?? '-';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '退货单 $orderNum',
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFFF3B30)),
                      ),
                    ),
                    ...back.productInfo.map((p) => _buildNetSaleProductRow(context, p)),
                  ],
                );
              }),
            ]),

          // 优惠补贴区块（对标 PWA 优惠补贴区域）
          if ((order.cashCoupons != null && order.cashCoupons!.isNotEmpty) ||
              (order.coupons != null && order.coupons!.isNotEmpty) ||
              (order.coinAmount != null && order.coinAmount! > 0) ||
              (order.couponAmount != null && order.couponAmount! > 0))
            _buildSection('优惠补贴', [
              // 现金券
              if (order.cashCoupons != null && order.cashCoupons!.isNotEmpty) ...[
                _buildDiscountRow('使用现金券', order.cashCoupons!.fold<int>(
                    0, (sum, c) => sum + ((c['amount'] as int?) ?? 0))),
                ...order.cashCoupons!.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c['title'] as String? ?? '现金券',
                            style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel),
                          ),
                          Text(
                            '-¥${((c['amount'] as int?) ?? 0 / 100).toStringAsFixed(2)}',
                            style: AppText.caption.copyWith(color: const Color(0xFFDE2A01)),
                          ),
                        ],
                      ),
                    )),
              ],
              // 优惠券
              if (order.coupons != null && order.coupons!.isNotEmpty) ...[
                _buildDiscountRow('使用优惠券', order.coupons!.fold<int>(
                    0, (sum, c) => sum + ((c['amount'] as int?) ?? 0))),
                ...order.coupons!.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c['title'] as String? ?? '优惠券',
                            style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel),
                          ),
                          Text(
                            '-¥${((c['amount'] as int?) ?? 0 / 100).toStringAsFixed(2)}',
                            style: AppText.caption.copyWith(color: const Color(0xFFDE2A01)),
                          ),
                        ],
                      ),
                    )),
              ],
              // 积分抵扣
              if (order.coinAmount != null && order.coinAmount! > 0)
                _buildDiscountRow('使用积分', order.coinAmount!),
              // 优惠券（兼容旧数据）
              if (order.couponAmount != null && order.couponAmount! > 0 &&
                  (order.cashCoupons == null || order.cashCoupons!.isEmpty) &&
                  (order.coupons == null || order.coupons!.isEmpty))
                _buildDiscountRow('使用优惠券', order.couponAmount!),
            ]),

          // 导购信息
          if (order.employeeName != null)
            _buildSection('导购信息', [
              _buildInfoRow('导购', order.employeeName!),
              if (order.assistantName != null)
                _buildInfoRow('助理', order.assistantName!),
            ]),

          // 参与者/协销信息（已支付订单有协销人员时显示）
          // 对标 PWA 参与者区块：拉新人、分享人、企微客服等
          if (order.hasAssistant)
            _buildSection('参与者', [
              if (order.getAssistantIdent(MallOrder.assistantRecruit) != null)
                _buildInfoRow('拉新人', '员工 #${order.getAssistantIdent(MallOrder.assistantRecruit)}'),
              if (order.getAssistantIdent(MallOrder.assistantSharer) != null)
                _buildInfoRow('分享人', '员工 #${order.getAssistantIdent(MallOrder.assistantSharer)}'),
              if (order.getAssistantIdent(MallOrder.assistantQwCS) != null)
                _buildInfoRow('企微客服', '员工 #${order.getAssistantIdent(MallOrder.assistantQwCS)}'),
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
            if (order.cancelReason != null && order.cancelReason!.isNotEmpty)
              _buildInfoRow('取消原因', order.cancelReason!),
            // 网销平台信息
            if (detail.netSaleOrder.isNotEmpty && detail.netSaleOrder.first.salesNet != null) ...[
              if (detail.netSaleOrder.first.salesNet!.netSalePlatform != null)
                _buildInfoRow('网销平台', detail.netSaleOrder.first.salesNet!.netSalePlatform!),
              if (detail.netSaleOrder.first.salesNet!.netSaleNumber != null)
                _buildInfoRow('网销单号', detail.netSaleOrder.first.salesNet!.netSaleNumber!),
            ],
          ]),

          // 发票区块（对标 PWA 发票申请入口）
          _buildInvoiceSection(context, order),

          // 备注（已支付/已完成订单只读显示；待支付/部分支付订单通过标签备注区编辑）
          if ((order.remark != null && order.remark!.isNotEmpty) &&
              order.statusInfo != MallOrderStatusEnum.pending &&
              order.statusInfo != MallOrderStatusEnum.paidNotShip)
            _buildSection('备注', [
              _buildInfoRow('', order.remark!),
            ]),

          // 支付记录入口
          _buildSection('支付记录', [
            GestureDetector(
              onTap: onViewPayment,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('查看支付明细', style: AppText.body.copyWith(color: AppColors.primary)),
                  const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ]),

          const SizedBox(height: AppSpacing.xl),

          // 操作按钮
          _buildActions(context, order),
        ],
      ),
    );
  }

  /// 折扣审批区块
  Widget _buildDiscountApprovalSection(
    BuildContext context,
    List<DiscountLog> logs,
    WidgetRef ref,
  ) {
    final log = logs.first;
    final state = log.state;
    final stateColor = _getDiscountStateColor(state);
    final stateLabel = _getDiscountStateLabel(state);

    return _buildSection('折扣审批', [
      // 审批状态行
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stateLabel,
                style: AppText.body.copyWith(
                  color: stateColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            child: Row(
              children: [
                const Icon(CupertinoIcons.refresh, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '刷新状态',
                  style: AppText.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            onPressed: () => ref.invalidate(
              discountApprovalProvider(detail.discountApprovalZID),
            ),
          ),
        ],
      ),

      const SizedBox(height: AppSpacing.md),

      // 折扣信息
      if (log.associated.isNotEmpty) ...[
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        Text('折扣明细', style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel)),
        const SizedBox(height: AppSpacing.xs),
        ...log.associated.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    a.type.label,
                    style: AppText.body,
                  ),
                  Text(
                    '-¥${(a.differenceAmount / 100).toStringAsFixed(2)}',
                    style: AppText.body.copyWith(
                      color: const Color(0xFFFF9500),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('大盘价', style: AppText.body),
            Text(
              '¥${(log.limitCent / 100).toStringAsFixed(2)}',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],

      // 备注
      if (log.remarks != null && log.remarks!.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        Text('备注', style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel)),
        const SizedBox(height: AppSpacing.xs),
        Text(log.remarks!, style: AppText.body),
      ],

      // 待审核时显示提示
      if (state.isPending) ...[
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.info_circle, size: 16, color: Color(0xFFFF9500)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当前有折扣审批正在进行中，支付前请确认审批已通过。',
                  style: AppText.caption.copyWith(color: const Color(0xFFE65100)),
                ),
              ),
            ],
          ),
        ),
      ],

      // 已拒绝时显示提示
      if (state.isRejected) ...[
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.xmark_circle, size: 16, color: Color(0xFFFF3B30)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '折扣审批已被拒绝，如需继续请重新申请折扣。',
                  style: AppText.caption.copyWith(color: const Color(0xFFC62828)),
                ),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  Color _getDiscountStateColor(DiscountLogState state) {
    switch (state) {
      case DiscountLogState.autoAudit:
      case DiscountLogState.manualAudit:
        return const Color(0xFF34C759); // 绿色 - 已通过
      case DiscountLogState.pending:
        return const Color(0xFFFF9500); // 橙色 - 待审核
      case DiscountLogState.rejected:
        return const Color(0xFFFF3B30); // 红色 - 已拒绝
      case DiscountLogState.invalid:
        return CupertinoColors.systemGrey;
      case DiscountLogState.revoked:
        return CupertinoColors.systemGrey;
    }
  }

  String _getDiscountStateLabel(DiscountLogState state) {
    switch (state) {
      case DiscountLogState.autoAudit:
        return '自动审核通过';
      case DiscountLogState.manualAudit:
        return '人工审核通过';
      case DiscountLogState.pending:
        return '待审核';
      case DiscountLogState.rejected:
        return '审核拒绝';
      case DiscountLogState.invalid:
        return '已失效';
      case DiscountLogState.revoked:
        return '已撤销';
    }
  }

  /// 订单来源选择区段（仅待支付订单显示，点击可编辑）
  Widget _buildSalesChannelSection(BuildContext context) {
    final selectedType = NetSalePlatformType.fromValue(_localSalesChannel);
    final displayName = selectedType?.label ?? '请选择订单来源';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('订单来源', style: AppText.subtitle),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () async {
            final result = await SelectSalesChannelSheet.show(
              context,
              currentValue: _localSalesChannel,
            );
            if (result != null) {
              setState(() => _localSalesChannel = result);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedType == null
                          ? CupertinoColors.placeholderText
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// 标签与备注区段（待支付/部分支付订单可编辑）
  Widget _buildLabelRemarkSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('订单标签或备注', style: AppText.subtitle),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF666666).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '标签可多选',
                style: TextStyle(fontSize: 9, color: Color(0xFF666666)),
              ),
            ),
          ],
        ),
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
            children: [
              // 标签选择区
              if (_labelsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CupertinoActivityIndicator(),
                )
              else if (_availableLabels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('暂无可用标签', style: AppText.caption),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableLabels.map((label) {
                    final isSelected = _localLabelIDs.contains(label.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _localLabelIDs.remove(label.id);
                          } else {
                            _localLabelIDs.add(label.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE8F0FD)
                              : const Color(0xFFD8DADE),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          label.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? const Color(0xFF0054E9)
                                : CupertinoColors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              // 备注输入
              CupertinoTextField(
                controller: _remarkController,
                placeholder: '添加备注信息（选填）',
                maxLines: 3,
                minLines: 2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
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

  /// 优惠补贴行（金额以分为单位，自动转为元）
  Widget _buildDiscountRow(String label, int amountCent) {
    if (amountCent <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          Text(
            '-¥${(amountCent / 100).toStringAsFixed(2)}',
            style: AppText.body.copyWith(
              color: const Color(0xFFDE2A01),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, Color? valueColor) {
    final resolvedColor = valueColor ?? CupertinoColors.label.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          Text(
            value,
            style: AppText.body.copyWith(
              color: resolvedColor,
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

  /// 网销商品行
  Widget _buildNetSaleProductRow(BuildContext context, NetSaleProduct p) {
    final name = p.skuName ?? p.productName ?? '商品';
    final price = p.discountPrice ?? p.skuPrice ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: p.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(p.thumbnail!, fit: BoxFit.cover),
                  )
                : const Icon(CupertinoIcons.photo, size: 20, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('x${p.qty}', style: AppText.caption),
              ],
            ),
          ),
          Text('¥${(price / 100).toStringAsFixed(2)}', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 网销服务行
  Widget _buildServiceRow(BuildContext context, NetSaleService s) {
    final name = s.serviceName ?? '服务';
    final price = s.discountPrice ?? s.servicePrice ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(CupertinoIcons.star_circle, size: 20, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: AppText.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text('¥${(price / 100).toStringAsFixed(2)}', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 赠品行
  Widget _buildGiveawayRow(GiveawayItem g) {
    final isService = g.itemType == GiveawayItemType.service;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isService ? '赠送服务' : '赠送商品',
              style: AppText.caption.copyWith(color: const Color(0xFFFF9500), fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isService ? '服务 #${g.serviceId}' : '商品 #${g.skuId}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 发票区块：对标 PWA 发票申请入口
  /// - 有发票号：显示发票号 + 查看详情链接
  /// - 无发票号 + 订单已完成：显示"申请开票"按钮
  Widget _buildInvoiceSection(BuildContext context, MallOrder order) {
    final hasInvoice = order.invoiceNumber != null && order.invoiceNumber!.isNotEmpty;
    // 可申请开票的订单状态：已完成(3)、已出库(2)
    final canApplyInvoice = order.status == 3 || order.status == 2;

    if (!hasInvoice && !canApplyInvoice) return const SizedBox.shrink();

    return _buildSection('发票', [
      if (hasInvoice) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('发票号', style: AppText.body),
            GestureDetector(
              onTap: () {
                // 导航到发票详情页（如果有发票ID可传入）
                // 目前只有发票号，导航到发票列表并搜索该单号
                context.push('/invoice/list?keyword=${order.invoiceNumber}');
              },
              child: Row(
                children: [
                  Text(
                    order.invoiceNumber!,
                    style: AppText.body.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ] else ...[
        // 无发票 + 可申请：显示申请按钮
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.doc_text, size: 20, color: Color(0xFF0A84FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('可申请开票', style: AppText.body.copyWith(color: const Color(0xFF0A84FF))),
                    Text('订单已完成，可申请开具发票', style: AppText.caption.copyWith(color: const Color(0xFF0A84FF).withValues(alpha: 0.7))),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(16),
                minSize: 0,
                onPressed: () {
                  // 导航到发票申请页，携带订单号参数
                  context.push('/invoice/application?orderNumber=${order.number}');
                },
                child: const Text('申请开票', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    ]);
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

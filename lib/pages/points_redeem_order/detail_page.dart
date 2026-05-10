import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/points_redeem_order_api.dart';
import '../../models/points_redeem_order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 积分兑换订单详情页
class PointsRedeemOrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const PointsRedeemOrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<PointsRedeemOrderDetailPage> createState() =>
      _PointsRedeemOrderDetailPageState();
}

class _PointsRedeemOrderDetailPageState
    extends ConsumerState<PointsRedeemOrderDetailPage> {
  final PointsRedeemOrderApi _api = PointsRedeemOrderApi();

  PointsRedeemOrder? _order;
  bool _isLoading = true;
  bool _isOperating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final order = await _api.detail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(int? ts) {
    if (ts == null || ts == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(PointsRedeemOrderStatus status) {
    switch (status) {
      case PointsRedeemOrderStatus.unpaid:
        return const Color(0xFFFF9500);
      case PointsRedeemOrderStatus.paid:
        return const Color(0xFF007AFF);
      case PointsRedeemOrderStatus.completed:
        return const Color(0xFF30D158);
      case PointsRedeemOrderStatus.expired:
      case PointsRedeemOrderStatus.refunded:
        return CupertinoColors.systemGrey;
      case PointsRedeemOrderStatus.applyForRefund:
        return const Color(0xFFFF3B30);
    }
  }

  Future<void> _showAddRemarkDialog() async {
    final textController = TextEditingController();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('添加备注'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: textController,
            placeholder: '请输入备注内容',
            maxLines: 4,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (textController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true || textController.text.trim().isEmpty) return;
    textController.text = textController.text.trim();

    if (_isOperating) return;
    setState(() => _isOperating = true);
    try {
      final success = await _api.addRemarks(widget.orderId, textController.text);
      if (mounted) {
        if (success) {
          _loadData();
        } else {
          _showError('添加备注失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('添加备注失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  Future<void> _doAction(
    String title,
    String confirmText,
    Future<bool> Function() action,
  ) async {
    if (_isOperating) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(confirmText),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isOperating = true);
    try {
      final success = await action();
      if (mounted) {
        if (success) {
          _loadData();
        } else {
          _showError('操作失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('操作失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('积分兑换单'),
        previousPageTitle: '返回',
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _order == null
                ? const Center(child: Text('未找到该订单'))
                : Column(
                    children: [
                      Expanded(child: _buildContent(_order!)),
                      _buildBottomActions(_order!),
                    ],
                  ),
      ),
    );
  }

  Widget _buildContent(PointsRedeemOrder order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 单据信息
          _SectionTitle(title: '单据信息'),
          _Card([
            _InfoRow(label: '兑换单号', value: order.number),
            _Divider(),
            _InfoRow(label: '创建时间', value: _formatTime(order.createdAt)),
            _Divider(),
            _InfoRow(
              label: '状态',
              value: order.status.label,
              valueColor: _statusColor(order.status),
            ),
            _Divider(),
            _InfoRow(
              label: '兑换部门',
              value: order.departmentId != null ? '部门ID: ${order.departmentId}' : '无',
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // 用户信息
          _SectionTitle(title: '用户信息'),
          _Card([
            _InfoRow(label: '用户ID', value: '${order.customer}'),
          ]),
          const SizedBox(height: AppSpacing.md),

          // 兑换商品
          _SectionTitle(title: '兑换商品'),
          _Card([
            _InfoRow(
              label: '商品ID',
              value: order.skuId != null
                  ? 'SKU: ${order.skuId}'
                  : order.serviceId != null
                      ? '服务: ${order.serviceId}'
                      : '商品: ${order.productItemId}',
            ),
            _Divider(),
            _InfoRow(
              label: '金额数量',
              value: '',
              child: Row(
                children: [
                  Text(
                    '${order.points}积分',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                  ),
                  if (order.payAmountCents != null && order.payAmountCents! > 0) ...[
                    const Text(' + ', style: TextStyle(color: Color(0xFF999999))),
                    Text(
                      '¥${(order.payAmountCents! / 100).toStringAsFixed(2)}元',
                      style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13),
                    ),
                  ],
                  const Text(' x1', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),

          // 职员备注
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: '职员备注'),
              if (!(_isOperating))
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _showAddRemarkDialog,
                  child: const Text(
                    '添加',
                    style: TextStyle(fontSize: 14, color: Color(0xFF007AFF)),
                  ),
                ),
            ],
          ),
          if (order.remarks.isEmpty)
            _Card([_InfoRow(label: '', value: '暂无备注', valueColor: CupertinoColors.secondaryLabel)])
          else
            ...order.remarks.map((r) => _Card([
                  _InfoRow(label: '时间', value: _formatTime(r.createdAt)),
                  _Divider(),
                  _InfoRow(label: '人员', value: 'ID: ${r.employee}'),
                  _Divider(),
                  _InfoRow(label: '内容', value: r.remarks),
                ])).expand((w) => [w, const SizedBox(height: AppSpacing.sm)]),
        ],
      ),
    );
  }

  Widget _buildBottomActions(PointsRedeemOrder order) {
    if (order.status == PointsRedeemOrderStatus.applyForRefund) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: _isOperating
                      ? null
                      : () => _doAction(
                            '退款确认',
                            '确认通过退款审核？',
                            () => _api.auditRefund(order.id),
                          ),
                  child: _isOperating
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('退款'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: _isOperating
                      ? null
                      : () => _doAction(
                            '取消退款',
                            '确认取消该退款申请？',
                            () => _api.rejectRefund(order.id),
                          ),
                  child: const Text('取消退款'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (order.status == PointsRedeemOrderStatus.paid) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                // 跳转零售单，URL参数对应 PWA navigate('../store-retail/sales-order-details?...')
                final skuId = order.skuId;
                final serviceId = order.serviceId;
                final params = {
                  'ident': order.customer.toString(),
                  'pointsRedeemOrderID': order.id.toString(),
                  if (skuId != null) 'pointsRedeemOrderSkuID': skuId.toString(),
                  if (serviceId != null) 'pointsRedeemOrderServiceID': serviceId.toString(),
                };
                final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
                context.push('/store-retail/order/${order.customer}?$query');
              },
              child: const Text('创建零售单'),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── 小组件 ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppText.body.copyWith(
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? child;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppText.caption.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: child ??
                Text(
                  value,
                  style: TextStyle(fontSize: 13, color: valueColor ?? const Color(0xFF333333)),
                ),
          ),
        ],
      ),
    );
  }
}

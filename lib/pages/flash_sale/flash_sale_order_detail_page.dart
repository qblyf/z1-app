import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/flash_sale_order_api.dart';
import '../../api/order_api.dart';
import '../../models/flash_sale_order.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 秒杀订单详情页
class FlashSaleOrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const FlashSaleOrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<FlashSaleOrderDetailPage> createState() =>
      _FlashSaleOrderDetailPageState();
}

class _FlashSaleOrderDetailPageState
    extends ConsumerState<FlashSaleOrderDetailPage> {
  final FlashSaleOrderApi _api = FlashSaleOrderApi();
  final OrderApi _orderApi = OrderApi();
  FlashSaleOrder? _order;
  MallOrderFullDetail? _mallOrderDetail;
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
      final order = await _api.detailById(widget.orderId);
      if (!mounted || order == null) return;
      // 如果有商城单号，加载商城订单详情（含营业员信息）
      MallOrderFullDetail? mallDetail;
      final mallOrderNumber = order.mallOrder ?? '';
      if (mallOrderNumber.isNotEmpty) {
        try {
          mallDetail = await _orderApi.getNewOrderDetailByMallNumber(mallOrderNumber);
        } catch (_) {
          // 商城详情加载失败不影响主流程
        }
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _mallOrderDetail = mallDetail;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 执行操作（退款/取消退款/处理）
  Future<void> _doAction(
    String title,
    String confirmText,
    Future<bool> Function() action,
  ) async {
    if (_isOperating) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(confirmText),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
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
          await _loadData();
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

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        middle: const Text('秒杀订单详情'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _order == null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('加载失败，请重试', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _loadData,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 单据信息
          _SectionTitle(title: '单据信息'),
          _InfoCard(
            children: [
              _InfoRow(label: '秒杀单号', value: order.number),
              _InfoRow(
                label: '状态',
                value: order.statusLabel,
                valueColor: _getStatusColor(order.statusEnum),
              ),
              _InfoRow(label: '创建时间', value: _formatTime(order.createdAt)),
              _InfoRow(label: '订单金额', value: '¥${order.amountYuan}'),
              _InfoRow(label: '处理部门ID', value: '${order.department}'),
              if (_mallOrderDetail?.mallOrder.sellerIdent != null)
                _InfoRow(label: '营业员', value: '员工 #${_mallOrderDetail!.mallOrder.sellerIdent}'),
              if (_mallOrderDetail?.mallOrder.shoppingGuide != null)
                _InfoRow(label: '专属导购', value: '员工 #${_mallOrderDetail!.mallOrder.shoppingGuide}'),
              if (order.mallOrder != null)
                _InfoRow(
                  label: '商城处理单号',
                  value: order.mallOrder!,
                  valueColor: const Color(0xFF0A84FF),
                  onTap: () {
                    // 跳转到商城订单详情
                    context.push('/mall-order/order-info?number=${Uri.encodeComponent(order.mallOrder!)}');
                  },
                ),
              if (order.toOrderAt != null)
                _InfoRow(label: '完成时间', value: _formatTime(order.toOrderAt)),
            ],
          ),

          // 用户信息
          _SectionTitle(title: '用户信息'),
          _InfoCard(
            children: [
              _InfoRow(label: '用户ID', value: '${order.customer}'),
              if (order.sharer != null)
                _InfoRow(label: '分享人ID', value: '${order.sharer}'),
            ],
          ),

          // 订单备注
          _SectionTitle(title: '订单备注'),
          _InfoCard(
            children: [
              _InfoRow(
                label: '备注',
                value: order.remarks?.isNotEmpty == true ? order.remarks! : '-',
              ),
              if (order.refundReason != null &&
                  order.refundReason!.isNotEmpty)
                _InfoRow(label: '退款原因', value: order.refundReason!),
            ],
          ),

          // 商品信息
          _SectionTitle(title: '订单商品'),
          _InfoCard(
            children: [
              _InfoRow(label: 'SKU ID', value: '${order.skuId}'),
              _InfoRow(label: '金额', value: '¥${order.amountYuan} x 1'),
              _InfoRow(label: '应付金额', value: '¥${order.amountYuan}', valueColor: const Color(0xFFFF3B30)),
            ],
          ),

          // 支付方式
          _SectionTitle(title: '支付方式'),
          _InfoCard(
            children: [
              _InfoRow(
                label: '实付金额',
                value: order.isPaid ? '¥${order.amountYuan}' : '¥0.00',
                valueColor: order.isPaid
                    ? const Color(0xFFFE9E2D)
                    : const Color(0xFF8E8E93),
              ),
              if (order.payment != null)
                _InfoRow(label: '支付流水号', value: order.payment!.content),
              if (order.payAt != null)
                _InfoRow(label: '支付时间', value: _formatTime(order.payAt)),
            ],
          ),

          // 操作按钮
          _buildActionButtons(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final order = _order!;
    final buttons = <Widget>[];

    if (order.canRefund) {
      // 申请退款状态：显示"退款"和"取消退款"按钮
      buttons.add(_ActionButton(
        label: '确认退款',
        color: const Color(0xFF34C759),
        isLoading: _isOperating,
        onPressed: () => _doAction(
          '确认退款',
          '确认同意退款？',
          () => _api.auditRefund(order.id),
        ),
      ));
      buttons.add(_ActionButton(
        label: '取消退款',
        color: const Color(0xFF8E8E93),
        isLoading: _isOperating,
        onPressed: () => _doAction(
          '取消退款',
          '确认取消退款申请？',
          () => _api.cancelRefund(order.id),
        ),
      ));
    }

    if (order.canProcess) {
      // 已完成但未转商城单：显示处理按钮
      buttons.add(_ActionButton(
        label: '处理秒杀单',
        color: const Color(0xFF007AFF),
        isLoading: _isOperating,
        onPressed: () => _doAction(
          '处理秒杀单',
          '确认将秒杀单转为商城处理单？',
          () => _api.addMallOrder(order.number),
        ),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(FlashSaleOrderStatus? status) {
    switch (status) {
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
}

/// 区块标题
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppText.body.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
        ),
      ),
    );
  }
}

/// 信息卡片
class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Text(label, style: AppText.body),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? const Color(0xFF636366),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: row,
      );
    }
    return row;
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: color,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

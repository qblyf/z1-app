import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/recycle_order_api.dart';
import '../../api/commission_api.dart';
import '../../models/recycle_order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 营业员回收订单详情页
/// 显示回收订单详情 + 提成信息（面向营业员视图）
class SalespersonRecycleOrderInfoPage extends ConsumerStatefulWidget {
  final String orderNumber;

  const SalespersonRecycleOrderInfoPage({
    super.key,
    required this.orderNumber,
  });

  @override
  ConsumerState<SalespersonRecycleOrderInfoPage> createState() =>
      _SalespersonRecycleOrderInfoPageState();
}

class _SalespersonRecycleOrderInfoPageState
    extends ConsumerState<SalespersonRecycleOrderInfoPage> {
  final RecycleOrderApi _recycleApi = RecycleOrderApi();
  final CommissionApi _commissionApi = CommissionApi();

  RecycleOrder? _order;
  List<CommissionOrderItem> _commissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 并行加载订单详情和提成数据
      final now = DateTime.now();
      final results = await Future.wait([
        _recycleApi.detail(widget.orderNumber),
        _commissionApi.getOrderCommission(
          orderNumber: widget.orderNumber,
          minCreatedAt: DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000,
          maxCreatedAt: now.millisecondsSinceEpoch ~/ 1000,
        ),
      ]);

      final order = results[0] as RecycleOrder?;
      final commissions = results[1] as List<CommissionOrderItem>;

      if (mounted) {
        setState(() {
          _order = order;
          _commissions = commissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatFen(int fen) {
    if (fen >= 0) {
      return '¥${(fen / 100).toStringAsFixed(2)}';
    }
    return '-¥${((-fen) / 100).toStringAsFixed(2)}';
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
        middle: const Text('回收订单详情'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : () => _showActionSheet(context),
          child: const Icon(CupertinoIcons.ellipsis),
        ),
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载中...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }

    if (_order == null) {
      return const AppErrorWidget(message: '未找到订单');
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final order = _order!;
    final stateColor = _getStateColor(order.stateEnum);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: stateColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_getStateIcon(order.stateEnum), color: stateColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.stateLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: stateColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '单号: ${order.number}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 单据信息
          _SectionCard(
            title: '单据信息',
            children: [
              _Row('回收单号', order.number),
              _Row('创建时间', _formatTime(order.createdAt)),
              _Row('回收状态', order.stateLabel),
            ],
          ),

          // 会员信息
          _SectionCard(
            title: '会员信息',
            children: [
              _Row('会员ID', '${order.customer}'),
            ],
          ),

          // 商品信息
          _SectionCard(
            title: '商品信息',
            children: [
              _Row('商品名称', order.ruleTitle),
              if (order.specification.isNotEmpty)
                _Row('规格', order.specification.join(' / ')),
              if (order.serial.isNotEmpty)
                _Row('串号', order.serial),
              _Row('系统估价', '¥${order.costAmountYuan}'),
              _Row(
                '回收价',
                '¥${order.actualAmountYuan}',
                valueColor: const Color(0xFFFF3B30),
              ),
              if (order.platformPrice != null)
                _Row(
                  '售出金额',
                  '¥${order.platformPriceYuan}',
                  valueColor: const Color(0xFF34C759),
                ),
              if (order.operator > 0)
                _Row('回收人', 'ID: ${order.operator}'),
              if (order.inspector != null && order.inspector! > 0)
                _Row('复检人', 'ID: ${order.inspector}'),
            ],
          ),

          // 调拨信息
          if (order.outDept != null || order.inDept != null)
            _SectionCard(
              title: '调拨信息',
              children: [
                if (order.outDept != null)
                  _Row('调出部门', 'ID: ${order.outDept}'),
                if (order.transferOutTime != null)
                  _Row('调出时间', _formatTime(order.transferOutTime)),
                if (order.inDept != null)
                  _Row('调入部门', 'ID: ${order.inDept}'),
                if (order.transferInTime != null)
                  _Row('接收时间', _formatTime(order.transferInTime)),
              ],
            ),

          // 交易信息
          _SectionCard(
            title: '交易信息',
            children: [
              if (order.payInfo != null && order.payInfo!.isNotEmpty)
                _Row('支付信息', order.payInfo!),
              _Row('支付方式', order.paymentType),
            ],
          ),

          // 提成信息
          _SectionCard(
            title: '提成信息',
            children: [
              if (_commissions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '暂无提成数据',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                )
              else ...[
                for (final commission in _commissions) ...[
                  _Row(
                    '订单提成',
                    _formatFen(commission.price),
                    valueColor: commission.price >= 0
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.destructiveRed,
                  ),
                  if (commission.totalCommissionPrice != null &&
                      commission.totalCommissionPrice != 0)
                    _Row(
                      '总提成',
                      _formatFen(commission.totalCommissionPrice!),
                      valueColor: CupertinoColors.activeBlue,
                      isBold: true,
                    ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/store-retail/recycle-order/detail/${widget.orderNumber}');
            },
            child: const Text('查看完整详情'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Color _getStateColor(RecycleOrderState? state) {
    switch (state) {
      case RecycleOrderState.unpaid:
        return CupertinoColors.activeOrange;
      case RecycleOrderState.paid:
        return CupertinoColors.activeBlue;
      case RecycleOrderState.transfer:
        return CupertinoColors.systemPurple;
      case RecycleOrderState.notRechecked:
        return CupertinoColors.systemYellow;
      case RecycleOrderState.rechecked:
        return CupertinoColors.activeGreen;
      case RecycleOrderState.nonStandardGoods:
        return CupertinoColors.systemIndigo;
      case RecycleOrderState.vendor:
        return CupertinoColors.systemTeal;
      case RecycleOrderState.vendorSold:
        return CupertinoColors.systemGreen;
      case RecycleOrderState.undone:
        return CupertinoColors.systemGrey;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStateIcon(RecycleOrderState? state) {
    switch (state) {
      case RecycleOrderState.unpaid:
        return CupertinoIcons.clock;
      case RecycleOrderState.paid:
        return CupertinoIcons.checkmark_circle;
      case RecycleOrderState.transfer:
        return CupertinoIcons.cube_box;
      case RecycleOrderState.notRechecked:
        return CupertinoIcons.exclamationmark_circle;
      case RecycleOrderState.rechecked:
        return CupertinoIcons.checkmark_seal;
      case RecycleOrderState.nonStandardGoods:
        return CupertinoIcons.exclamationmark_triangle;
      case RecycleOrderState.vendor:
        return CupertinoIcons.bag;
      case RecycleOrderState.vendorSold:
        return CupertinoIcons.money_dollar_circle;
      case RecycleOrderState.undone:
        return CupertinoIcons.xmark_circle;
      default:
        return CupertinoIcons.question_circle;
    }
  }
}

// ================================================================
// 辅助组件
// ================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.card,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _Row(
    this.label,
    this.value, {
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 18 : 14,
              color: valueColor ?? CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

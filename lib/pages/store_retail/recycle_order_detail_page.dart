import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/recycle_order_api.dart';
import '../../models/recycle_order.dart';
import '../../theme/app_theme.dart';

/// 回收订单详情页
class RecycleOrderDetailPage extends ConsumerStatefulWidget {
  final String orderNumber;

  const RecycleOrderDetailPage({
    super.key,
    required this.orderNumber,
  });

  @override
  ConsumerState<RecycleOrderDetailPage> createState() =>
      _RecycleOrderDetailPageState();
}

class _RecycleOrderDetailPageState
    extends ConsumerState<RecycleOrderDetailPage> {
  final RecycleOrderApi _api = RecycleOrderApi();
  RecycleOrder? _order;
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
      final order = await _api.detail(widget.orderNumber);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 执行状态操作
  Future<void> _doAction(
    String title,
    Future<bool> Function() action,
  ) async {
    if (_isOperating) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: const Text('此操作不可撤回，是否继续？'),
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

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('回收订单详情'),
        trailing: _isLoading
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // TODO: 显示更多操作菜单
                },
                child: const Icon(CupertinoIcons.ellipsis),
              ),
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
              color: stateColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: stateColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStateIcon(order.stateEnum),
                  color: stateColor,
                  size: 28,
                ),
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
                        '订单号: ${order.number}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 会员信息
          _SectionTitle(title: '顾客信息'),
          _InfoCard(
            children: [
              _InfoRow(label: '顾客ID', value: '${order.customer}'),
              _InfoRow(
                label: '创建时间',
                value: _formatTime(order.createdAt),
              ),
            ],
          ),

          // 商品信息
          _SectionTitle(title: '商品信息'),
          _InfoCard(
            children: [
              _InfoRow(label: '商品名称', value: order.ruleTitle),
              if (order.specification.isNotEmpty)
                _InfoRow(
                  label: '规格',
                  value: order.specification.join(' / '),
                ),
              _InfoRow(label: '串号', value: order.serial),
              _InfoRow(label: '系统估价', value: '¥${order.costAmountYuan}'),
              _InfoRow(
                label: '回收价',
                value: '¥${order.actualAmountYuan}',
                valueColor: const Color(0xFFFF3B30),
              ),
              if (order.platformPrice != null)
                _InfoRow(
                  label: '售出金额',
                  value: '¥${order.platformPriceYuan}',
                  valueColor: const Color(0xFF34C759),
                ),
              _InfoRow(label: '支付方式', value: order.paymentType),
              if (order.payInfo != null && order.payInfo!.isNotEmpty)
                _InfoRow(label: '交易信息', value: order.payInfo!),
            ],
          ),

          // 调拨信息（已付款后的状态显示）
          if (order.stateEnum != RecycleOrderState.unpaid) ...[
            _SectionTitle(title: '调拨信息'),
            _InfoCard(
              children: [
                _InfoRow(
                  label: '调出时间',
                  value: _formatTime(order.transferOutTime),
                ),
                _InfoRow(
                  label: '调入时间',
                  value: _formatTime(order.transferInTime),
                ),
                _InfoRow(
                  label: '接收时间',
                  value: _formatTime(order.transferInTime),
                ),
                if (order.recheckedTime != null)
                  _InfoRow(
                    label: '复检时间',
                    value: _formatTime(order.recheckedTime),
                  ),
              ],
            ),
          ],

          // 复检信息
          if (order.stateEnum == RecycleOrderState.rechecked ||
              order.stateEnum == RecycleOrderState.vendor ||
              order.stateEnum == RecycleOrderState.vendorSold) ...[
            _SectionTitle(title: '复检信息'),
            _InfoCard(
              children: [
                _InfoRow(
                  label: '复检差异',
                  value: order.recheckDifference != 0
                      ? '¥${(order.recheckDifference / 100).toStringAsFixed(2)}'
                      : '无差异',
                  valueColor: order.recheckDifference > 0
                      ? const Color(0xFF34C759)
                      : order.recheckDifference < 0
                          ? const Color(0xFFFF3B30)
                          : null,
                ),
                if (order.inspector != null && order.inspector != 0)
                  _InfoRow(label: '复检人', value: 'ID: ${order.inspector}'),
              ],
            ),
          ],

          // 更新时间
          if (order.updatedAt != null) ...[
            _SectionTitle(title: '其他信息'),
            _InfoCard(
              children: [
                _InfoRow(
                  label: '更新时间',
                  value: _formatTime(order.updatedAt),
                ),
              ],
            ),
          ],

          // 操作按钮
          if (_order != null) _buildActionButtons(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final order = _order!;
    final buttons = <Widget>[];

    // 根据状态显示不同操作按钮
    switch (order.stateEnum) {
      case RecycleOrderState.unpaid:
        buttons.add(_ActionButton(
          label: '确认打款',
          color: const Color(0xFF34C759),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认打款',
            () => _api.paid(
              number: order.number,
              accountId: 1, // TODO: 选择账户
            ),
          ),
        ));
        buttons.add(_ActionButton(
          label: '撤销订单',
          color: const Color(0xFFFF3B30),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认撤销订单',
            () => _api.undone(order.number),
          ),
        ));
        break;

      case RecycleOrderState.paid:
        buttons.add(_ActionButton(
          label: '发起调拨',
          color: const Color(0xFF007AFF),
          isLoading: _isOperating,
          onPressed: () => _showTransferSheet(order.number),
        ));
        buttons.add(_ActionButton(
          label: '撤销订单',
          color: const Color(0xFFFF3B30),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认撤销订单',
            () => _api.undone(order.number),
          ),
        ));
        break;

      case RecycleOrderState.transfer:
        buttons.add(_ActionButton(
          label: '确认接机',
          color: const Color(0xFF34C759),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认接机（售后确认）',
            () => _api.notRechecked(order.number),
          ),
        ));
        break;

      case RecycleOrderState.notRechecked:
        buttons.add(_ActionButton(
          label: '完成复检',
          color: const Color(0xFF34C759),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认复检完成',
            () => _api.rechecked(order.number),
          ),
        ));
        break;

      case RecycleOrderState.rechecked:
        buttons.add(_ActionButton(
          label: '转非标准品',
          color: const Color(0xFFFF9500),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认转为非标准品',
            () => _api.notStandardGoods(order.number),
          ),
        ));
        buttons.add(_ActionButton(
          label: '发起拍卖',
          color: const Color(0xFF007AFF),
          isLoading: _isOperating,
          onPressed: () {
            // TODO: 显示渠道选择弹框
            _showError('请在PC端选择渠道');
          },
        ));
        break;

      case RecycleOrderState.vendor:
        buttons.add(_ActionButton(
          label: '确认已售出',
          color: const Color(0xFF34C759),
          isLoading: _isOperating,
          onPressed: () => _showVendorSoldSheet(order.number),
        ));
        buttons.add(_ActionButton(
          label: '撤销',
          color: const Color(0xFFFF3B30),
          isLoading: _isOperating,
          onPressed: () => _doAction(
            '确认撤销（恢复为已复检）',
            () => _api.vendorToRechecked(order.number),
          ),
        ));
        break;

      default:
        break;
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

  void _showTransferSheet(String number) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('选择调入部门'),
        message: const Text('请选择接收部门（该功能需在PC端操作）'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showError('请在PC端选择调入部门');
            },
            child: const Text('选择部门'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showVendorSoldSheet(String number) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('确认售出'),
        message: const Text('请在PC端完成售出操作并填写收款账户和金额'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showError('请在PC端完成售出操作');
            },
            child: const Text('去PC端操作'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Color _getStateColor(RecycleOrderState? state) {
    switch (state) {
      case RecycleOrderState.unpaid:
        return const Color(0xFFFF9500);
      case RecycleOrderState.paid:
        return const Color(0xFF34C759);
      case RecycleOrderState.transfer:
        return const Color(0xFF5856D6);
      case RecycleOrderState.notRechecked:
        return const Color(0xFFFF3B30);
      case RecycleOrderState.rechecked:
        return const Color(0xFF34C759);
      case RecycleOrderState.nonStandardGoods:
        return const Color(0xFFFF2D55);
      case RecycleOrderState.vendor:
        return const Color(0xFF007AFF);
      case RecycleOrderState.vendorSold:
        return const Color(0xFF34C759);
      case RecycleOrderState.undone:
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  IconData _getStateIcon(RecycleOrderState? state) {
    switch (state) {
      case RecycleOrderState.unpaid:
        return CupertinoIcons.clock;
      case RecycleOrderState.paid:
        return CupertinoIcons.checkmark_circle;
      case RecycleOrderState.transfer:
        return CupertinoIcons.arrow_right_arrow_left;
      case RecycleOrderState.notRechecked:
        return CupertinoIcons.exclamationmark_triangle;
      case RecycleOrderState.rechecked:
        return CupertinoIcons.checkmark_seal;
      case RecycleOrderState.nonStandardGoods:
        return CupertinoIcons.exclamationmark_circle;
      case RecycleOrderState.vendor:
        return CupertinoIcons.globe;
      case RecycleOrderState.vendorSold:
        return CupertinoIcons.money_dollar_circle;
      case RecycleOrderState.undone:
        return CupertinoIcons.xmark_circle;
      default:
        return CupertinoIcons.info_circle;
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

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        ],
      ),
    );
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

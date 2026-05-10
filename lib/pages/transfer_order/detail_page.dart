import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/transfer_order_api.dart';
import '../../models/transfer_order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 调拨单详情页
class TransferOrderDetailPage extends ConsumerStatefulWidget {
  final int orderID;

  const TransferOrderDetailPage({super.key, required this.orderID});

  @override
  ConsumerState<TransferOrderDetailPage> createState() =>
      _TransferOrderDetailPageState();
}

class _TransferOrderDetailPageState
    extends ConsumerState<TransferOrderDetailPage> {
  TransferOrder? _order;
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
      final api = TransferOrderApi();
      final order = await api.detail(widget.orderID);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _audit() async {
    final confirmed = await _confirm('审核通过', '确认审核通过此调拨单？');
    if (!confirmed) return;
    setState(() => _isOperating = true);
    try {
      final ok = await TransferOrderApi().audit(widget.orderID);
      _showMsg(ok ? '审核成功' : '审核失败');
      if (ok) _loadData();
    } catch (e) {
      _showMsg('审核失败：$e');
    } finally {
      setState(() => _isOperating = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('拒绝调拨单'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: reasonController,
              placeholder: '拒绝原因（可选）',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('拒绝'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isOperating = true);
    try {
      final ok = await TransferOrderApi().reject(
        widget.orderID,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
      );
      _showMsg(ok ? '已拒绝' : '操作失败');
      if (ok) _loadData();
    } catch (e) {
      _showMsg('操作失败：$e');
    } finally {
      setState(() => _isOperating = false);
    }
  }

  Future<bool> _confirm(String title, String msg) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text('确认'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMsg(String msg) {
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

  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _audit();
            },
            child: const Text('审核通过'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _reject();
            },
            child: const Text('拒绝'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
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
        middle: Text(_order?.transferOrderNumber ?? '调拨单详情'),
        trailing: _order != null &&
                _order!.status == TransferOrderStatus.pending
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isOperating ? null : _showActionSheet,
                child: _isOperating
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.ellipsis),
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _order == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_right_arrow_left,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('未找到调拨单', style: AppText.caption),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final statusColor = Color(order.status.colorValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 状态卡片
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    order.status == TransferOrderStatus.approved
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.clock,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.status.label,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(order.transferOrderNumber ?? '',
                          style: AppText.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${order.totalQuantity} 件',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text('共 ${order.products.length} 种商品',
                        style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 调拨流向
          _SectionTitle('调拨流向'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.arrow_up_circle_fill,
                          color: Color(0xFFFF3B30), size: 32),
                      const SizedBox(height: 8),
                      Text('调出部门', style: AppText.caption),
                      const SizedBox(height: 4),
                      Text(
                        order.fromDepartmentName ?? '部门${order.fromDepartmentID}',
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Icon(CupertinoIcons.arrow_right,
                      color: AppColors.textTertiary, size: 32),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.arrow_down_circle_fill,
                          color: Color(0xFF30D158), size: 32),
                      const SizedBox(height: 8),
                      Text('调入部门', style: AppText.caption),
                      const SizedBox(height: 4),
                      Text(
                        order.toDepartmentName ?? '部门${order.toDepartmentID}',
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 基本信息
          _SectionTitle('基本信息'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _InfoRow('仓库', order.warehouseName ?? '仓库${order.warehouseID}'),
                _InfoRow('调拨类型', order.type.label),
                _InfoRow('创建人', order.creatorName ?? '-'),
                _InfoRow('创建时间', order.formattedCreatedAt),
                if (order.remarks != null && order.remarks!.isNotEmpty)
                  _InfoRow('备注', order.remarks!),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 商品列表
          _SectionTitle('调拨明细（共 ${order.products.length} 种）'),
          const SizedBox(height: 8),
          ...order.products.map((p) => _ProductItem(product: p)),

          // 审核信息
          if (order.auditedAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionTitle('审核信息'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  _InfoRow('审核人', order.auditedByName ?? '-'),
                  _InfoRow('审核时间', _formatTime(order.auditedAt!)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppText.label);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: AppText.caption)),
          Expanded(child: Text(value, style: AppText.body)),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final TransferOrderProduct product;

  const _ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(product.thumbnail!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                              CupertinoIcons.cube_box_fill,
                              color: Color(0xFF5E5CE6),
                            )),
                  )
                : const Icon(CupertinoIcons.cube_box_fill,
                    color: Color(0xFF5E5CE6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.displayName,
              style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '×${product.quantity}',
              style: const TextStyle(
                color: Color(0xFF5E5CE6),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

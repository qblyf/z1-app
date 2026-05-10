import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/ahs_api.dart';
import '../../models/ahs_order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 掌上回收单详情页
class PalmRecycleOrderDetailPage extends ConsumerStatefulWidget {
  final String orderNumber;

  const PalmRecycleOrderDetailPage({
    super.key,
    required this.orderNumber,
  });

  @override
  ConsumerState<PalmRecycleOrderDetailPage> createState() =>
      _PalmRecycleOrderDetailPageState();
}

class _PalmRecycleOrderDetailPageState
    extends ConsumerState<PalmRecycleOrderDetailPage> {
  final AhsApi _api = AhsApi();
  AhsOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final order = await _api.getOrderInfo(widget.orderNumber);
      if (mounted) {
        setState(() {
          _order = order;
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('掌上回收单详情'),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(height: 16),
            Text('未获取到该掌上回收单数据'),
          ],
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 掌上回收单信息
          _buildSection('掌上回收单信息', [
            _buildRow('回收单号', _order!.orderNumber ?? '-'),
            _buildRow('回收单状态', _buildStatusBadge(_order!.status)),
            _buildRow('回收人', _buildEmployeeInfo(_order!.emplIdent)),
            _buildRow('回收部门', _buildDeptInfo(_order!.departmentId)),
            _buildRow('回收时间', _buildTime(_order!.createdAt)),
          ]),

          const SizedBox(height: 16),

          // 顾客信息
          _buildSection('顾客信息', [
            _buildRow('顾客姓名', _buildUserInfo(_order!.userIdent, 'name')),
            _buildRow('联系方式', _buildUserInfo(_order!.userIdent, 'phone')),
          ]),

          const SizedBox(height: 16),

          // 商品信息
          _buildSection('商品信息', [
            _buildProductInfo(),
            const SizedBox(height: 12),
            _buildRow('序列号1', _order!.serial ?? '-'),
            _buildRow(
              '序列号2',
              _order!.imeis?.isNotEmpty == true
                  ? _order!.imeis!.join('，')
                  : '-',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRow(String label, dynamic value) {
    final isLast = label == '回收时间' ||
        label == '联系方式' ||
        label == '序列号2';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.5,
                ),
              ),
      ),
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
          if (value is Widget)
            value
          else
            Flexible(
              child: Text(
                value?.toString() ?? '-',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    final priceStr = _order!.finalPrice != null
        ? '¥${(_order!.finalPrice! / 100).toStringAsFixed(2)}'
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order!.skuName ?? '商品',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (_order!.skuSpec?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    _order!.skuSpec!
                        .map((s) => s.valueName ?? '')
                        .where((s) => s.isNotEmpty)
                        .join(' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            priceStr,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AhsOrderStatus? status) {
    if (status == null) return const Text('-');
    Color color;
    switch (status) {
      case AhsOrderStatus.pending:
        color = CupertinoColors.activeOrange;
        break;
      case AhsOrderStatus.cancelled:
        color = CupertinoColors.systemGrey;
        break;
      case AhsOrderStatus.completed:
        color = CupertinoColors.activeGreen;
        break;
      case AhsOrderStatus.checking:
        color = CupertinoColors.activeBlue;
        break;
      case AhsOrderStatus.listed:
        color = CupertinoColors.systemPurple;
        break;
      case AhsOrderStatus.sold:
        color = CupertinoColors.activeGreen;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmployeeInfo(int? ident) {
    if (ident == null) return const Text('-', style: TextStyle(fontSize: 14));
    // TODO: 使用 RenderEmployeeInfo 组件渲染员工姓名
    return Text(
      '员工 #$ident',
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildDeptInfo(int? deptId) {
    if (deptId == null) return const Text('-', style: TextStyle(fontSize: 14));
    // TODO: 使用 RenderDeptInfo 组件渲染部门名称
    return Text(
      '部门 #$deptId',
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildUserInfo(int? ident, String type) {
    if (ident == null) return const Text('-', style: TextStyle(fontSize: 14));
    // TODO: 使用 RenderUser 组件渲染用户信息
    return Text(
      type == 'name' ? '用户 #$ident' : '-',
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildTime(int? unix) {
    if (unix == null) return const Text('-', style: TextStyle(fontSize: 14));
    final dt = DateTime.fromMillisecondsSinceEpoch(unix);
    return Text(
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 14),
    );
  }
}

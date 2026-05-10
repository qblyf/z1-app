import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/recycle_order_api.dart';
import '../../models/recycle_order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 商城回收单详情页
/// 路由：/mall-order/recycle-order-info/:orderNumber
class RecycleOrderInfoPage extends ConsumerStatefulWidget {
  final String orderNumber;

  const RecycleOrderInfoPage({super.key, required this.orderNumber});

  @override
  ConsumerState<RecycleOrderInfoPage> createState() => _RecycleOrderInfoPageState();
}

class _RecycleOrderInfoPageState extends ConsumerState<RecycleOrderInfoPage> {
  final RecycleOrderApi _api = RecycleOrderApi();
  RecycleOrder? _order;
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
      final order = await _api.detail(widget.orderNumber);
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
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: const Text('回收单详情', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      child: _buildBody(),
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
      return const EmptyWidget(
        message: '未找到该回收单',
        icon: CupertinoIcons.doc_text,
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 状态卡片
          _buildStatusCard(),

          const SizedBox(height: AppSpacing.lg),

          // 回收单信息
          _buildSection('回收单信息', [
            _buildRow('回收单号', _order!.number),
            _buildRow('回收单状态', _buildStateBadge(_order!.stateEnum)),
            _buildRow('回收人', '员工 #${_order!.operator}'),
            _buildRow('回收部门', '部门 #${_order!.department}'),
            _buildRow('回收时间', _formatTime(_order!.createdAt)),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 顾客信息
          _buildSection('顾客信息', [
            _buildRow('顾客姓名', '用户 #${_order!.customer}'),
            _buildRow('联系方式', '-'),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 商品信息
          _buildSection('商品信息', [
            _buildProductInfo(),
            Container(height: 0.5, color: AppColors.divider),
            _buildRow('序列号', _order!.serial.isNotEmpty ? _order!.serial : '-'),
            if (_order!.specification.isNotEmpty)
              _buildRow('规格', _order!.specification.join(' ')),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 金额信息
          _buildSection('金额信息', [
            _buildRow('实际收款', '¥${_order!.actualAmountYuan}'),
            _buildRow('回收宝金额', '¥${(_order!.evalAmount / 100).toStringAsFixed(2)}'),
            _buildRow('成本金额', '¥${_order!.costAmountYuan}'),
            if (_order!.platformPrice != null)
              _buildRow('渠道售出价', '¥${_order!.platformPriceYuan}'),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 支付信息
          _buildSection('支付信息', [
            _buildRow('支付方式', _order!.paymentType.isNotEmpty ? _order!.paymentType : '-'),
            if (_order!.payInfo != null && _order!.payInfo!.isNotEmpty)
              _buildRow('支付详情', _order!.payInfo!),
          ]),

          // 图片信息
          if (_order!.images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildSection('验机照片', [
              _buildImages(),
            ]),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final stateEnum = _order!.stateEnum;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (stateEnum) {
      case RecycleOrderState.unpaid:
        statusColor = const Color(0xFFFF9F0A);
        statusLabel = '未付款';
        statusIcon = CupertinoIcons.clock;
        break;
      case RecycleOrderState.paid:
        statusColor = const Color(0xFF0A84FF);
        statusLabel = '已付款';
        statusIcon = CupertinoIcons.checkmark_circle_fill;
        break;
      case RecycleOrderState.transfer:
        statusColor = const Color(0xFF5856D6);
        statusLabel = '调拨在途';
        statusIcon = CupertinoIcons.cube_box;
        break;
      case RecycleOrderState.notRechecked:
        statusColor = const Color(0xFFFF9500);
        statusLabel = '未复检';
        statusIcon = CupertinoIcons.exclamationmark_circle;
        break;
      case RecycleOrderState.rechecked:
        statusColor = const Color(0xFF30D158);
        statusLabel = '已复检';
        statusIcon = CupertinoIcons.checkmark_circle;
        break;
      case RecycleOrderState.nonStandardGoods:
        statusColor = const Color(0xFFBF5AF2);
        statusLabel = '转非标';
        statusIcon = CupertinoIcons.cube;
        break;
      case RecycleOrderState.vendor:
        statusColor = const Color(0xFFFF6961);
        statusLabel = '渠道';
        statusIcon = CupertinoIcons.building_2_fill;
        break;
      case RecycleOrderState.vendorSold:
        statusColor = const Color(0xFF30D158);
        statusLabel = '渠道售出';
        statusIcon = CupertinoIcons.checkmark_seal_fill;
        break;
      case RecycleOrderState.undone:
        statusColor = const Color(0xFF8E8E93);
        statusLabel = '已撤销';
        statusIcon = CupertinoIcons.xmark_circle_fill;
        break;
      default:
        statusColor = const Color(0xFF8E8E93);
        statusLabel = stateEnum?.label ?? _order!.state;
        statusIcon = CupertinoIcons.info_circle;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: AppText.subtitle.copyWith(color: statusColor),
                ),
                Text(
                  _getStatusHint(stateEnum),
                  style: AppText.caption.copyWith(
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusHint(RecycleOrderState? state) {
    switch (state) {
      case RecycleOrderState.unpaid:
        return '等待向顾客付款';
      case RecycleOrderState.paid:
        return '已向顾客付款，等待验机';
      case RecycleOrderState.transfer:
        return '商品调拨运输中';
      case RecycleOrderState.notRechecked:
        return '等待复检';
      case RecycleOrderState.rechecked:
        return '复检完成';
      case RecycleOrderState.nonStandardGoods:
        return '已转为非标准商品';
      case RecycleOrderState.vendor:
        return '商品在渠道中';
      case RecycleOrderState.vendorSold:
        return '商品已售出';
      case RecycleOrderState.undone:
        return '回收单已撤销';
      default:
        return '';
    }
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
      ],
    );
  }

  Widget _buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(value?.toString() ?? '-', style: AppText.body),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '商品名称',
              style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order!.ruleTitle.isNotEmpty ? _order!.ruleTitle : '回收商品',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                if (_order!.specification.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _order!.specification.join(' '),
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '¥${_order!.actualAmountYuan}',
            style: AppText.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _order!.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _order!.images[index],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateBadge(RecycleOrderState? state) {
    if (state == null) {
      return Text('-', style: AppText.body);
    }

    Color color;
    switch (state) {
      case RecycleOrderState.unpaid:
        color = const Color(0xFFFF9F0A);
        break;
      case RecycleOrderState.paid:
        color = const Color(0xFF0A84FF);
        break;
      case RecycleOrderState.transfer:
        color = const Color(0xFF5856D6);
        break;
      case RecycleOrderState.notRechecked:
        color = const Color(0xFFFF9500);
        break;
      case RecycleOrderState.rechecked:
        color = const Color(0xFF30D158);
        break;
      case RecycleOrderState.nonStandardGoods:
        color = const Color(0xFFBF5AF2);
        break;
      case RecycleOrderState.vendor:
        color = const Color(0xFFFF6961);
        break;
      case RecycleOrderState.vendorSold:
        color = const Color(0xFF30D158);
        break;
      case RecycleOrderState.undone:
        color = const Color(0xFF8E8E93);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(int unix) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

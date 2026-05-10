import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/repair_order_api.dart';
import '../../models/repair_order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

class RepairOrderDetailPage extends ConsumerStatefulWidget {
  final int repairID;

  const RepairOrderDetailPage({super.key, required this.repairID});

  @override
  ConsumerState<RepairOrderDetailPage> createState() => _RepairOrderDetailPageState();
}

class _RepairOrderDetailPageState extends ConsumerState<RepairOrderDetailPage> {
  RepairOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = RepairOrderApi();
      final detail = await api.detail(widget.repairID);
      if (mounted) {
        setState(() {
          _order = detail;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
        middle: const Text('维修单详情'),
        previousPageTitle: '返回',
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? Center(child: Text('加载失败: $_error', style: const TextStyle(color: CupertinoColors.systemRed)))
                : _order == null
                    ? const Center(child: Text('未找到该维修单'))
                    : _buildContent(_order!),
      ),
    );
  }

  Widget _buildContent(RepairOrder order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_stateColor(order.repairState), _stateColor(order.repairState).withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(order.repairType.label, style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(order.repairState.label, style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(order.repairNumber, style: const TextStyle(color: CupertinoColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(order.warrantyState.label, style: TextStyle(color: CupertinoColors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 基本信息
          _Section(title: '基本信息', children: [
            _InfoRow(label: '故障描述', value: order.description.isNotEmpty ? order.description : '无'),
            if (order.accessoriesDesc != null && order.accessoriesDesc!.isNotEmpty)
              _InfoRow(label: '附件描述', value: order.accessoriesDesc!),
            if (order.valueAddedServices != null && order.valueAddedServices!.isNotEmpty)
              _InfoRow(label: '增值服务', value: order.valueAddedServices!),
            _InfoRow(label: '购机日期', value: order.buyDate.isNotEmpty ? order.buyDate : '未知'),
            if (order.remarks != null && order.remarks!.isNotEmpty)
              _InfoRow(label: '备注', value: order.remarks!),
          ]),

          const SizedBox(height: 16),

          // 时间信息
          _Section(title: '时间信息', children: [
            _InfoRow(label: '创建时间', value: _formatDateTime(order.createdAt)),
            _InfoRow(label: '更新时间', value: _formatDateTime(order.updatedAt)),
          ]),

          const SizedBox(height: 16),

          // 维修信息
          if (order.engineerIdent != null || order.repairCentreID != null)
            _Section(title: '维修信息', children: [
              if (order.engineerIdent != null)
                _InfoRow(label: '工程师', value: 'ID: ${order.engineerIdent}'),
              if (order.repairCentreID != null)
                _InfoRow(label: '维修站', value: 'ID: ${order.repairCentreID}'),
            ]),
        ],
      ),
    );
  }

  Color _stateColor(RepairState state) {
    switch (state) {
      case RepairState.pending:
        return const Color(0xFFFF9500);
      case RepairState.repairing:
        return const Color(0xFF007AFF);
      case RepairState.repairedConfirm:
      case RepairState.repairedNotice:
      case RepairState.repairedNoticed:
      case RepairState.repairedPicked:
        return const Color(0xFF30D158);
      case RepairState.unRepairableConfirm:
      case RepairState.unRepairableNotice:
      case RepairState.unRepairableNoticed:
      case RepairState.unRepairablePicked:
        return const Color(0xFFFF3B30);
      case RepairState.missingParts:
        return const Color(0xFFFF9F0A);
    }
  }

  String _formatDateTime(int ts) {
    if (ts == 0) return '未知';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator.resolveFrom(context), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/goods_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 货品流转追踪页面
/// 对应 PWA /pages/path-d/goods/tracking.tsx
/// 通过 goodsId 查询货品的完整流转历史
class GoodsTrackingPage extends ConsumerStatefulWidget {
  final int goodsId;
  const GoodsTrackingPage({super.key, required this.goodsId});

  @override
  ConsumerState<GoodsTrackingPage> createState() => _GoodsTrackingPageState();
}

class _GoodsTrackingPageState extends ConsumerState<GoodsTrackingPage> {
  final GoodsApi _api = GoodsApi();

  bool _isLoading = true;
  String? _errorMsg;
  GoodsInfo? _goodsInfo;
  List<SerialTraceRecord> _traceList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      // 加载货品详情
      final info = await _api.getGoodsDetail([widget.goodsId]);
      // 加载流转追踪
      final traces = await _api.traceGoods(widget.goodsId);
      if (mounted) {
        setState(() {
          _goodsInfo = info;
          _traceList = traces;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMsg = '加载失败：$e'; });
      }
    }
  }

  String _typeLabel(int type) {
    switch (type) {
      case 1: return '采购入库';
      case 2: return '调拨出库';
      case 3: return '调拨入库';
      case 4: return '零售出库';
      case 5: return '销售出库';
      case 6: return '其他';
      default: return '未知';
    }
  }

  Color _typeColor(int type) {
    switch (type) {
      case 1: return const Color(0xFF30D158);
      case 2: return const Color(0xFFFF9500);
      case 3: return const Color(0xFF64D2FF);
      case 4: return const Color(0xFFFF3B30);
      case 5: return const Color(0xFFBF5AF2);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _formatTime(int? ts) {
    if (ts == null) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('货品流转追踪'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMsg != null
                ? Center(child: Text(_errorMsg!, style: AppText.body))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 货品基本信息
          if (_goodsInfo != null) _buildGoodsInfo(_goodsInfo!),

          const SizedBox(height: 16),

          // 流转历史标题
          const Text('流转历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_traceList.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),
                  const Icon(CupertinoIcons.doc_text, size: 48, color: Color(0xFFDDDDE0)),
                  const SizedBox(height: 16),
                  Text('暂无流转记录', style: AppText.caption),
                ],
              ),
            )
          else
            ..._traceList.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return _TraceItem(
                record: record,
                typeLabel: _typeLabel(record.type),
                typeColor: _typeColor(record.type),
                formatTime: _formatTime,
                isLast: index == _traceList.length - 1,
              );
            }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGoodsInfo(GoodsInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('货品信息', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _InfoRow('商品ID', info.id.toString()),
          if (info.serial != null) _InfoRow('序列号', info.serial!),
          if (info.meid != null) _InfoRow('MEID', info.meid!),
          if (info.sn2 != null) _InfoRow('SN2', info.sn2!),
          _InfoRow('仓库', info.warehouse?.toString() ?? '-'),
          _InfoRow('供应商', info.vendor?.toString() ?? '-'),
          _InfoRow('状态', _stateLabel(info.state)),
        ],
      ),
    );
  }

  String _stateLabel(int? state) {
    switch (state) {
      case 1: return '在库';
      case 2: return '已售';
      case 3: return '退货';
      default: return '未知';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }
}

class _TraceItem extends StatelessWidget {
  final SerialTraceRecord record;
  final String typeLabel;
  final Color typeColor;
  final String Function(int?) formatTime;
  final bool isLast;

  const _TraceItem({
    required this.record,
    required this.typeLabel,
    required this.typeColor,
    required this.formatTime,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE0E0E0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 内容卡片
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(typeLabel, style: TextStyle(fontSize: 12, color: typeColor)),
                      ),
                      const Spacer(),
                      Text(
                        formatTime(record.createdAt),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (record.number != null && record.number!.isNotEmpty)
                    _TraceRow('单号', record.number!),
                  if (record.inWarehouse != null)
                    _TraceRow('入库仓库', record.inWarehouse.toString()),
                  if (record.outWarehouse != null)
                    _TraceRow('出库仓库', record.outWarehouse.toString()),
                  if (record.vendor != null)
                    _TraceRow('供应商', record.vendor.toString()),
                  if (record.userIdent != null)
                    _TraceRow('操作人ID', record.userIdent.toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceRow extends StatelessWidget {
  final String label;
  final String value;
  const _TraceRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/goods_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 序列号搜索页面
/// 对应 PWA /pages/path-d/goods/search.tsx
class SerialSearchPage extends ConsumerStatefulWidget {
  const SerialSearchPage({super.key});

  @override
  ConsumerState<SerialSearchPage> createState() => _SerialSearchPageState();
}

class _SerialSearchPageState extends ConsumerState<SerialSearchPage> {
  final GoodsApi _goodsApi = GoodsApi();
  final _searchController = TextEditingController();

  bool _isSearching = false;
  String? _errorMsg;
  SerialSearchResult? _result;

  // 追踪
  bool _isTracing = false;
  List<SerialTraceRecord> _traceList = [];
  bool _traceVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final serial = _searchController.text.trim();
    if (serial.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMsg = null;
      _result = null;
      _traceVisible = false;
    });

    try {
      final list = await _goodsApi.searchBySerial(serial);
      if (mounted) {
        setState(() {
          _isSearching = false;
          _result = list.isNotEmpty ? list.first : null;
          if (list.isEmpty) _errorMsg = '未找到该串号';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMsg = '搜索失败：$e';
        });
      }
    }
  }

  Future<void> _trace(String serial) async {
    setState(() {
      _isTracing = true;
      _traceList = [];
    });

    try {
      final list = await _goodsApi.traceSerial(serial);
      if (mounted) {
        setState(() {
          _isTracing = false;
          _traceList = list;
          _traceVisible = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isTracing = false);
    }
  }

  String _traceTypeLabel(int type) {
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

  String _stateLabel(int? state) {
    switch (state) {
      case 1: return '在库';
      case 2: return '已售';
      case 3: return '退货';
      default: return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('序列号搜索'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _searchController,
                      placeholder: '输入串号 / MEID / SN2',
                      clearButtonMode: OverlayVisibilityMode.editing,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: _isSearching ? null : _search,
                    child: _isSearching
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('搜索'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.search, size: 48, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text(_errorMsg!, style: AppText.body),
          ],
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.barcode_viewfinder, size: 64, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text('输入串号进行搜索', style: AppText.caption),
          ],
        ),
      );
    }

    final r = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息卡片
          Container(
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
                _InfoRow('商品ID', r.goodsId?.toString() ?? '-'),
                _InfoRow('串号', r.serial),
                if (r.meid != null && r.meid!.isNotEmpty) _InfoRow('MEID', r.meid!),
                if (r.sn2 != null && r.sn2!.isNotEmpty) _InfoRow('SN2', r.sn2!),
                if (r.skuCostCent != null) _InfoRow('成本价', '¥${(r.skuCostCent! / 100).toStringAsFixed(2)}'),
                if (r.purchaseCent != null) _InfoRow('采购价', '¥${(r.purchaseCent! / 100).toStringAsFixed(2)}'),
              ],
            ),
          ),

          // 非标货品
          if (r.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
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
                  const Text('非标准货品', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...r.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ItemID: ${item.itemId}', style: AppText.body),
                        if (item.costCent != null)
                          Text('成本价: ¥${(item.costCent! / 100).toStringAsFixed(2)}',
                              style: AppText.caption),
                        if (item.purchaseCent != null)
                          Text('采购价: ¥${(item.purchaseCent! / 100).toStringAsFixed(2)}',
                              style: AppText.caption),
                        const Divider(),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () => _trace(r.serial),
                  child: _isTracing
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('流转追踪'),
                ),
              ),
            ],
          ),

          // 追踪结果
          if (_traceVisible) ...[
            const SizedBox(height: 16),
            if (_traceList.isEmpty)
              Center(child: Text('暂无流转记录', style: AppText.caption))
            else
              ..._traceList.map((record) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(AppSpacing.md),
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
                            color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _traceTypeLabel(record.type),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          record.number ?? '',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (record.inWarehouse != null)
                      _InfoRow('入库仓库', record.inWarehouse.toString()),
                    if (record.outWarehouse != null)
                      _InfoRow('出库仓库', record.outWarehouse.toString()),
                    if (record.createdAt != null)
                      _InfoRow('时间', _formatTime(record.createdAt!)),
                    if (record.orderState != null)
                      _InfoRow('订单状态', _stateLabel(record.orderState)),
                  ],
                ),
              )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
            width: 80,
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

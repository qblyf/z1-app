import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

final _areaTimeRangeProvider = NotifierProvider<_AreaTimeRangeNotifier, ({int start, int end})>(_AreaTimeRangeNotifier.new);

class _AreaTimeRangeNotifier extends Notifier<({int start, int end})> {
  @override
  ({int start, int end}) build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return (
      start: start.millisecondsSinceEpoch ~/ 1000,
      end: now.millisecondsSinceEpoch ~/ 1000,
    );
  }
}

final _areaOrderByProvider = NotifierProvider<_AreaOrderByNotifier, ({String key, String sort})>(_AreaOrderByNotifier.new);

class _AreaOrderByNotifier extends Notifier<({String key, String sort})> {
  @override
  ({String key, String sort}) build() => (key: 'mainProductCount', sort: 'desc');
}

final _areaRankListProvider = FutureProvider.autoDispose<List<AreaRankItem>>((ref) async {
  final timeRange = ref.watch(_areaTimeRangeProvider);
  final orderBy = ref.watch(_areaOrderByProvider);
  // 使用模拟的部门ID，实际从用户信息获取
  return storekeeperDataApi.getAreaRankTop(
    departmentId: 0,
    startAt: timeRange.start,
    endAt: timeRange.end,
    orderByKey: orderBy.key,
    sort: orderBy.sort,
  );
});

class AreaDataComparePage extends ConsumerStatefulWidget {
  const AreaDataComparePage({super.key});

  @override
  ConsumerState<AreaDataComparePage> createState() => _AreaDataComparePageState();
}

class _AreaDataComparePageState extends ConsumerState<AreaDataComparePage> {
  int _timeType = 1; // 0=日, 1=月, 2=自定义
  int _orderByIndex = 0; // 0=主营销量, 1=销售额, 2=总毛利

  final List<String> _orderByKeys = ['mainProductCount', 'totalAmount', 'totalGross'];
  final List<String> _orderByLabels = ['主营销量', '销售额', '总毛利'];

  void _onTimeTypeChanged(int? value) {
    if (value == null) return;
    setState(() => _timeType = value);
    final now = DateTime.now();
    int startTimestamp;
    switch (value) {
      case 0: // 当日
        startTimestamp = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
        break;
      case 1: // 本月
      default:
        startTimestamp = DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000;
        break;
    }
    ref.read(_areaTimeRangeProvider.notifier).state = (
      start: startTimestamp,
      end: now.millisecondsSinceEpoch ~/ 1000,
    );
  }

  void _onOrderByChanged(int index) {
    setState(() => _orderByIndex = index);
    final key = _orderByKeys[index];
    ref.read(_areaOrderByProvider.notifier).state = (key: key, sort: 'desc');
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_areaRankListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('数据对比'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 时间筛选
            Container(
              padding: const EdgeInsets.all(12),
              color: CupertinoColors.white,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _timeType,
                children: const {
                  0: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('当日')),
                  1: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('本月')),
                  2: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('自定义')),
                },
                onValueChanged: _onTimeTypeChanged,
              ),
            ),
            // 排序字段选择
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  const Text(
                    '排序字段：',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_orderByLabels.length, (index) {
                          final isSelected = _orderByIndex == index;
                          return GestureDetector(
                            onTap: () => _onOrderByChanged(index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                                ),
                              ),
                              child: Text(
                                _orderByLabels[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  const Expanded(flex: 2, child: Text('部门', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel))),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _onOrderByChanged(0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _orderByLabels[0],
                            style: TextStyle(
                              fontSize: 12,
                              color: _orderByIndex == 0 ? CupertinoColors.activeBlue : CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                          if (_orderByIndex == 0)
                            const Icon(CupertinoIcons.arrow_down, size: 10, color: CupertinoColors.activeBlue),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _onOrderByChanged(1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _orderByLabels[1],
                            style: TextStyle(
                              fontSize: 12,
                              color: _orderByIndex == 1 ? CupertinoColors.activeBlue : CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                          if (_orderByIndex == 1)
                            const Icon(CupertinoIcons.arrow_down, size: 10, color: CupertinoColors.activeBlue),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _onOrderByChanged(2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _orderByLabels[2],
                            style: TextStyle(
                              fontSize: 12,
                              color: _orderByIndex == 2 ? CupertinoColors.activeBlue : CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                          if (_orderByIndex == 2)
                            const Icon(CupertinoIcons.arrow_down, size: 10, color: CupertinoColors.activeBlue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: listAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.chart_bar, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无对比数据', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _AreaRankRow(index: index + 1, item: item);
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败: $e', style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaRankRow extends StatelessWidget {
  final int index;
  final AreaRankItem item;

  const _AreaRankRow({required this.index, required this.item});

  String _formatAmount(int amount) {
    if (amount >= 10000 * 100) {
      return '¥${(amount / 10000 / 100).toStringAsFixed(2)}万';
    }
    return '¥${(amount / 100).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: _RankBadge(index: index),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.departmentName ?? '部门${item.department}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.mainProductCount}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(item.totalAmount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(item.totalGross),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int index;

  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 16));
    } else if (index == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 16));
    } else if (index == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 16));
    }
    return Text(
      '$index',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }
}

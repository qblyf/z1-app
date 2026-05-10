import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import 'sku_ranking_page.dart';
import '../../router/app_router.dart';

final _spuTimeRangeProvider = NotifierProvider<_SpuTimeRangeNotifier, ({int start, int end})>(_SpuTimeRangeNotifier.new);

class _SpuTimeRangeNotifier extends Notifier<({int start, int end})> {
  @override
  ({int start, int end}) build() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return (
      start: start.millisecondsSinceEpoch ~/ 1000,
      end: now.millisecondsSinceEpoch ~/ 1000,
    );
  }
}

final _spuRankListProvider = FutureProvider.autoDispose<List<SPURankingItem>>((ref) async {
  final timeRange = ref.watch(_spuTimeRangeProvider);
  // 使用模拟的部门ID，实际从用户信息获取
  return storekeeperDataApi.getSPURanking(
    departmentId: 0,
    minCreatedAt: timeRange.start,
    maxCreatedAt: timeRange.end,
  );
});

class SPURankingPage extends ConsumerStatefulWidget {
  const SPURankingPage({super.key});

  @override
  ConsumerState<SPURankingPage> createState() => _SPURankingPageState();
}

class _SPURankingPageState extends ConsumerState<SPURankingPage> {
  int _timeType = 2; // 0=日, 1=近7日, 2=近30日, 3=自定义

  void _onTimeTypeChanged(int? value) {
    if (value == null) return;
    setState(() => _timeType = value);
    final now = DateTime.now();
    int startTimestamp;
    switch (value) {
      case 0: // 当日
        startTimestamp = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
        break;
      case 1: // 近7日
        startTimestamp = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
        break;
      case 2: // 近30日
      default:
        startTimestamp = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
        break;
    }
    ref.read(_spuTimeRangeProvider.notifier).state = (
      start: startTimestamp,
      end: now.millisecondsSinceEpoch ~/ 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_spuRankListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('SPU排行'),
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
                  0: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('当日', style: TextStyle(fontSize: 13))),
                  1: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('近7日', style: TextStyle(fontSize: 13))),
                  2: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('近30日', style: TextStyle(fontSize: 13))),
                },
                onValueChanged: _onTimeTypeChanged,
              ),
            ),
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  const Expanded(flex: 2, child: Text('SPU', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '销量',
                      style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '销售额',
                      style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '可售天数',
                      style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      textAlign: TextAlign.right,
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
                          Text('暂无排行数据', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _SPURankCard(index: index + 1, item: item);
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

class _SPURankCard extends StatelessWidget {
  final int index;
  final SPURankingItem item;

  const _SPURankCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => SKURankingPage(spuId: item.spuId, spuName: item.spuName),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：排名和SPU名称
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: _RankBadge(index: index),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.spuName ?? 'SPU${item.spuId}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey),
              ],
            ),
            const SizedBox(height: 12),
            // 销量和销售额
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: '销量',
                    value: '${item.salesCount}',
                    subLabel: '占比 ${item.salesCountRatio}',
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: '销售额',
                    value: '¥${(item.salesAmount / 100).toStringAsFixed(0)}',
                    subLabel: '金额占比 ${item.salesAmountRatio}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // 库存信息
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: '总库存',
                    value: '${item.totalStock}',
                    subLabel: '在店库存 ${item.departmentStock}',
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: '库销比',
                    value: '${item.stockSalesCountRatio}%',
                    subLabel: '可售天数 ${item.salesDay}',
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: '样机数量',
                    value: '${item.sampleCount}',
                    subLabel: '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (subLabel.isNotEmpty)
          Text(
            subLabel,
            style: TextStyle(fontSize: 10, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
          ),
      ],
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
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

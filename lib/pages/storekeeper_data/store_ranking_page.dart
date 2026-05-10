import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

final _rankListProvider = FutureProvider.autoDispose<List<StoreRankItem>>((ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  // 使用模拟的部门ID，实际从用户信息获取
  return storekeeperDataApi.getStoreRank(
    departmentId: 0,
    start: start.millisecondsSinceEpoch ~/ 1000,
    end: now.millisecondsSinceEpoch ~/ 1000,
  );
});

class StoreRankingPage extends ConsumerStatefulWidget {
  const StoreRankingPage({super.key});

  @override
  ConsumerState<StoreRankingPage> createState() => _StoreRankingPageState();
}

class _StoreRankingPageState extends ConsumerState<StoreRankingPage> {
  int _timeType = 1; // 0=日, 1=月, 2=自定义

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_rankListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('门店排行'),
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
                onValueChanged: (v) => setState(() => _timeType = v ?? 1),
              ),
            ),
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  const Expanded(flex: 2, child: Text('门店', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '主营销量',
                      style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '总毛利',
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
                      return _StoreRankRow(index: index + 1, item: item);
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

class _StoreRankRow extends StatelessWidget {
  final int index;
  final StoreRankItem item;

  const _StoreRankRow({required this.index, required this.item});

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
          Expanded(flex: 2, child: Text('门店${item.department}', style: const TextStyle(fontSize: 14))),
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
              '¥${(item.totalGross / 100).toStringAsFixed(0)}',
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

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';

/// 排序字段
enum EmployeeRankingOrderBy {
  mainProductCount('mainProductCount', '主营销量'),
  discountAmount('discountAmount', '销售额'),
  grossProfit('grossProfit', '贡献毛利'),
  totalCommissionPrice('totalCommissionPrice', '提成金额');

  final String key;
  final String label;
  const EmployeeRankingOrderBy(this.key, this.label);
}

/// 时间类型
enum EmployeeRankingTimeType {
  day(0, '当日'),
  week(1, '本周'),
  month(2, '本月');

  final int value;
  final String label;
  const EmployeeRankingTimeType(this.value, this.label);
}

final _employeeRankingProvider = FutureProvider.autoDispose.family<List<EmployeeSalesItem>, ({int timeType, String orderByKey, String sort})>((ref, params) async {
  final now = DateTime.now();
  int startTime;
  int endTime = now.millisecondsSinceEpoch ~/ 1000;

  if (params.timeType == 0) {
    // 当日
    startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
  } else if (params.timeType == 1) {
    // 本周
    final weekDay = now.weekday;
    startTime = DateTime(now.year, now.month, now.day - weekDay + 1).millisecondsSinceEpoch ~/ 1000;
  } else {
    // 本月
    startTime = DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000;
  }

  return storekeeperDataApi.getEmployeeSalesRanking(
    departmentId: 0,
    minCreatedAt: startTime,
    maxCreatedAt: endTime,
    orderByKey: params.orderByKey,
    sort: params.sort,
  );
});

class EmployeeRankingPage extends ConsumerStatefulWidget {
  const EmployeeRankingPage({super.key});

  @override
  ConsumerState<EmployeeRankingPage> createState() => _EmployeeRankingPageState();
}

class _EmployeeRankingPageState extends ConsumerState<EmployeeRankingPage> {
  int _timeType = 2; // 默认本月
  EmployeeRankingOrderBy _orderBy = EmployeeRankingOrderBy.mainProductCount;
  bool _isDesc = true;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_employeeRankingProvider((
      timeType: _timeType,
      orderByKey: _orderBy.key,
      sort: _isDesc ? 'desc' : 'asc',
    )));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('员工排行'),
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
                children: {
                  0: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('当日')),
                  1: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('本周')),
                  2: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('本月')),
                },
                onValueChanged: (v) => setState(() => _timeType = v ?? 2),
              ),
            ),
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  const Expanded(flex: 2, child: Text('员工', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel))),
                  _buildSortHeader('主营销量', EmployeeRankingOrderBy.mainProductCount),
                  _buildSortHeader('销售额', EmployeeRankingOrderBy.discountAmount),
                  _buildSortHeader('贡献毛利', EmployeeRankingOrderBy.grossProfit),
                  _buildSortHeader('提成金额', EmployeeRankingOrderBy.totalCommissionPrice),
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
                          Icon(CupertinoIcons.person_2, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
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
                      return _EmployeeRankRow(index: index + 1, item: item);
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

  Widget _buildSortHeader(String title, EmployeeRankingOrderBy orderByKey) {
    final isSelected = _orderBy == orderByKey;
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_orderBy == orderByKey) {
              _isDesc = !_isDesc;
            } else {
              _orderBy = orderByKey;
              _isDesc = true;
            }
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            if (isSelected)
              Icon(
                _isDesc ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
                size: 10,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeRankRow extends StatelessWidget {
  final int index;
  final EmployeeSalesItem item;

  const _EmployeeRankRow({required this.index, required this.item});

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
              '员工${item.userIdent}',
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
              '¥${(item.totalGross / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(item.totalRatioAverageGross / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(item.totalRatioAverageGross / 100).toStringAsFixed(0)}',
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

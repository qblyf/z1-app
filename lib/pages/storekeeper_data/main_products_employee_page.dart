import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 排序字段
enum MainProductsEmplOrderBy {
  buyCount('buyCount', '销量'),
  totalGrossProfit('totalGrossProfit', '毛利'),
  averageGrossProfit('averageGrossProfit', '单毛'),
  totalCommissionPrice('totalCommissionPrice', '提成');

  final String key;
  final String label;
  const MainProductsEmplOrderBy(this.key, this.label);
}

/// 时间类型
enum MainProductsEmplTimeType {
  day(0, '日'),
  month(1, '月'),
  last30d(2, '近30天'),
  custom(3, '自定义');

  final int value;
  final String label;
  const MainProductsEmplTimeType(this.value, this.label);
}

/// 时间范围
class MainProductsEmplTimeRange {
  final DateTime start;
  final DateTime end;
  MainProductsEmplTimeRange({required this.start, required this.end});
}

/// 扩展的员工销售详情数据
class ExtendedMainProductEmplItem {
  final MainProductEmplItem item;
  final double averageGrossProfit;

  ExtendedMainProductEmplItem({required this.item, required this.averageGrossProfit});
}

/// 总计行数据
class TotalRowData {
  final int buyCount;
  final int totalGrossProfit;
  final double averageGrossProfit;
  final int totalCommissionPrice;

  TotalRowData({
    required this.buyCount,
    required this.totalGrossProfit,
    required this.averageGrossProfit,
    required this.totalCommissionPrice,
  });
}

/// 均值行数据
class AverageRowData {
  final double buyCount;
  final double totalGrossProfit;
  final double averageGrossProfit;
  final double totalCommissionPrice;

  AverageRowData({
    required this.buyCount,
    required this.totalGrossProfit,
    required this.averageGrossProfit,
    required this.totalCommissionPrice,
  });
}

final _mainProductsEmplProvider = FutureProvider.autoDispose.family<List<ExtendedMainProductEmplItem>, ({int productId, MainProductsEmplTimeRange timeRange})>((ref, params) async {
  final list = await storekeeperDataApi.getMainProductsEmplStatistic(
    departmentId: 0,
    productId: params.productId,
    minCreatedAt: params.timeRange.start.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: params.timeRange.end.millisecondsSinceEpoch ~/ 1000,
  );
  return list.map((item) => ExtendedMainProductEmplItem(
    item: item,
    averageGrossProfit: item.buyCount > 0 ? item.totalGrossProfit / item.buyCount : 0.0,
  )).toList();
});

class MainProductsEmployeePage extends ConsumerStatefulWidget {
  final int productId;
  final String productName;

  const MainProductsEmployeePage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<MainProductsEmployeePage> createState() => _MainProductsEmployeePageState();
}

class _MainProductsEmployeePageState extends ConsumerState<MainProductsEmployeePage> {
  MainProductsEmplTimeType _timeType = MainProductsEmplTimeType.last30d;
  MainProductsEmplOrderBy _orderBy = MainProductsEmplOrderBy.buyCount;
  bool _isDesc = true;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _showDatePicker = false;

  @override
  void initState() {
    super.initState();
    _updateTimeRange();
  }

  void _updateTimeRange() {
    final now = DateTime.now();
    if (_timeType == MainProductsEmplTimeType.day) {
      _startTime = DateTime(now.year, now.month, now.day);
      _endTime = now;
    } else if (_timeType == MainProductsEmplTimeType.month) {
      _startTime = DateTime(now.year, now.month, 1);
      _endTime = now;
    } else if (_timeType == MainProductsEmplTimeType.last30d) {
      _startTime = DateTime(now.year, now.month, now.day - 30);
      _endTime = now;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  TotalRowData _calculateTotalRow(List<ExtendedMainProductEmplItem> list) {
    int totalBuyCount = 0;
    int totalGrossProfit = 0;
    int totalCommission = 0;
    double totalAvgGross = 0;

    for (final ext in list) {
      totalBuyCount += ext.item.buyCount;
      totalGrossProfit += ext.item.totalGrossProfit;
      totalCommission += ext.item.totalCommissionPrice;
      totalAvgGross += ext.averageGrossProfit;
    }

    return TotalRowData(
      buyCount: totalBuyCount,
      totalGrossProfit: totalGrossProfit,
      averageGrossProfit: totalBuyCount > 0 ? totalGrossProfit / totalBuyCount : 0.0,
      totalCommissionPrice: totalCommission,
    );
  }

  AverageRowData _calculateAverageRow(List<ExtendedMainProductEmplItem> list) {
    final employeesWithSales = list.where((ext) => ext.item.buyCount > 0).length;
    if (employeesWithSales == 0) {
      return AverageRowData(
        buyCount: 0,
        totalGrossProfit: 0,
        averageGrossProfit: 0,
        totalCommissionPrice: 0,
      );
    }

    final total = _calculateTotalRow(list);
    return AverageRowData(
      buyCount: total.buyCount / employeesWithSales,
      totalGrossProfit: total.totalGrossProfit / employeesWithSales,
      averageGrossProfit: total.averageGrossProfit,
      totalCommissionPrice: total.totalCommissionPrice / employeesWithSales,
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeRange = MainProductsEmplTimeRange(start: _startTime, end: _endTime);
    final listAsync = ref.watch(_mainProductsEmplProvider((productId: widget.productId, timeRange: timeRange)));

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
        middle: Text(widget.productName),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 时间筛选
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: CupertinoColors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTimeTypeTab(MainProductsEmplTimeType.day, '日'),
                      _buildTimeTypeTab(MainProductsEmplTimeType.month, '月'),
                      _buildTimeTypeTab(MainProductsEmplTimeType.last30d, '近30天'),
                      Expanded(child: _buildCustomDatePicker()),
                    ],
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
                  const Expanded(flex: 2, child: Text('员工', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel))),
                  _buildSortHeader('销量', MainProductsEmplOrderBy.buyCount),
                  _buildSortHeader('毛利', MainProductsEmplOrderBy.totalGrossProfit),
                  _buildSortHeader('单毛', MainProductsEmplOrderBy.averageGrossProfit),
                  _buildSortHeader('提成', MainProductsEmplOrderBy.totalCommissionPrice),
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
                          Text('暂无销售数据', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }

                  // 排序
                  final sortedList = List<ExtendedMainProductEmplItem>.from(list);
                  sortedList.sort((a, b) {
                    int aValue;
                    int bValue;
                    double aDouble;
                    double bDouble;

                    switch (_orderBy) {
                      case MainProductsEmplOrderBy.buyCount:
                        aValue = a.item.buyCount;
                        bValue = b.item.buyCount;
                        return _isDesc ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
                      case MainProductsEmplOrderBy.totalGrossProfit:
                        aValue = a.item.totalGrossProfit;
                        bValue = b.item.totalGrossProfit;
                        return _isDesc ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
                      case MainProductsEmplOrderBy.averageGrossProfit:
                        aDouble = a.averageGrossProfit;
                        bDouble = b.averageGrossProfit;
                        return _isDesc ? bDouble.compareTo(aDouble) : aDouble.compareTo(bDouble);
                      case MainProductsEmplOrderBy.totalCommissionPrice:
                        aValue = a.item.totalCommissionPrice;
                        bValue = b.item.totalCommissionPrice;
                        return _isDesc ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
                    }
                  });

                  final totalRow = _calculateTotalRow(sortedList);
                  final avgRow = _calculateAverageRow(sortedList);

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: sortedList.length + 3, // 2 header rows + data rows
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSummaryRow('总计', totalRow);
                      } else if (index == 1) {
                        return _buildAverageRow(avgRow);
                      } else {
                        final item = sortedList[index - 2];
                        return _MainProductEmplRow(item: item);
                      }
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败: $e', style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context))),
                ),
              ),
            ),
            // 自定义日期选择器
            if (_showDatePicker) _buildDatePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTypeTab(MainProductsEmplTimeType type, String label) {
    final isSelected = _timeType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeType = type;
          _updateTimeRange();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDatePicker() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDatePicker = !_showDatePicker;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${_formatDate(_startTime)}-${_formatDate(_endTime)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.calendar,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortHeader(String title, MainProductsEmplOrderBy orderByKey) {
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

  Widget _buildDatePicker() {
    return Container(
      height: 200,
      color: CupertinoColors.white,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: _startTime,
        onDateTimeChanged: (DateTime newDate) {
          setState(() {
            _startTime = newDate;
            _endTime = DateTime.now();
            _timeType = MainProductsEmplTimeType.custom;
          });
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, TotalRowData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: CupertinoColors.systemGrey5,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${data.buyCount}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(data.totalGrossProfit / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(data.averageGrossProfit / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(data.totalCommissionPrice / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageRow(AverageRowData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey5,
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  '均值',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('说明'),
                        content: const Text('只统计有销量的员工数据，其中[单毛均值 = 员工单毛合计值 / 人数]'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('确定'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(
                      child: Text('?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.buyCount.toStringAsFixed(1),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(data.totalGrossProfit / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(data.averageGrossProfit / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(data.totalCommissionPrice / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainProductEmplRow extends StatelessWidget {
  final ExtendedMainProductEmplItem item;

  const _MainProductEmplRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '员工${item.item.seller}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.item.buyCount}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(item.item.totalGrossProfit / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(item.averageGrossProfit / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '¥${(item.item.totalCommissionPrice / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import 'main_products_employee_page.dart';
import '../../router/app_router.dart';

/// 排序字段
enum MainProductsOrderBy {
  buyCount('buyCount', '销量'),
  averageGrossProfit('averageGrossProfit', '单毛'),
  totalStock('totalStock', '库存');

  final String key;
  final String label;
  const MainProductsOrderBy(this.key, this.label);
}

/// 时间类型
enum MainProductsTimeType {
  day(0, '日'),
  month(1, '月'),
  last30d(2, '近30天'),
  custom(3, '自定义');

  final int value;
  final String label;
  const MainProductsTimeType(this.value, this.label);
}

/// 时间范围
class MainProductsTimeRange {
  final DateTime start;
  final DateTime end;
  MainProductsTimeRange({required this.start, required this.end});
}

final _mainProductsProvider = FutureProvider.autoDispose.family<List<MainProductItem>, MainProductsTimeRange>((ref, timeRange) async {
  return storekeeperDataApi.getMainProducts(
    departmentId: 0,
    minCreatedAt: timeRange.start.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: timeRange.end.millisecondsSinceEpoch ~/ 1000,
  );
});

class MainProductsPage extends ConsumerStatefulWidget {
  const MainProductsPage({super.key});

  @override
  ConsumerState<MainProductsPage> createState() => _MainProductsPageState();
}

class _MainProductsPageState extends ConsumerState<MainProductsPage> {
  MainProductsTimeType _timeType = MainProductsTimeType.last30d;
  MainProductsOrderBy _orderBy = MainProductsOrderBy.buyCount;
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
    if (_timeType == MainProductsTimeType.day) {
      _startTime = DateTime(now.year, now.month, now.day);
      _endTime = now;
    } else if (_timeType == MainProductsTimeType.month) {
      _startTime = DateTime(now.year, now.month, 1);
      _endTime = now;
    } else if (_timeType == MainProductsTimeType.last30d) {
      _startTime = DateTime(now.year, now.month, now.day - 30);
      _endTime = now;
    }
    // custom 模式保持 _startTime 和 _endTime 不变
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeRange = MainProductsTimeRange(start: _startTime, end: _endTime);
    final listAsync = ref.watch(_mainProductsProvider(timeRange));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('重点产品'),
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
                      _buildTimeTypeTab(MainProductsTimeType.day, '日'),
                      _buildTimeTypeTab(MainProductsTimeType.month, '月'),
                      _buildTimeTypeTab(MainProductsTimeType.last30d, '近30天'),
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
                  const Expanded(flex: 3, child: Text('机型', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel))),
                  _buildSortHeader('销量', MainProductsOrderBy.buyCount),
                  _buildSortHeader('单毛', MainProductsOrderBy.averageGrossProfit),
                  _buildSortHeader('库存', MainProductsOrderBy.totalStock),
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
                          Icon(CupertinoIcons.cube_box, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无产品数据', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  // 排序
                  final sortedList = List<MainProductItem>.from(list);
                  sortedList.sort((a, b) {
                    int aValue;
                    int bValue;
                    if (_orderBy == MainProductsOrderBy.buyCount) {
                      aValue = a.totalCount;
                      bValue = b.totalCount;
                    } else if (_orderBy == MainProductsOrderBy.averageGrossProfit) {
                      aValue = a.totalGross;
                      bValue = b.totalGross;
                    } else {
                      aValue = a.totalCount;
                      bValue = b.totalCount;
                    }
                    return _isDesc ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
                  });
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final item = sortedList[index];
                      return _MainProductRow(
                        item: item,
                        onTap: () => _navigateToEmployeeDetail(item),
                      );
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

  Widget _buildTimeTypeTab(MainProductsTimeType type, String label) {
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

  Widget _buildSortHeader(String title, MainProductsOrderBy orderByKey) {
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
            _timeType = MainProductsTimeType.custom;
          });
        },
      ),
    );
  }

  void _navigateToEmployeeDetail(MainProductItem item) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => MainProductsEmployeePage(
          productId: item.productId,
          productName: '产品${item.productId}',
        ),
      ),
    );
  }
}

class _MainProductRow extends StatelessWidget {
  final MainProductItem item;
  final VoidCallback onTap;

  const _MainProductRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final averageGross = item.totalCount > 0 ? item.totalGross / item.totalCount : 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '产品${item.productId}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${item.totalCount}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '¥${(averageGross / 100).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
              ),
            ),
            const Expanded(
              flex: 2,
              child: Text(
                '-',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

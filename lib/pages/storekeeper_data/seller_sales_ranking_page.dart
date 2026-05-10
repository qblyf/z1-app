import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/sales_statistic_api.dart';
import '../../api/employee_api.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 员工销售排行 API Provider
final sellerSalesRankingProvider = FutureProvider.family<List<SellerSalesRankingItem>, _RankingParams>(
  (ref, params) async {
    final api = SalesStatisticApi();
    return api.sellerSalesRanking(
      minCreatedAt: params.minCreatedAt,
      maxCreatedAt: params.maxCreatedAt,
      departmentId: params.departmentId,
    );
  },
);

/// 部门员工列表 Provider
final deptEmployeesProvider = FutureProvider.family<List<int>, int>(
  (ref, departmentId) async {
    final api = EmployeeApi();
    final employees = await api.getByUserIdents([]);
    // 按部门筛选
    final filtered = employees.where((e) =>
      e.departmentIds?.contains(departmentId) == true
    ).toList();
    return filtered.map((e) => e.userIdent).toList();
  },
);

class _RankingParams {
  final int minCreatedAt;
  final int maxCreatedAt;
  final int? departmentId;

  _RankingParams({
    required this.minCreatedAt,
    required this.maxCreatedAt,
    this.departmentId,
  });

  @override
  bool operator ==(Object other) =>
    other is _RankingParams &&
    other.minCreatedAt == minCreatedAt &&
    other.maxCreatedAt == maxCreatedAt &&
    other.departmentId == departmentId;

  @override
  int get hashCode => Object.hash(minCreatedAt, maxCreatedAt, departmentId);
}

/// 员工销售排行页面
class SellerSalesRankingPage extends ConsumerStatefulWidget {
  final int? departmentId;

  const SellerSalesRankingPage({
    super.key,
    this.departmentId,
  });

  @override
  ConsumerState<SellerSalesRankingPage> createState() => _SellerSalesRankingPageState();
}

class _SellerSalesRankingPageState extends ConsumerState<SellerSalesRankingPage> {
  String _timeType = 'day'; // day | week | month

  int get _beginTime {
    final now = DateTime.now();
    switch (_timeType) {
      case 'month':
        return DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000;
      case 'week':
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 1).millisecondsSinceEpoch ~/ 1000;
      default:
        return DateTime(now.year, now.month, now.day, 0, 0, 0).millisecondsSinceEpoch ~/ 1000;
    }
  }

  int get _endTime {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  @override
  Widget build(BuildContext context) {
    final params = _RankingParams(
      minCreatedAt: _beginTime,
      maxCreatedAt: _endTime,
      departmentId: widget.departmentId,
    );
    final rankingAsync = ref.watch(sellerSalesRankingProvider(params));

    return CupertinoPageScaffold(
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
        middle: const Text('员工排行'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: () => ref.invalidate(sellerSalesRankingProvider(params)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 时间筛选
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  _TimeChip(
                    label: '当日',
                    isActive: _timeType == 'day',
                    onTap: () => setState(() => _timeType = 'day'),
                  ),
                  const SizedBox(width: 8),
                  _TimeChip(
                    label: '本周',
                    isActive: _timeType == 'week',
                    onTap: () => setState(() => _timeType = 'week'),
                  ),
                  const SizedBox(width: 8),
                  _TimeChip(
                    label: '本月',
                    isActive: _timeType == 'month',
                    onTap: () => setState(() => _timeType = 'month'),
                  ),
                  const Spacer(),
                  Text(
                    _formatUpdateTime(),
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              child: Row(
                children: [
                  _headerCell('#', flex: 1),
                  _headerCell('员工', flex: 2),
                  _headerCell('主营销量', flex: 2, align: TextAlign.right),
                  _headerCell('销售额', flex: 2, align: TextAlign.right),
                  _headerCell('贡献毛利', flex: 2, align: TextAlign.right),
                  _headerCell('提成', flex: 2, align: TextAlign.right),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: rankingAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyWidget(
                      message: '暂无排行数据',
                      icon: CupertinoIcons.chart_bar,
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _RankingRow(
                        rank: index + 1,
                        item: item,
                        onTap: () {
                          if (widget.departmentId != null) {
                            context.push(
                              '/storekeeper-data/empl-sales-info?seller=${item.sellerIdent}&departmentID=${widget.departmentId}',
                            );
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.destructiveRed)),
                      CupertinoButton(
                        onPressed: () => ref.invalidate(sellerSalesRankingProvider(params)),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  String _formatUpdateTime() {
    final now = DateTime.now();
    return '更新至 ${now.month}-${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: CupertinoColors.activeBlue, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive
                ? CupertinoColors.activeBlue
                : CupertinoColors.label.resolveFrom(context),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final SellerSalesRankingItem item;
  final VoidCallback onTap;

  const _RankingRow({
    required this.rank,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) {
      rankColor = CupertinoColors.systemYellow;
    } else if (rank == 2) {
      rankColor = CupertinoColors.systemGrey;
    } else if (rank == 3) {
      rankColor = CupertinoColors.systemOrange;
    } else {
      rankColor = CupertinoColors.systemGrey3;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 排名
            SizedBox(
              width: 24,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 员工
            Expanded(
              flex: 2,
              child: Text(
                '员工 #${item.sellerIdent}',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 主营销量
            Expanded(
              flex: 2,
              child: Text(
                '${item.mainProductQuantity}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            // 销售额
            Expanded(
              flex: 2,
              child: Text(
                _formatAmount(item.discountAmount),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            // 贡献毛利
            Expanded(
              flex: 2,
              child: Text(
                _formatAmount(item.grossProfit),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            // 提成
            Expanded(
              flex: 2,
              child: Text(
                _formatAmount(item.totalCommissionPrice),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.activeBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return '¥${(amount / 100).toStringAsFixed(0)}';
  }
}

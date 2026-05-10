import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';

/// 排序字段
enum CapitalTurnoverOrderBy {
  recentSalesIncome('近30日销售收入'),
  currentStockCost('当前库存成本'),
  turnoverRate('资金周转率');

  final String label;
  const CapitalTurnoverOrderBy(this.label);
}

/// 排序方向
enum SortDirection {
  desc,
  asc,
}

/// 资金周转数据 Provider
final _capitalTurnoverProvider = FutureProvider.autoDispose
    .family<List<CapitalTurnoverItem>, ({int departmentId, String orderByKey, String sort})>(
  (ref, params) async {
    return storekeeperDataApi.getCapitalTurnover(
      departmentId: params.departmentId,
      orderByKey: params.orderByKey,
      sort: params.sort,
    );
  },
);

class CapitalTurnoverPage extends ConsumerStatefulWidget {
  const CapitalTurnoverPage({super.key});

  @override
  ConsumerState<CapitalTurnoverPage> createState() => _CapitalTurnoverPageState();
}

class _CapitalTurnoverPageState extends ConsumerState<CapitalTurnoverPage> {
  // 模拟的部门ID，实际应从用户信息获取
  static const int _departmentId = 0;

  CapitalTurnoverOrderBy _orderBy = CapitalTurnoverOrderBy.turnoverRate;
  SortDirection _sortDirection = SortDirection.desc;

  @override
  Widget build(BuildContext context) {
    final orderByKey = _getOrderByKey(_orderBy);
    final sortStr = _sortDirection == SortDirection.desc ? 'desc' : 'asc';

    final turnoverAsync = ref.watch(
      _capitalTurnoverProvider((
        departmentId: _departmentId,
        orderByKey: orderByKey,
        sort: sortStr,
      )),
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('资金周转'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text(
                      '门店',
                      style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _SortableHeader(
                      label: '30日销售收入',
                      orderBy: CapitalTurnoverOrderBy.recentSalesIncome,
                      currentOrderBy: _orderBy,
                      sortDirection: _sortDirection,
                      onTap: () => _handleSort(CapitalTurnoverOrderBy.recentSalesIncome),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _SortableHeader(
                      label: '实时库存',
                      orderBy: CapitalTurnoverOrderBy.currentStockCost,
                      currentOrderBy: _orderBy,
                      sortDirection: _sortDirection,
                      onTap: () => _handleSort(CapitalTurnoverOrderBy.currentStockCost),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _SortableHeader(
                      label: '30日周转率',
                      orderBy: CapitalTurnoverOrderBy.turnoverRate,
                      currentOrderBy: _orderBy,
                      sortDirection: _sortDirection,
                      onTap: () => _handleSort(CapitalTurnoverOrderBy.turnoverRate),
                    ),
                  ),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: turnoverAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _CapitalTurnoverRow(
                        item: item,
                        isHighlight: _isTopPerformer(item, list),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 48,
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '加载失败',
                          style: AppText.subtitle.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          style: AppText.caption.copyWith(
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton(
                          onPressed: () => ref.invalidate(_capitalTurnoverProvider((
                            departmentId: _departmentId,
                            orderByKey: orderByKey,
                            sort: sortStr,
                          ))),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 单位说明
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '单位：万元',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                  Text(
                    '数据更新时间: ${_formatNow()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSort(CapitalTurnoverOrderBy orderBy) {
    setState(() {
      if (_orderBy == orderBy) {
        // 如果点击的是当前排序列，切换排序方向
        _sortDirection = _sortDirection == SortDirection.desc
            ? SortDirection.asc
            : SortDirection.desc;
      } else {
        // 如果点击的是新排序列，默认降序
        _orderBy = orderBy;
        _sortDirection = SortDirection.desc;
      }
    });
  }

  String _getOrderByKey(CapitalTurnoverOrderBy orderBy) {
    switch (orderBy) {
      case CapitalTurnoverOrderBy.recentSalesIncome:
        return 'recentDiscountAmount';
      case CapitalTurnoverOrderBy.currentStockCost:
        return 'currentCost';
      case CapitalTurnoverOrderBy.turnoverRate:
        return 'recentCapitalTurnover';
    }
  }

  bool _isTopPerformer(CapitalTurnoverItem item, List<CapitalTurnoverItem> list) {
    if (list.isEmpty) return false;
    // 高亮周转率最高的门店
    final topItem = list.reduce((a, b) =>
        a.turnoverRate > b.turnoverRate ? a : b);
    return item.department == topItem.department && item.turnoverRate == topItem.turnoverRate;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 48,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无资金周转数据',
            style: AppText.body.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

/// 可排序列头
class _SortableHeader extends StatelessWidget {
  final String label;
  final CapitalTurnoverOrderBy orderBy;
  final CapitalTurnoverOrderBy currentOrderBy;
  final SortDirection sortDirection;
  final VoidCallback onTap;

  const _SortableHeader({
    required this.label,
    required this.orderBy,
    required this.currentOrderBy,
    required this.sortDirection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = orderBy == currentOrderBy;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? AppColors.primary
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 2),
            Icon(
              sortDirection == SortDirection.desc
                  ? CupertinoIcons.arrow_down
                  : CupertinoIcons.arrow_up,
              size: 10,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// 资金周转数据行
class _CapitalTurnoverRow extends StatelessWidget {
  final CapitalTurnoverItem item;
  final bool isHighlight;

  const _CapitalTurnoverRow({
    required this.item,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    // 单位转换：分为->万元
    final salesIncome = (item.recentSalesIncome / 10000 / 100).toStringAsFixed(2);
    final stockCost = (item.currentStockCost / 10000 / 100).toStringAsFixed(2);
    final turnoverRate = item.turnoverRate.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.success.withValues(alpha: 0.08)
            : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isHighlight) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '优',
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    '门店${item.department}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$salesIncome万',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$stockCost万',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              turnoverRate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isHighlight ? AppColors.success : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

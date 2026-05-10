import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/financial_expense_api.dart';
import '../../models/financial_expense.dart';
import '../../theme/app_theme.dart';

final _expenseFilterProvider = StateProvider<_ExpenseFilter>((ref) {
  return _ExpenseFilter();
});

class _ExpenseFilter {
  final int? status;
  final DateTime startDate;
  final DateTime endDate;

  _ExpenseFilter({
    this.status,
    DateTime? startDate,
    DateTime? endDate,
  })  : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  _ExpenseFilter copyWith({int? status, DateTime? startDate, DateTime? endDate}) {
    return _ExpenseFilter(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

final _expenseListProvider = FutureProvider.autoDispose<List<FinancialExpenseItem>>((ref) async {
  final filter = ref.watch(_expenseFilterProvider);
  return financialExpenseApi.list(
    status: filter.status,
    minCreatedAt: filter.startDate.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: filter.endDate.millisecondsSinceEpoch ~/ 1000 + 86399,
  );
});

final _expenseSummaryProvider = FutureProvider.autoDispose<FinancialExpenseSummary>((ref) async {
  final filter = ref.watch(_expenseFilterProvider);
  return financialExpenseApi.count(
    status: filter.status,
    minCreatedAt: filter.startDate.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: filter.endDate.millisecondsSinceEpoch ~/ 1000 + 86399,
  );
});

class FinancialExpenseListPage extends ConsumerStatefulWidget {
  const FinancialExpenseListPage({super.key});

  @override
  ConsumerState<FinancialExpenseListPage> createState() => _FinancialExpenseListPageState();
}

class _FinancialExpenseListPageState extends ConsumerState<FinancialExpenseListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final filter = ref.read(_expenseFilterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _ExpenseFilterSheet(initialFilter: filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_expenseSummaryProvider);
    final listAsync = ref.watch(_expenseListProvider);
    final filter = ref.watch(_expenseFilterProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('财务支出'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showFilterSheet,
              child: const Icon(CupertinoIcons.slider_horizontal_3),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/financial-expense/create'),
              child: const Icon(CupertinoIcons.plus),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 汇总卡片
            summaryAsync.when(
              data: (summary) => Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF30D158), Color(0xFF5E5CE6)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            summary.unAuditAmountDisplay,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '待审核',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${summary.unAuditOrderNum} 单',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: CupertinoColors.white.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            summary.auditAmountDisplay,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '已审核',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${summary.auditOrderNum} 单',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 100, child: Center(child: CupertinoActivityIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 统计栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  Text(
                    _statusLabel(filter.status),
                    style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('筛选', style: AppText.caption.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 2),
                          const Icon(CupertinoIcons.chevron_down, size: 10, color: AppColors.primary),
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
                          Icon(CupertinoIcons.money_dollar_circle, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无支出单', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async => ref.invalidate(_expenseListProvider),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ExpenseCard(item: list[index]),
                          childCount: list.length,
                        ),
                      ),
                    ],
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

  String _statusLabel(int? status) {
    if (status == null) return '全部支出单';
    return FinancialExpenseStatus.fromValue(status).label;
  }
}

class _ExpenseCard extends StatelessWidget {
  final FinancialExpenseItem item;

  const _ExpenseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.status.colorValue);

    return GestureDetector(
      onTap: () => context.push('/financial-expense/detail/${item.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Text(
                    item.title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.label,
                    style: AppText.caption.copyWith(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  item.amountDisplay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                if (item.financialExpensesTypeName != null)
                  Text(
                    item.financialExpensesTypeName!,
                    style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                  ),
              ],
            ),
            if (item.createdAt > 0) ...[
              const SizedBox(height: 8),
              Text(
                _formatTime(item.createdAt),
                style: AppText.caption.copyWith(color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _ExpenseFilterSheet extends ConsumerStatefulWidget {
  final _ExpenseFilter initialFilter;

  const _ExpenseFilterSheet({required this.initialFilter});

  @override
  ConsumerState<_ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<_ExpenseFilterSheet> {
  int? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
  }

  void _apply() {
    ref.read(_expenseFilterProvider.notifier).state = widget.initialFilter.copyWith(status: _status);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('重置'),
                    onPressed: () => setState(() => _status = null),
                  ),
                  const Text('筛选', style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _apply,
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('支出状态', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(null, '全部'),
                      ...FinancialExpenseStatus.values.map(
                        (s) => _buildChip(s.value, s.label),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(int? value, String label) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

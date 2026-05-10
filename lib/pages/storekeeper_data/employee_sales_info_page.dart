import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/employee_api.dart';
import '../../api/sales_statistic_api.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 员工销售详情页面
/// 对应 PWA: /storekeeper-data/empl-sales-info
class EmployeeSalesInfoPage extends ConsumerStatefulWidget {
  /// 部门ID
  final int departmentId;
  /// 员工标识（可选，不传则显示当前用户）
  final int? sellerIdent;

  const EmployeeSalesInfoPage({
    super.key,
    required this.departmentId,
    this.sellerIdent,
  });

  @override
  ConsumerState<EmployeeSalesInfoPage> createState() => _EmployeeSalesInfoPageState();
}

class _EmployeeSalesInfoPageState extends ConsumerState<EmployeeSalesInfoPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _showMonthPicker = false;
  int? _currentUserIdent;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    // 获取当前登录用户ID，实际应从 AuthProvider 获取
    // 暂时使用 sellerIdent 参数
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSeller = widget.sellerIdent ?? _currentUserIdent;
    final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final endOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);
    final monthKey = _SellerSalesKey(widget.departmentId, effectiveSeller ?? 0, startOfMonth.millisecondsSinceEpoch ~/ 1000, endOfMonth.millisecondsSinceEpoch ~/ 1000);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('员工销售详情'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 员工信息卡片
            _EmployeeInfoCard(departmentId: widget.departmentId, sellerIdent: effectiveSeller),
            // 月份选择
            _MonthSelector(
              year: _selectedYear,
              month: _selectedMonth,
              onTap: () => setState(() => _showMonthPicker = !_showMonthPicker),
            ),
            // 月份选择器
            if (_showMonthPicker)
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: DateTime(_selectedYear, _selectedMonth),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (dt) => setState(() {
                    _selectedYear = dt.year;
                    _selectedMonth = dt.month;
                    _showMonthPicker = false;
                  }),
                ),
              ),
            // 销售数据
            Expanded(
              child: _SalesDataSection(key: ValueKey(monthKey), departmentId: widget.departmentId, sellerIdent: effectiveSeller, year: _selectedYear, month: _selectedMonth),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 员工信息卡片 ─────────────────────────────────────────────
class _EmployeeInfoCard extends ConsumerWidget {
  final int departmentId;
  final int? sellerIdent;

  const _EmployeeInfoCard({required this.departmentId, this.sellerIdent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Employee>>(
      future: sellerIdent != null
          ? EmployeeApi().getByUserIdents([sellerIdent!])
          : Future.value([]),
      builder: (context, snapshot) {
        final emp = snapshot.data?.isNotEmpty == true ? snapshot.data!.first : null;
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [CupertinoColors.activeBlue, CupertinoColors.activeBlue.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    (emp?.name?.isNotEmpty == true) ? emp!.name!.substring(0, 1) : '员',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp?.name ?? (sellerIdent != null ? '员工 $sellerIdent' : '员工详情'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emp?.number != null ? '工号: ${emp!.number}' : '店: 部门 $departmentId',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 月份选择 ─────────────────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onTap;

  const _MonthSelector({
    required this.year,
    required this.month,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: CupertinoColors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('选择月份', style: TextStyle(fontSize: 15)),
            Row(
              children: [
                Text(
                  '$year-$month',
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 销售数据区 ───────────────────────────────────────────────
class _SalesDataSection extends ConsumerWidget {
  final int departmentId;
  final int? sellerIdent;
  final int year;
  final int month;

  const _SalesDataSection({
    super.key,
    required this.departmentId,
    this.sellerIdent,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final salesAsync = ref.watch(_sellerSalesProvider(
      _SellerSalesKey(departmentId, sellerIdent ?? 0, startOfMonth.millisecondsSinceEpoch ~/ 1000, endOfMonth.millisecondsSinceEpoch ~/ 1000),
    ));

    return salesAsync.when(
      data: (items) {
        // 找到该员工的数据
        final item = sellerIdent != null
            ? items.where((e) => e.sellerIdent == sellerIdent).firstOrNull
            : items.isNotEmpty ? items.first : null;

        if (item == null) {
          return const _EmptyState(message: '暂无销售数据');
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // 关键指标卡片
            _StatCard(
              items: [
                _StatItem(label: '主推数量', value: '${item.mainProductQuantity}', color: CupertinoColors.activeOrange),
                _StatItem(label: '销售金额', value: _formatFen(item.discountAmount), color: CupertinoColors.activeGreen),
                _StatItem(label: '毛利', value: _formatFen(item.grossProfit), color: CupertinoColors.activeBlue),
              ],
            ),
            const SizedBox(height: 12),
            // 详细数据卡片
            _DetailCard(
              title: '销售明细',
              children: [
                _DetailRow(label: '主推产品数量', value: '${item.mainProductQuantity}'),
                _DetailRow(label: '销售金额(元)', value: _formatFen(item.discountAmount)),
                _DetailRow(label: '毛利(元)', value: _formatFen(item.grossProfit)),
                _DetailRow(label: '提成金额(元)', value: _formatFen(item.totalCommissionPrice), isLast: true),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.destructiveRed)),
        ),
      ),
    );
  }

  String _formatFen(int fen) {
    if (fen >= 10000) {
      return '${(fen / 100).toStringAsFixed(0)}元';
    }
    return '${(fen / 100).toStringAsFixed(2)}元';
  }
}

class _SellerSalesKey {
  final int departmentId;
  final int sellerIdent;
  final int start;
  final int end;
  const _SellerSalesKey(this.departmentId, this.sellerIdent, this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SellerSalesKey &&
          departmentId == other.departmentId &&
          sellerIdent == other.sellerIdent &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(departmentId, sellerIdent, start, end);
}

final _sellerSalesProvider = FutureProvider.family<List<SellerSalesRankingItem>, _SellerSalesKey>((ref, key) async {
  final api = SalesStatisticApi();
  return api.sellerSalesRanking(
    minCreatedAt: key.start,
    maxCreatedAt: key.end,
    departmentId: key.departmentId > 0 ? key.departmentId : null,
  );
});

// ── 通用组件 ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final List<_StatItem> items;

  const _StatCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              return Column(
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        ],
      ),
    );
  }
}

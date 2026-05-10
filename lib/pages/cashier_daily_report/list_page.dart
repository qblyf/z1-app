import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/cashier_daily_report_api.dart';
import '../../models/cashier_daily_report.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

final _cashierApiProvider = Provider((_) => CashierDailyReportApi());

/// 收银日报列表页
class CashierDailyReportListPage extends ConsumerStatefulWidget {
  const CashierDailyReportListPage({super.key});

  @override
  ConsumerState<CashierDailyReportListPage> createState() =>
      _CashierDailyReportListPageState();
}

class _CashierDailyReportListPageState
    extends ConsumerState<CashierDailyReportListPage> {
  List<CashierDailyReport> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int _total = 0;

  // 筛选
  String? _stateFilter; // null=全部, unaudited, audited
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(_cashierApiProvider);
      final minTime = _startDate.copyWith(hour: 0, minute: 0, second: 0);
      final maxTime = _endDate.copyWith(hour: 23, minute: 59, second: 59);

      List<String>? states;
      if (_stateFilter != null) states = [_stateFilter!];

      final total = await api.count(
        minCashierTime: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCashierTime: maxTime.millisecondsSinceEpoch ~/ 1000,
        states: states,
      );

      final data = await api.list(
        minCashierTime: minTime.millisecondsSinceEpoch ~/ 1000,
        maxCashierTime: maxTime.millisecondsSinceEpoch ~/ 1000,
        states: states,
        limit: 20,
        offset: _page * 20,
      );

      setState(() {
        if (refresh) {
          _list = data;
        } else {
          _list.addAll(data);
        }
        _hasMore = data.length >= 20;
        _total = total;
        _isLoading = false;
        _page++;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadData(refresh: true);
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _FilterSheet(
        stateFilter: _stateFilter,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (state, start, end) {
          setState(() {
            _stateFilter = state;
            _startDate = start;
            _endDate = end;
          });
          _loadData(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        middle: const Text('收银日报'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.slider_horizontal_3),
              onPressed: _showFilterSheet,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.plus),
              onPressed: () => context.push('/cashier-daily-report/create'),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 统计摘要
            _SummaryBar(total: _total, count: _list.length),

            // 列表
            Expanded(
              child: _list.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.doc_text,
                              size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无收银日报', style: AppText.caption),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification &&
                            n.metrics.extentAfter < 100 &&
                            _hasMore &&
                            !_isLoading) {
                          _loadData();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          CupertinoSliverRefreshControl(onRefresh: _refresh),
                          SliverPadding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ReportCard(
                                  report: _list[i],
                                  onTap: () => context.push(
                                    '/cashier-daily-report/detail/${_list[i].departmentID}/${_list[i].date}',
                                  ),
                                ),
                                childCount: _list.length,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(child: CupertinoActivityIndicator()),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计摘要栏
class _SummaryBar extends StatelessWidget {
  final int total;
  final int count;

  const _SummaryBar({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: CupertinoColors.white,
      child: Row(
        children: [
          Text('共 $total 条', style: AppText.caption),
          const Spacer(),
          Text('本页 ${count} 条', style: AppText.caption),
        ],
      ),
    );
  }
}

/// 筛选面板
class _FilterSheet extends StatefulWidget {
  final String? stateFilter;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(String?, DateTime, DateTime) onApply;

  const _FilterSheet({
    required this.stateFilter,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _stateIndex; // 0=全部, 1=未审核, 2=已审核
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    if (widget.stateFilter == 'unaudited') {
      _stateIndex = 1;
    } else if (widget.stateFilter == 'audited') {
      _stateIndex = 2;
    } else {
      _stateIndex = 0;
    }
    _start = widget.startDate;
    _end = widget.endDate;
  }

  String? get _stateValue {
    if (_stateIndex == 1) return 'unaudited';
    if (_stateIndex == 2) return 'audited';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('筛选',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill,
                    color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 状态
          Text('状态', style: AppText.label),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _stateIndex,
            children: const {
              0: Text('全部'),
              1: Text('未审核'),
              2: Text('已审核'),
            },
            onValueChanged: (v) => setState(() => _stateIndex = v ?? 0),
          ),

          const SizedBox(height: AppSpacing.md),

          // 日期范围
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: '开始日期',
                  date: _start,
                  onChanged: (d) => setState(() => _start = d),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DatePickerField(
                  label: '结束日期',
                  date: _end,
                  onChanged: (d) => setState(() => _end = d),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_stateValue, _start, _end);
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }
}

/// 日期选择字段
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showDatePicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: AppText.body,
            ),
          ),
        ),
      ],
    );
  }

  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: date,
                maximumDate: DateTime.now(),
                onDateTimeChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 报表卡片
class _ReportCard extends StatelessWidget {
  final CashierDailyReport report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.date,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: report.state.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.state.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: report.state.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 信息行
            Row(
              children: [
                Icon(CupertinoIcons.building_2_fill,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(report.departmentName ?? '部门${report.departmentID}',
                    style: AppText.caption),
                const SizedBox(width: 12),
                Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(report.creatorName ?? '', style: AppText.caption),
              ],
            ),

            const SizedBox(height: 8),

            // 金额统计行
            Row(
              children: [
                _StatChip(
                  label: 'POS进账',
                  value: '¥${report.posIncomeYuan.toStringAsFixed(2)}',
                  color: const Color(0xFF0A84FF),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '银行',
                  value: '¥${report.bankIncomeYuan.toStringAsFixed(2)}',
                  color: const Color(0xFF30D158),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '其他',
                  value: '¥${report.totalOtherYuan.toStringAsFixed(2)}',
                  color: const Color(0xFFFF9500),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(report.formattedCreatedAt, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

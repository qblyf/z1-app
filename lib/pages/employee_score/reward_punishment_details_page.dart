import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/employee_score_api.dart';
import '../../models/employee_score.dart';
import '../../providers/employee_score_providers.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 赏罚工分明细页面
/// 对应 PWA: /employee-score/reward-punishment-details
class RewardPunishmentDetailsPage extends ConsumerStatefulWidget {
  const RewardPunishmentDetailsPage({super.key});

  @override
  ConsumerState<RewardPunishmentDetailsPage> createState() => _RewardPunishmentDetailsPageState();
}

class _RewardPunishmentDetailsPageState extends ConsumerState<RewardPunishmentDetailsPage> {
  /// 过滤类型：0=全部 1=本部门 2=我的
  int _filterType = 0;
  ScoreClass? _selectedClass;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  List<ScoreGiveLog> _items = [];
  int _total = 0;
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(employeeScoreApiProvider);
      final startTs = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0).millisecondsSinceEpoch ~/ 1000;
      final endTs = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

      final list = await api.getGiveLogDetailsList(
        classIds: _selectedClass != null ? [_selectedClass!.id] : null,
        minGiveAt: startTs,
        maxGiveAt: endTs,
        limit: 20,
        offset: _page * 20,
      );

      // 获取总数
      final count = await api.getGiveLogDetailsCount(
        classIds: _selectedClass != null ? [_selectedClass!.id] : null,
        minGiveAt: startTs,
        maxGiveAt: endTs,
      );

      setState(() {
        if (_page == 0) {
          _items = list;
        } else {
          _items.addAll(list);
        }
        _total = count;
        _hasMore = list.length >= 20;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    _page = 0;
    await _loadData();
  }

  void _onFilterChanged(int type) {
    setState(() => _filterType = type);
    _page = 0;
    _loadData();
  }

  void _onDateRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _page = 0;
    _loadData();
  }

  void _onClassSelected(ScoreClass? cls) {
    setState(() => _selectedClass = cls);
    _page = 0;
    _loadData();
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
        middle: const Text('赏罚工分明细'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add, size: 22),
          onPressed: () => context.push('/employee-score/apply'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 过滤器
            _FilterBar(
              filterType: _filterType,
              onFilterChanged: _onFilterChanged,
            ),

            // 日期 + 分类选择
            _FilterRow(
              startDate: _startDate,
              endDate: _endDate,
              selectedClass: _selectedClass,
              onDateTap: () => _showDateRangePicker(context),
              onClassTap: () => _showClassPicker(context),
              onClassClear: () => _onClassSelected(null),
            ),

            // 总数
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              color: CupertinoColors.white,
              child: Text(
                '共 $_total 条记录',
                style: AppText.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),

            // 列表
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.doc_text, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无记录', style: AppText.caption),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
                          _page++;
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
                                (_, i) => _ScoreLogCard(item: _items[i]),
                                childCount: _items.length,
                              ),
                            ),
                          ),
                          if (_isLoading && _page > 0)
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

  void _showClassPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _ClassPickerSheet(
        selectedClass: _selectedClass,
        onSelected: _onClassSelected,
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _DateRangePickerSheet(
        startDate: _startDate,
        endDate: _endDate,
        onConfirmed: _onDateRangeChanged,
      ),
    );
  }
}

// ── 过滤器栏 ─────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final int filterType;
  final ValueChanged<int> onFilterChanged;

  const _FilterBar({required this.filterType, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (0, '全部'),
      (1, '本部门'),
      (2, '我的'),
    ];
    return Container(
      height: 44,
      color: CupertinoColors.white,
      child: Row(
        children: tabs.map((t) {
          final isActive = filterType == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterChanged(t.$1),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey5,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? const Color(0xFF0A84FF) : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 日期+分类选择行 ─────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ScoreClass? selectedClass;
  final VoidCallback onDateTap;
  final VoidCallback onClassTap;
  final VoidCallback onClassClear;

  const _FilterRow({
    required this.startDate,
    required this.endDate,
    required this.selectedClass,
    required this.onDateTap,
    required this.onClassTap,
    required this.onClassClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: CupertinoColors.white,
          child: Row(
            children: [
              // 日期选择
              Expanded(
                child: GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 13, color: Color(0xFF666666)),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmt(startDate)}-${_fmt(endDate)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 分类选择
              GestureDetector(
                onTap: onClassTap,
                child: Container(
                  width: 110,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedClass?.name ?? '工分分类',
                          style: TextStyle(
                            fontSize: 11,
                            color: selectedClass != null ? const Color(0xFF000000) : const Color(0xFF999999),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedClass != null)
                        GestureDetector(
                          onTap: onClassClear,
                          child: const Text('X', style: TextStyle(fontSize: 13, color: Color(0xFFB4B4B4))),
                        )
                      else
                        const Text('∨', style: TextStyle(fontSize: 13, color: Color(0xFFB4B4B4))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

// ── 分类选择底部弹窗 ─────────────────────────────────────────────────────
class _ClassPickerSheet extends ConsumerStatefulWidget {
  final ScoreClass? selectedClass;
  final ValueChanged<ScoreClass?> onSelected;

  const _ClassPickerSheet({required this.selectedClass, required this.onSelected});

  @override
  ConsumerState<_ClassPickerSheet> createState() => _ClassPickerSheetState();
}

class _ClassPickerSheetState extends ConsumerState<_ClassPickerSheet> {
  List<ScoreClass> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final api = EmployeeScoreApi();
      final list = await api.getClassList();
      setState(() {
        _classes = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择工分分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey3, size: 24),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CupertinoActivityIndicator(),
              )
            else
              ..._classes.map((cls) {
                final isSelected = widget.selectedClass?.id == cls.id;
                return GestureDetector(
                  onTap: () {
                    widget.onSelected(cls);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                    decoration: BoxDecoration(
                      border: const Border(bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5)),
                      color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(cls.name, style: const TextStyle(fontSize: 15)),
                        ),
                        if (isSelected)
                          const Icon(CupertinoIcons.checkmark, color: Color(0xFF0A84FF), size: 18),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ── 积分记录卡片 ─────────────────────────────────────────────────────
class _ScoreLogCard extends StatelessWidget {
  final ScoreGiveLog item;

  const _ScoreLogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final score = item.effectiveScore;
    final isReward = score >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE9E9E9).withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：员工名 + 积分 + 时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${item.employeeName ?? '员工 ${item.userIdent}'}${isReward ? '获得' : '扣除'}${_formatScore(score.abs())}分${isReward ? '奖励' : '处罚'}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(item.givenAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行：部门
          if (item.departmentName != null && item.departmentName!.isNotEmpty) ...[
            Text(
              '部门名称：${item.departmentName ?? ''}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          // 第三行：补充说明
          if (item.effectiveRemark != null && item.effectiveRemark!.isNotEmpty)
            Text(
              '补充说明：${item.effectiveRemark ?? ''}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 10000) return (score / 100).toStringAsFixed(1);
    return score.toString();
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── 日期范围选择底部弹窗 ─────────────────────────────────────────────────────
class _DateRangePickerSheet extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onConfirmed;

  const _DateRangePickerSheet({
    required this.startDate,
    required this.endDate,
    required this.onConfirmed,
  });

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _pickingStart = true;

  @override
  void initState() {
    super.initState();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('选择日期范围', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('确认'),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onConfirmed(_start, _end);
                    },
                  ),
                ],
              ),
            ),
            // 快捷选择
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              child: Row(
                children: [
                  _QuickChip(label: '近7天', onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _start = DateTime(now.year, now.month, now.day - 7);
                      _end = DateTime(now.year, now.month, now.day);
                    });
                  }),
                  const SizedBox(width: 8),
                  _QuickChip(label: '近30天', onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _start = DateTime(now.year, now.month, now.day - 30);
                      _end = DateTime(now.year, now.month, now.day);
                    });
                  }),
                  const SizedBox(width: 8),
                  _QuickChip(label: '本月', onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _start = DateTime(now.year, now.month, 1);
                      _end = DateTime(now.year, now.month, now.day);
                    });
                  }),
                ],
              ),
            ),
            // Tab 切换
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  _TabButton(label: '开始: ${_fmt(_start)}', isActive: _pickingStart, onTap: () => setState(() => _pickingStart = true)),
                  const SizedBox(width: 12),
                  _TabButton(label: '结束: ${_fmt(_end)}', isActive: !_pickingStart, onTap: () => setState(() => _pickingStart = false)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 日期选择器
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _pickingStart ? _start : _end,
                maximumDate: _pickingStart ? _end : DateTime.now(),
                minimumDate: _pickingStart ? null : (_pickingStart ? null : _start),
                onDateTimeChanged: (d) {
                  setState(() {
                    if (_pickingStart) {
                      _start = d;
                    } else {
                      _end = d;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF))),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A84FF) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: isActive ? CupertinoColors.white : const Color(0xFF666666)),
        ),
      ),
    );
  }
}


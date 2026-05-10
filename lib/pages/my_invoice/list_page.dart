import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../api/my_invoice_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 我的发票申请列表页
/// 对应 PWA /pages/path-d/my-invoice/application-list.tsx
class MyInvoiceListPage extends ConsumerStatefulWidget {
  const MyInvoiceListPage({super.key});

  @override
  ConsumerState<MyInvoiceListPage> createState() => _MyInvoiceListPageState();
}

class _MyInvoiceListPageState extends ConsumerState<MyInvoiceListPage> {
  final MyInvoiceApi _api = MyInvoiceApi();

  List<MyInvoice> _list = [];
  bool _isLoading = false;

  // 筛选
  String _currentStatus = 'all';
  List<String> _currentTypes = [
    'paper-general',
    'elec-general',
    'paper-special',
    'elec-special',
    'digital-elec-special',
    'digital-elec-general',
  ];
  DateTime _startTime = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endTime = DateTime.now();

  // 时间范围选择
  bool _showTimeRange = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await _api.list(limit: 200);
      setState(() {
        _list = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<MyInvoice> get _filteredList {
    final minTime = _startTime.copyWith(hour: 0, minute: 0, second: 0);
    final maxTime = _endTime.copyWith(hour: 23, minute: 59, second: 59);
    final minTs = minTime.millisecondsSinceEpoch ~/ 1000;
    final maxTs = maxTime.millisecondsSinceEpoch ~/ 1000;

    return _list.where((item) {
      if (_currentStatus != 'all' && item.status != _currentStatus) return false;
      if (!_currentTypes.contains(item.invoiceType)) return false;
      if (item.applyTime < minTs || item.applyTime > maxTs) return false;
      return true;
    }).toList();
  }

  void _showTimeRangeSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _TimeRangeSheet(
        start: _startTime,
        end: _endTime,
        onApply: (start, end) {
          setState(() {
            _startTime = start;
            _endTime = end;
          });
        },
      ),
    );
  }

  void _showTypeFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _TypeFilterSheet(
        currentTypes: _currentTypes,
        onApply: (types) {
          setState(() => _currentTypes = types);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的发票申请'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 筛选栏
            _buildFilterBar(),

            // 列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.doc_text,
                                  size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 8),
                              Text('暂无发票申请', style: AppText.caption),
                            ],
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollEndNotification &&
                                n.metrics.extentAfter < 100 &&
                                !_isLoading) {
                              _loadData();
                            }
                            return false;
                          },
                          child: CustomScrollView(
                            slivers: [
                              CupertinoSliverRefreshControl(
                                  onRefresh: () => _loadData()),
                              SliverPadding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) => _InvoiceCard(
                                      item: _filteredList[i],
                                      onTap: () => context.push(
                                          '/my-invoice/detail/${_filteredList[i].id}'),
                                    ),
                                    childCount: _filteredList.length,
                                  ),
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // 时间 + 发票类型筛选
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showTimeRangeSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 14, color: Color(0xFF007AFF)),
                        const SizedBox(width: 4),
                        Text(
                          '${_startTime.month}/${_startTime.day}-${_endTime.month}/${_endTime.day}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF007AFF)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showTypeFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.tag, size: 14, color: Color(0xFF007AFF)),
                        const SizedBox(width: 4),
                        const Text('发票类型', style: TextStyle(fontSize: 13, color: Color(0xFF007AFF))),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 12, color: Color(0xFF007AFF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 状态标签
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _StatusChip(
                  label: '全部',
                  isActive: _currentStatus == 'all',
                  onTap: () => setState(() => _currentStatus = 'all'),
                ),
                ..._statusOptions.map((o) => _StatusChip(
                      label: o['label']!,
                      isActive: _currentStatus == o['value'],
                      onTap: () => setState(() => _currentStatus = o['value']!),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _statusOptions = [
    {'label': '未开票', 'value': 'no-invoice'},
    {'label': '待开票', 'value': 'to-be-invoiced'},
    {'label': '已开票', 'value': 'invoiced'},
    {'label': '已废弃', 'value': 'deprecated'},
    {'label': '红冲', 'value': 'reverse'},
  ];
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? CupertinoColors.white : const Color(0xFF8E8E93),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final MyInvoice item;
  final VoidCallback onTap;

  const _InvoiceCard({required this.item, required this.onTap});

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
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.invoiceHeader,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(fontSize: 12, color: item.statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.formattedAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ),
                Text(
                  item.invoiceTypeLabel,
                  style: AppText.caption,
                ),
                const SizedBox(width: 12),
                Text(item.formattedApplyTime, style: AppText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 时间范围选择 Sheet
class _TimeRangeSheet extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final void Function(DateTime, DateTime) onApply;

  const _TimeRangeSheet({required this.start, required this.end, required this.onApply});

  @override
  State<_TimeRangeSheet> createState() => _TimeRangeSheetState();
}

class _TimeRangeSheetState extends State<_TimeRangeSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.start;
    _end = widget.end;
  }

  void _showPicker({required bool isStart}) {
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
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isStart ? _start : _end,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (dt) {
                  setState(() {
                    if (isStart) _start = dt; else _end = dt;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md, right: AppSpacing.md,
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
              const Text('选择时间范围', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFC7C7CC), size: 28),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: '开始日期',
                  date: _start,
                  onTap: () => _showPicker(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(
                  label: '结束日期',
                  date: _end,
                  onTap: () => _showPicker(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_start, _end);
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
}

/// 发票类型筛选 Sheet
class _TypeFilterSheet extends StatefulWidget {
  final List<String> currentTypes;
  final void Function(List<String>) onApply;

  const _TypeFilterSheet({required this.currentTypes, required this.onApply});

  @override
  State<_TypeFilterSheet> createState() => _TypeFilterSheetState();
}

class _TypeFilterSheetState extends State<_TypeFilterSheet> {
  late List<String> _selected;

  static const _allTypes = [
    {'label': '纸质普票', 'value': 'paper-general'},
    {'label': '电子普票', 'value': 'elec-general'},
    {'label': '纸质专票', 'value': 'paper-special'},
    {'label': '电子专票', 'value': 'elec-special'},
    {'label': '数电票专用发票', 'value': 'digital-elec-special'},
    {'label': '数电票普通发票', 'value': 'digital-elec-general'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md, right: AppSpacing.md,
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
              const Text('发票类型', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFC7C7CC), size: 28),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ..._allTypes.map((t) {
            final isSelected = _selected.contains(t['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selected.remove(t['value']);
                  } else {
                    _selected.add(t['value']!);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFC7C7CC),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(t['label']!, style: AppText.body),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_selected);
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }
}

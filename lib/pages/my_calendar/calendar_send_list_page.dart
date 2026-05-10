import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/calendar_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 行事历 - 抄送给我的列表页
/// 对应 PWA /pages/path-d/my-calendar/send-list.tsx
class CalendarSendListPage extends ConsumerStatefulWidget {
  const CalendarSendListPage({super.key});

  @override
  ConsumerState<CalendarSendListPage> createState() => _CalendarSendListPageState();
}

class _CalendarSendListPageState extends ConsumerState<CalendarSendListPage> {
  final CalendarApi _api = CalendarApi();

  List<CalendarSendTask> _list = [];
  bool _isLoading = false;
  int _total = 0;

  // 筛选
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 3));
  DateTime _endDate = DateTime.now();
  int? _employeeId;
  String _taskName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    setState(() => _isLoading = true);

    try {
      // 获取数量
      final counts = await _api.getMyCalendarCount(
        currentUserType: 'send',
        responsibleEmployees: _employeeId != null ? [_employeeId!] : null,
        taskName: _taskName.isNotEmpty ? _taskName : null,
        taskLogStatus: ['finished'],
        statStartAt: _startDate.millisecondsSinceEpoch ~/ 1000,
        statEndAt: _endDate.millisecondsSinceEpoch ~/ 1000,
      );

      final finishedCount = counts.firstWhere((c) => c.status == 'finished', orElse: () => CalendarStatusCount(status: 'finished', count: 0)).count;
      if (finishedCount < 1) {
        setState(() { _list = []; _total = 0; _isLoading = false; });
        return;
      }

      final list = await _api.getMyCalendarList(
        currentUserType: 'send',
        responsibleEmployees: _employeeId != null ? [_employeeId!] : null,
        taskName: _taskName.isNotEmpty ? _taskName : null,
        taskLogStatus: ['finished'],
        statStartAt: _startDate.millisecondsSinceEpoch ~/ 1000,
        statEndAt: _endDate.millisecondsSinceEpoch ~/ 1000,
        limit: 300,
        offset: 0,
      );

      if (mounted) {
        setState(() { _list = list; _total = finishedCount; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    final taskNameCtrl = TextEditingController(text: _taskName);
    DateTime start = _startDate;
    DateTime end = _endDate;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('取消', style: TextStyle(color: Color(0xFF666666))),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const Spacer(),
                    const Text('筛选', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('确定', style: TextStyle(color: Color(0xFF0A84FF))),
                      onPressed: () {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                          _taskName = taskNameCtrl.text.trim();
                        });
                        _loadData(refresh: true);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择日期', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DateBtn(date: start, onTap: () async {
                              await showCupertinoModalPopup(
                                context: ctx,
                                builder: (_) => Container(
                                  height: 260, color: CupertinoColors.white,
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: start,
                                    onDateTimeChanged: (d) => setSheetState(() => start = d),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至')),
                          Expanded(
                            child: _DateBtn(date: end, onTap: () async {
                              await showCupertinoModalPopup(
                                context: ctx,
                                builder: (_) => Container(
                                  height: 260, color: CupertinoColors.white,
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: end,
                                    onDateTimeChanged: (d) => setSheetState(() => end = d),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('任务名称', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: taskNameCtrl,
                        placeholder: '输入任务名称',
                        padding: const EdgeInsets.all(12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Color _statusColor(String status) {
    switch (status) {
      case 'doing': return const Color(0xFF0A84FF);
      case 'unchecked': return const Color(0xFFFF9500);
      case 'finished': return const Color(0xFF30D158);
      case 'overdueFinished': return const Color(0xFFFF9F0A);
      case 'unfinished': return const Color(0xFFFF3B30);
      case 'invalid': return const Color(0xFF8E8E93);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'doing': return '进行中';
      case 'unchecked': return '待验收';
      case 'finished': return '已完成';
      case 'overdueFinished': return '逾期完成';
      case 'unfinished': return '未完成';
      case 'invalid': return '已作废';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('抄送给我的行事历'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showFilterSheet,
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 22),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部日期筛选
            Container(
              color: CupertinoColors.white,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (_) => _DateRangeSheet(
                          startDate: _startDate,
                          endDate: _endDate,
                          onApply: (s, e) {
                            setState(() { _startDate = s; _endDate = e; });
                            _loadData(refresh: true);
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text('选择日期', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                          const Spacer(),
                          Text(
                            '${_formatDate(_startDate)}-${_formatDate(_endDate)}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF999999)),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 0.5, margin: const EdgeInsets.only(left: 16), color: const Color(0xFFE5E5E5)),
                ],
              ),
            ),

            // 总数
            if (_total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Text('已完成 $_total 条', style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
              ),

            // 列表
            Expanded(
              child: _isLoading && _list.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : _list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.calendar, size: 48, color: Color(0xFFDDDDE0)),
                              const SizedBox(height: 16),
                              Text('暂无数据', style: AppText.body),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async { await _loadData(refresh: true); },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _list.length,
                            itemBuilder: (ctx, i) => _TaskCard(
                              task: _list[i],
                              statusColor: _statusColor(_list[i].taskLogStatus),
                              statusLabel: _statusLabel(_list[i].taskLogStatus),
                              onTap: () => context.push('/task-management/log/${_list[i].taskLogID}'),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final CalendarSendTask task;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.statusColor, required this.statusLabel, required this.onTap});

  String _formatTime(int ts) {
    if (ts == 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                if (task.categoryName != null && task.categoryName!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(task.categoryName!, style: const TextStyle(fontSize: 11, color: Color(0xFF5856D6))),
                  ),
                Expanded(
                  child: Text(
                    task.taskName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor)),
                ),
              ],
            ),
            if (task.introduction != null && task.introduction!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.introduction!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(
                  _formatTime(task.startAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
                const SizedBox(width: 12),
                if (task.duration > 0)
                  Text(
                    '时长 ${task.duration ~/ 60}小时${task.duration % 60 > 0 ? "${task.duration % 60}分钟" : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.person, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(
                  '负责人ID: ${task.responsibleEmployee}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
                const Spacer(),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateBtn({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}

class _DateRangeSheet extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onApply;

  const _DateRangeSheet({required this.startDate, required this.endDate, required this.onApply});

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      color: CupertinoColors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('取消', style: TextStyle(color: Color(0xFF666666))),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('确定', style: TextStyle(color: Color(0xFF0A84FF))),
                  onPressed: () {
                    widget.onApply(_start, _end);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _start,
                    onDateTimeChanged: (d) => setState(() => _start = d),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至')),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _end,
                    onDateTimeChanged: (d) => setState(() => _end = d),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const RefreshIndicator({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

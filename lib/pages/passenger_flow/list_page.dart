import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/passenger_flow_api.dart';
import '../../models/passenger_flow.dart';
import '../../theme/app_theme.dart';

/// 门店客流统计列表页
class PassengerFlowListPage extends ConsumerStatefulWidget {
  const PassengerFlowListPage({super.key});

  @override
  ConsumerState<PassengerFlowListPage> createState() => _PassengerFlowListPageState();
}

class _PassengerFlowListPageState extends ConsumerState<PassengerFlowListPage> {
  List<PassengerFlow> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  int _totalIn = 0;
  int _totalUnique = 0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) { _page = 0; _hasMore = true; }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final api = PassengerFlowApi();
      final minDate = _startDate.millisecondsSinceEpoch ~/ 1000;
      final maxDate = _endDate.millisecondsSinceEpoch ~/ 1000;

      final data = await api.list(
        minDate: minDate,
        maxDate: maxDate,
        limit: 50,
        offset: _page * 50,
      );

      final totalIn = data.fold<int>(0, (sum, f) => sum + f.count);
      final totalUnique = data.fold<int>(0, (sum, f) => sum + f.uniqueCount);

      setState(() {
        if (refresh) {
          _list = data;
        } else {
          _list.addAll(data);
        }
        _hasMore = data.length >= 50;
        _totalIn = totalIn;
        _totalUnique = totalUnique;
        _isLoading = false;
        _page++;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _DateFilterSheet(
        startDate: _startDate,
        endDate: _endDate,
        onApply: (start, end) {
          setState(() {
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
        middle: const Text('客流统计'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 汇总卡片
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: '进店人次',
                      value: '$_totalIn',
                      color: const Color(0xFFFF9500),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: '独立访客',
                      value: '$_totalUnique',
                      color: const Color(0xFF0A84FF),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _list.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_2, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无客流数据', style: AppText.caption),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
                          _loadData();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          CupertinoSliverRefreshControl(onRefresh: () => _loadData(refresh: true)),
                          SliverPadding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _FlowCard(item: _list[i]),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final PassengerFlow item;

  const _FlowCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.person_2_fill, color: Color(0xFF0A84FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.storeName ?? '门店${item.storeID}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.formattedDate} ${item.formattedTime} · ${item.timeSpan}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.count}',
                style: const TextStyle(
                  color: Color(0xFFFF9500),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              Text('人次', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateFilterSheet extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onApply;

  const _DateFilterSheet({
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
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
              const Text('日期筛选', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary),
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
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/ahs_api.dart';
import '../../api/dept_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 掌上回收统计 - 部门维度
class PalmRecycleDeptStatisticsPage extends ConsumerStatefulWidget {
  const PalmRecycleDeptStatisticsPage({super.key});

  @override
  ConsumerState<PalmRecycleDeptStatisticsPage> createState() => _PalmRecycleDeptStatisticsPageState();
}

class _PalmRecycleDeptStatisticsPageState extends ConsumerState<PalmRecycleDeptStatisticsPage> {
  List<AhsDeptStatistic> _list = [];
  Map<int, String> _deptNames = {};
  bool _isLoading = true;
  String? _error;

  // 默认本月
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = AhsApi();
      final deptApi = DeptApi();

      final minTs = _startDate.millisecondsSinceEpoch ~/ 1000;
      final maxTs = _endDate.millisecondsSinceEpoch ~/ 1000;

      final results = await Future.wait([
        api.deptStatistics(minCreatedAt: minTs, maxCreatedAt: maxTs),
        deptApi.getDepartmentList(),
      ]);

      final list = results[0] as List<AhsDeptStatistic>;
      final depts = results[1] as List<DeptInfo>;

      if (mounted) {
        setState(() {
          _list = list;
          _deptNames = {for (var d in depts) d.id: d.name};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showDateRangePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(child: const Text('确定'), onPressed: () {
                  Navigator.pop(ctx);
                  _loadData();
                }),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _startDate,
                onDateTimeChanged: (dt) => setState(() => _startDate = dt),
              ),
            ),
          ],
        ),
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
        middle: const Text('部门回收统计'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDateRangePicker,
          child: const Icon(CupertinoIcons.calendar),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 16, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 8),
                  Text(
                    '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')} ~ '
                    '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            // 汇总行
            if (_list.isNotEmpty) _buildSummary(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _error != null
                      ? Center(child: Text('加载失败: $_error'))
                      : _list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.chart_bar, size: 48, color: AppColors.textTertiary),
                                  const SizedBox(height: 8),
                                  Text('暂无统计数据', style: AppText.caption),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: _list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final item = _list[index];
                                return _DeptStatCard(
                                  item: item,
                                  deptName: _deptNames[item.department] ?? '部门 #${item.department}',
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final totalRecycleAmount = _list.fold<int>(0, (sum, item) => sum + item.recycleAmount);
    final totalRecycleCount = _list.fold<int>(0, (sum, item) => sum + item.recycleCount);
    final totalProfit = _list.fold<int>(0, (sum, item) => sum + item.estimatedProfit);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: '回收总额', value: '¥${(totalRecycleAmount / 100).toStringAsFixed(0)}'),
          _SummaryItem(label: '回收单量', value: '$totalRecycleCount'),
          _SummaryItem(label: '预估毛利', value: '¥${(totalProfit / 100).toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.white)),
      ],
    );
  }
}

class _DeptStatCard extends StatelessWidget {
  final AhsDeptStatistic item;
  final String deptName;

  const _DeptStatCard({required this.item, required this.deptName});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(CupertinoIcons.building_2_fill, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(deptName, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                '¥${(item.recycleAmount / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: '回收 ${item.recycleCount} 单', color: const Color(0xFF007AFF)),
              const SizedBox(width: 8),
              _StatChip(label: '有价值 ${item.valuableCount} 单', color: const Color(0xFF30D158)),
              const SizedBox(width: 8),
              _StatChip(label: '无价值 ${item.noValueCount} 单', color: const Color(0xFFFF9500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(label: '标准 ${item.mainProdCount}', color: const Color(0xFF5E5CE6)),
              const SizedBox(width: 8),
              _StatChip(label: '非标 ${item.itemProdCount}', color: const Color(0xFF8E8E93)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('回收成本: ', style: AppText.caption),
              Text('¥${(item.recycleCost / 100).toStringAsFixed(2)}', style: AppText.body),
              const Spacer(),
              Text('预估毛利: ', style: AppText.caption),
              Text(
                '¥${(item.estimatedProfit / 100).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: item.estimatedProfit >= 0 ? const Color(0xFF30D158) : const Color(0xFFFF3B30)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

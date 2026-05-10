import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';

/// 排序字段
enum TaskDimension {
  count('销量'),
  gross('毛利'),
  singleGross('单毛'),
  relatedRate('连带率');

  final String label;
  const TaskDimension(this.label);
}

/// 月度目标概览 Provider
final _monthlyGoalsProvider = FutureProvider.autoDispose
    .family<MonthlyGoalsPandect, ({int year, int month, int departmentId})>(
  (ref, params) async {
    return storekeeperDataApi.getMonthlyGoalsPandect(
      departmentId: params.departmentId,
      year: params.year,
      month: params.month,
    );
  },
);

class TargetGlancePage extends ConsumerStatefulWidget {
  const TargetGlancePage({super.key});

  @override
  ConsumerState<TargetGlancePage> createState() => _TargetGlancePageState();
}

class _TargetGlancePageState extends ConsumerState<TargetGlancePage> {
  // 模拟的部门ID，实际应从用户信息获取
  static const int _departmentId = 0;

  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  TaskDimension _selectedDimension = TaskDimension.count;

  @override
  Widget build(BuildContext context) {
    final pandectAsync = ref.watch(
      _monthlyGoalsProvider((year: _year, month: _month, departmentId: _departmentId)),
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('目标总览'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showYearMonthPicker,
          child: Text(
            '$_year-${_month.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
      child: SafeArea(
        child: pandectAsync.when(
          data: (pandect) => _buildContent(context, pandect),
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
                    onPressed: () => ref.invalidate(_monthlyGoalsProvider(
                      (year: _year, month: _month, departmentId: _departmentId),
                    )),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MonthlyGoalsPandect pandect) {
    // 计算主营销量和总毛利的进度
    final countTask = _findTaskByTitle(pandect, '主营商品销量');
    final grossTask = _findTaskByTitle(pandect, '总毛利');
    final countActual = _findActualByTitle(pandect, '主营商品销量');
    final grossActual = _findActualByTitle(pandect, '总毛利');

    final countTargetTotal = countTask?.goals ?? 0;
    final countTargetCurrent = countTask?.currentProgress ?? 0;
    final countCompleted = countActual?.value ?? 0;
    final countRatio = countTargetTotal > 0 ? countCompleted / countTargetTotal : 0.0;
    final countExpectRatio = countTargetTotal > 0 ? countTargetCurrent / countTargetTotal : 0.0;

    final grossTargetTotal = grossTask?.goals ?? 0;
    final grossTargetCurrent = grossTask?.currentProgress ?? 0;
    final grossCompleted = grossActual?.value ?? 0;
    final grossRatio = grossTargetTotal > 0 ? grossCompleted / grossTargetTotal : 0.0;
    final grossExpectRatio = grossTargetTotal > 0 ? grossTargetCurrent / grossTargetTotal : 0.0;

    // 按分类分组
    final categories = _getCategories(pandect);

    return CustomScrollView(
      slivers: [
        // 主营销量任务卡片
        SliverToBoxAdapter(
          child: _TaskProgressCard(
            title: '$_month月主营销量任务',
            completed: countCompleted,
            total: countTargetTotal,
            ratio: countRatio,
            expectRatio: countExpectRatio,
            expectValue: countTargetCurrent,
            dimension: '件',
            isCount: true,
          ),
        ),
        // 总毛利任务卡片
        SliverToBoxAdapter(
          child: _TaskProgressCard(
            title: '$_month月总毛利任务',
            completed: grossCompleted,
            total: grossTargetTotal,
            ratio: grossRatio,
            expectRatio: grossExpectRatio,
            expectValue: grossTargetCurrent,
            dimension: '元',
            isCount: false,
          ),
        ),
        // 分类统计表格
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // 维度选择
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: CupertinoSlidingSegmentedControl<TaskDimension>(
                    groupValue: _selectedDimension,
                    children: {
                      for (final dim in TaskDimension.values)
                        dim: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(dim.label, style: const TextStyle(fontSize: 12)),
                        ),
                    },
                    onValueChanged: (v) => setState(() => _selectedDimension = v!),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // 表头
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '类别',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '目标',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _selectedDimension == TaskDimension.relatedRate
                              ? '实际'
                              : '完成比',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                // 表格数据
                if (categories.isEmpty)
                  _buildEmptyState(context)
                else
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (final category in categories)
                          _buildCategoryRow(context, pandect, category),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                // 数据更新时间
                if (pandect.lastTime > 0)
                  Center(
                    child: Text(
                      '数据更新至 ${_formatDateTime(pandect.lastTime)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    MonthlyGoalsPandect pandect,
    String category,
  ) {
    final taskList = pandect.taskProgressRes.where((t) => t.category == category).toList();
    final actualList = pandect.actualValueRes;

    // 根据选择的维度获取对应数据
    TaskProgressRes? task;
    ActualValueRes? actual;

    switch (_selectedDimension) {
      case TaskDimension.count:
        task = taskList.where((t) => t.dimension == '销量').firstOrNull;
        actual = actualList.where((a) => a.title == task?.title).firstOrNull;
        break;
      case TaskDimension.gross:
        task = taskList.where((t) => t.dimension == '毛利').firstOrNull;
        actual = actualList.where((a) => a.title == task?.title).firstOrNull;
        break;
      case TaskDimension.singleGross:
        task = taskList.where((t) => t.dimension == '单毛').firstOrNull;
        actual = actualList.where((a) => a.title == task?.title).firstOrNull;
        break;
      case TaskDimension.relatedRate:
        task = taskList.where((t) => t.dimension == '连带率').firstOrNull;
        actual = actualList.where((a) => a.title == task?.title).firstOrNull;
        break;
    }

    final goals = task?.goals ?? 0;
    final actualValue = actual?.value;
    final isMarkRed = actualValue != null && actualValue < (task?.currentProgress ?? 0);

    String displayGoals = '-';
    String displayActual = '-';

    if (goals > 0) {
      if (_selectedDimension == TaskDimension.gross ||
          _selectedDimension == TaskDimension.singleGross) {
        displayGoals = '¥${_formatPrice(goals)}';
      } else {
        displayGoals = '$goals';
      }
    }

    if (actualValue != null) {
      if (_selectedDimension == TaskDimension.gross ||
          _selectedDimension == TaskDimension.singleGross) {
        displayActual = '¥${_formatPrice(actualValue)}';
      } else if (_selectedDimension == TaskDimension.relatedRate) {
        displayActual = '$actualValue';
      } else {
        final ratio = goals > 0 ? (actualValue / goals * 100).toStringAsFixed(1) : '0';
        displayActual = '$ratio%';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
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
            flex: 2,
            child: Text(
              category,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              displayGoals,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              displayActual,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isMarkRed
                    ? CupertinoColors.systemRed.resolveFrom(context)
                    : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.sm),
        ),
      ),
      child: Center(
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
              '暂无数据',
              style: AppText.body.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TaskProgressRes? _findTaskByTitle(MonthlyGoalsPandect pandect, String title) {
    return pandect.taskProgressRes.where((t) => t.title == title).firstOrNull;
  }

  ActualValueRes? _findActualByTitle(MonthlyGoalsPandect pandect, String title) {
    return pandect.actualValueRes.where((a) => a.title == title).firstOrNull;
  }

  List<String> _getCategories(MonthlyGoalsPandect pandect) {
    final categories = pandect.taskProgressRes
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    return categories;
  }

  void _showYearMonthPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: DateTime(_year, _month),
                onDateTimeChanged: (dateTime) {
                  setState(() {
                    _year = dateTime.year;
                    _month = dateTime.month;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return (price / 100).toStringAsFixed(0);
  }

  String _formatDateTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 任务进度卡片组件
class _TaskProgressCard extends StatelessWidget {
  final String title;
  final int completed;
  final int total;
  final double ratio;
  final double expectRatio;
  final int expectValue;
  final String dimension;
  final bool isCount;

  const _TaskProgressCard({
    required this.title,
    required this.completed,
    required this.total,
    required this.ratio,
    required this.expectRatio,
    required this.expectValue,
    required this.dimension,
    required this.isCount,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = ratio >= expectRatio
        ? AppColors.success
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 进度条
          _ProgressBar(
            ratio: ratio.clamp(0.0, 1.0),
            expectRatio: expectRatio.clamp(0.0, 1.0),
            color: progressColor,
            height: 10,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 进度文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCount
                    ? '$completed / $total $dimension'
                    : '¥${_formatPrice(completed)} / ¥${_formatPrice(total)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '期望进度: $expectValue $dimension',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return (price / 100).toStringAsFixed(0);
  }
}

/// 进度条组件
class _ProgressBar extends StatelessWidget {
  final double ratio;
  final double expectRatio;
  final Color color;
  final double height;

  const _ProgressBar({
    required this.ratio,
    required this.expectRatio,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // 背景
          Container(
            height: height,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          // 期望进度标记
          if (expectRatio > 0 && expectRatio < 1)
            Positioned(
              left: expectRatio * (MediaQuery.of(context).size.width - 64),
              child: Container(
                width: 2,
                height: height,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
          // 实际进度
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

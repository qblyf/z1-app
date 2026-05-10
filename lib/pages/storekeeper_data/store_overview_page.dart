import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_api.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 门店概况页面
/// 对应 PWA: /storekeeper-data/store-overview
class StoreOverviewPage extends ConsumerStatefulWidget {
  final int deptId;

  const StoreOverviewPage({super.key, required this.deptId});

  @override
  ConsumerState<StoreOverviewPage> createState() => _StoreOverviewPageState();
}

class _StoreOverviewPageState extends ConsumerState<StoreOverviewPage> {
  int _activeKey = 0; // 0=人员构成 1=任务达成 2=销售分析
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _showMonthPicker = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('门店概况'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 门店信息卡片
            _StoreInfoSection(deptId: widget.deptId),
            // Tab切换
            _TabBar(
              activeKey: _activeKey,
              onChanged: (k) => setState(() => _activeKey = k),
              onMonthTap: () => setState(() => _showMonthPicker = !_showMonthPicker),
              year: _selectedYear,
              month: _selectedMonth,
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
            // 内容区
            Expanded(
              child: _activeKey == 0
                  ? _PersonnelTab(deptId: widget.deptId)
                  : _activeKey == 1
                      ? _TaskTab(
                          deptId: widget.deptId,
                          year: _selectedYear,
                          month: _selectedMonth,
                        )
                      : _SalesTab(
                          deptId: widget.deptId,
                          year: _selectedYear,
                          month: _selectedMonth,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 门店信息区 ────────────────────────────────────────────────
class _StoreInfoSection extends ConsumerWidget {
  final int deptId;

  const _StoreInfoSection({required this.deptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 并行加载部门详情和门店信息
    final detailAsync = ref.watch(_storeDetailProvider(deptId));
    final storeInfoAsync = ref.watch(_storeInfoProvider(deptId));

    return detailAsync.when(
      data: (detail) {
        // storeInfoAsync 使用 whenData 只取 data 部分
        final storeInfo = storeInfoAsync.whenOrNull(data: (v) => v);
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      storeInfo?.name ?? detail?.name ?? '门店',
                      style: TextStyle(fontSize: 11, color: CupertinoColors.activeBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      storeInfo?.name ?? detail?.name ?? '门店详情',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: '负责人',
                value: storeInfo?.managerName ?? storeInfo?.manager ?? detail?.manager ?? '未设置',
              ),
              _InfoRow(
                label: '电话',
                value: storeInfo?.telephone ?? detail?.phone ?? '未设置',
                isLast: true,
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
        child: Text('加载失败: $e', style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

final _storeDetailProvider = FutureProvider.family<StoreDetail, int>((ref, deptId) async {
  final api = StorekeeperDataApi();
  return api.getStoreDetail(departmentId: deptId);
});

final _storeInfoProvider = FutureProvider.family<StoreInfo?, int>((ref, deptId) async {
  final api = StoreApi();
  return api.detail(departmentIDs: [deptId]);
});

// ── Tab栏 ───────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final int activeKey;
  final ValueChanged<int> onChanged;
  final VoidCallback onMonthTap;
  final int year;
  final int month;

  const _TabBar({
    required this.activeKey,
    required this.onChanged,
    required this.onMonthTap,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['人员构成', '任务达成', '销售分析'];
    return Container(
      color: CupertinoColors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final isActive = activeKey == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? CupertinoColors.activeBlue : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          GestureDetector(
            onTap: onMonthTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: CupertinoColors.systemGrey6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$year-$month',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 任务达成 Tab ─────────────────────────────────────────────
class _TaskTab extends ConsumerWidget {
  final int deptId;
  final int year;
  final int month;

  const _TaskTab({required this.deptId, required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 key 对象让 provider 能够响应年月变化
    final providerKey = _MonthKey(deptId, year, month);
    final pandectAsync = ref.watch(_monthlyGoalsProvider(providerKey));

    return pandectAsync.when(
      data: (pandect) {
        final tasks = pandect.taskProgressRes;
        final actuals = pandect.actualValueRes;

        if (tasks.isEmpty && actuals.isEmpty) {
          return const _EmptyState(message: '暂无任务数据');
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ...tasks.map((t) => _TaskProgressCard(task: t)),
            ...actuals.map((a) => _ActualValueCard(actual: a)),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => _ErrorState(message: e.toString()),
    );
  }
}

/// 用于 provider 响应式刷新的 key
class _MonthKey {
  final int deptId;
  final int year;
  final int month;
  const _MonthKey(this.deptId, this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MonthKey &&
          deptId == other.deptId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(deptId, year, month);
}

final _monthlyGoalsProvider = FutureProvider.family<MonthlyGoalsPandect, _MonthKey>((ref, key) async {
  final api = StorekeeperDataApi();
  return api.getMonthlyGoalsPandect(
    departmentId: key.deptId,
    year: key.year,
    month: key.month,
  );
});

class _TaskProgressCard extends StatelessWidget {
  final TaskProgressRes task;

  const _TaskProgressCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final progress = task.goals > 0 ? task.currentProgress / task.goals : 0.0;
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? CupertinoColors.activeGreen : CupertinoColors.activeOrange,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '目标: ${task.goals}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Text(
                '当前: ${task.currentProgress}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActualValueCard extends StatelessWidget {
  final ActualValueRes actual;

  const _ActualValueCard({required this.actual});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              actual.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Text(
            actual.value != null ? '${actual.value}' : '-',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeOrange,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 人员构成 Tab ─────────────────────────────────────────────
class _PersonnelTab extends StatelessWidget {
  final int deptId;

  const _PersonnelTab({required this.deptId});

  @override
  Widget build(BuildContext context) {
    // 人员构成需要员工列表 API，暂显示引导入口
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.person_2_fill,
                size: 48,
                color: CupertinoColors.systemGrey3,
              ),
              const SizedBox(height: 12),
              Text(
                '人员构成',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查看门店员工构成情况',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _QuickLinkCard(
          title: '员工销售排行',
          subtitle: '查看门店员工销售业绩排名',
          onTap: () => context.push('/storekeeper-data/employee-ranking'),
          icon: CupertinoIcons.chart_bar_alt_fill,
          color: const Color(0xFFBF5AF2),
        ),
        const SizedBox(height: 8),
        _QuickLinkCard(
          title: '员工业绩',
          subtitle: '员工业绩数据明细',
          onTap: () => context.push('/storekeeper-data/employee-ranking'),
          icon: CupertinoIcons.person_2_fill,
          color: const Color(0xFF5E5CE6),
        ),
      ],
    );
  }
}

// ── 销售分析 Tab ─────────────────────────────────────────────
class _SalesTab extends StatelessWidget {
  final int deptId;
  final int year;
  final int month;

  const _SalesTab({required this.deptId, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.chart_pie_fill,
                size: 48,
                color: CupertinoColors.systemGrey3,
              ),
              const SizedBox(height: 12),
              Text(
                '销售分析',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$year年$month月 门店销售数据综合分析',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _QuickLinkCard(
          title: '本月员工销售排行',
          subtitle: '查看员工销售数据',
          onTap: () => context.push('/storekeeper-data/employee-ranking'),
          icon: CupertinoIcons.person_2_fill,
          color: const Color(0xFFBF5AF2),
        ),
        const SizedBox(height: 8),
        _QuickLinkCard(
          title: '本月主推产品',
          subtitle: '重点产品销量统计',
          onTap: () => context.push('/storekeeper-data/main-products'),
          icon: CupertinoIcons.star_fill,
          color: const Color(0xFFFF9500),
        ),
        const SizedBox(height: 8),
        _QuickLinkCard(
          title: '本月门店排行',
          subtitle: '门店业绩排名',
          onTap: () => context.push('/storekeeper-data/store-ranking'),
          icon: CupertinoIcons.chart_bar_alt_fill,
          color: const Color(0xFF30D158),
        ),
        const SizedBox(height: 8),
        _QuickLinkCard(
          title: '资金周转',
          subtitle: '门店资金周转率',
          onTap: () => context.push('/storekeeper-data/capital-turnover'),
          icon: CupertinoIcons.money_dollar_circle_fill,
          color: const Color(0xFF64D2FF),
        ),
      ],
    );
  }
}

// ── 通用组件 ─────────────────────────────────────────────────
class _QuickLinkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _QuickLinkCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
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
          Text(
            message,
            style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '加载失败: $message',
          style: const TextStyle(color: CupertinoColors.destructiveRed),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/storekeeper_data_api.dart';
import '../../models/storekeeper_data.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 月度经营分析页面
/// 对应 PWA: /storekeeper-data/analyse-month-data
class AnalyseMonthPage extends ConsumerStatefulWidget {
  const AnalyseMonthPage({super.key});

  @override
  ConsumerState<AnalyseMonthPage> createState() => _AnalyseMonthPageState();
}

class _AnalyseMonthPageState extends ConsumerState<AnalyseMonthPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _showMonthPicker = false;

  @override
  Widget build(BuildContext context) {
    final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final endOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);
    final monthKey = _MonthKey(
      _selectedYear,
      _selectedMonth,
      startOfMonth.millisecondsSinceEpoch ~/ 1000,
      endOfMonth.millisecondsSinceEpoch ~/ 1000,
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
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
        middle: const Text('月度经营分析'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _showMonthPicker = !_showMonthPicker),
          child: Text(
            '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: _AnalyseMonthContent(
                key: ValueKey(monthKey),
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

// ── 内容区 ─────────────────────────────────────────────────────
class _AnalyseMonthContent extends ConsumerWidget {
  final int year;
  final int month;

  const _AnalyseMonthContent({super.key, required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    final key = _MonthKey(year, month, startOfMonth.millisecondsSinceEpoch ~/ 1000, endOfMonth.millisecondsSinceEpoch ~/ 1000);
    final asyncData = ref.watch(_monthAnalyseProvider(key));

    return asyncData.when(
      data: (data) => _buildContent(context, data),
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemRed),
              const SizedBox(height: 12),
              Text('加载失败: $e', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () => ref.invalidate(_monthAnalyseProvider(key)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ManagerHomepageData data) {
    final cards = _buildAnalyseCards(data.monthStatsRes);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // 月度类目单毛配比雷达图
        _RadarChartCard(stats: data.monthStatsRes),
        const SizedBox(height: AppSpacing.lg),
        // 标题
        Text(
          '月度销售',
          style: AppText.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        // 分类统计卡片
        ...cards,
      ],
    );
  }

  List<Widget> _buildAnalyseCards(TypePhaseStats stats) {
    final mainCount = _findValue(stats.count, '主营商品');
    final cards = <Widget>[];

    final categories = [
      ('主营', '主营商品'),
      ('连带', '连带商品'),
      ('会员', '会员产品'),
      ('智能', '智能产品'),
      ('配件', '配件产品'),
      ('保险', '服务产品'),
      ('回收', '回收商品'),
      ('维修', '保修维修'),
      ('运营商', '运营商'),
      ('二手良品', '非标商品'),
    ];

    for (final (title, key) in categories) {
      final gross = _findValue(stats.gross, key);
      final count = _findValue(stats.count, key);
      final relatedRate = _findValue(stats.relatedRate, key);
      final comparedGross = _findValue(stats.gross, key);

      // 配比 = 毛利 / 主营销量
      double allocation = 0;
      if (mainCount != null && mainCount.value != 0 && gross != null) {
        allocation = gross.value / mainCount.value;
      }

      // 环比: comparedValue 即上月同期数据
      final comparedPercent = comparedGross != null && comparedGross.comparedValue != 0
          ? ((gross?.value ?? 0) - comparedGross.comparedValue) / comparedGross.comparedValue
          : 0.0;

      cards.add(
        _AnalyseCard(
          title: title,
          allocation: allocation.toStringAsFixed(2),
          count: count?.value ?? 0,
          gross: _formatFen(gross?.value ?? 0),
          grossComparedPercent: '${comparedPercent >= 0 ? '+' : ''}${(comparedPercent * 100).toStringAsFixed(1)}%',
          relatedRate: relatedRate != null ? '${(relatedRate.value / 100).toStringAsFixed(1)}%' : '-',
          isUp: comparedPercent >= 0,
          isLast: title == '二手良品',
        ),
      );
    }

    return cards;
  }

  TypeStatsDataItem? _findValue(List<TypeStatsDataItem> list, String type) {
    return list.where((e) => e.type == type).firstOrNull;
  }

  String _formatFen(int fen) {
    if (fen >= 1000000) {
      return '¥${(fen / 10000).toStringAsFixed(0)}万';
    }
    return '¥${(fen / 100).toStringAsFixed(0)}';
  }
}

// ── 雷达图卡片 ─────────────────────────────────────────────────────
class _RadarChartCard extends StatelessWidget {
  final TypePhaseStats stats;

  const _RadarChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('月度类目单毛配比', style: AppText.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 240,
            child: CustomPaint(
              size: Size.infinite,
              painter: _RadarChartPainter(stats: stats),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final TypePhaseStats stats;
  static const List<(String, String)> _categories = [
    ('主营', '主营商品'),
    ('连带', '连带商品'),
    ('会员', '会员产品'),
    ('智能', '智能产品'),
    ('配件', '配件产品'),
    ('保险', '服务产品'),
    ('回收', '回收商品'),
    ('维修', '保修维修'),
    ('运营商', '运营商'),
  ];

  _RadarChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final n = _categories.length;
    const maxScore = 100.0;

    // 计算配比值（每个分类的配比）
    final mainCount = _findValue(stats.count, '主营商品');
    final ratios = <double>[];
    for (final (_, key) in _categories) {
      final gross = _findValue(stats.gross, key);
      double ratio = 0;
      if (mainCount != null && mainCount.value != 0 && gross != null) {
        ratio = (gross.value / mainCount.value).clamp(0.0, 10.0); // 配比上限10
      }
      ratios.add((ratio / 10.0 * maxScore).clamp(0.0, maxScore));
    }

    // 绘制背景网格（5层环形）
    final bgPaint = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, bgPaint);
    }

    // 绘制轴线
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, bgPaint);
    }

    // 绘制数据区域
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = const Color(0xFF0A84FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * ratios[i] / maxScore;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, linePaint);

    // 绘制数据点
    final dotPaint = Paint()
      ..color = const Color(0xFF0A84FF)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * ratios[i] / maxScore;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      canvas.drawCircle(point, 4, dotPaint);
    }

    // 绘制标签
    final labelStyle = TextStyle(
      color: const Color(0xFF8E8E93),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final labelRadius = radius + 14;
      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      final textSpan = TextSpan(text: _categories[i].$1, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double dx = labelX - textPainter.width / 2;
      double dy = labelY - textPainter.height / 2;

      // 微调左右对齐
      if (angle > math.pi * 0.4 && angle < math.pi * 0.6) {
        dx = labelX;
      } else if (angle > -math.pi * 0.6 && angle < -math.pi * 0.4) {
        dx = labelX - textPainter.width;
      }

      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  TypeStatsDataItem? _findValue(List<TypeStatsDataItem> list, String type) {
    return list.where((e) => e.type == type).firstOrNull;
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) => oldDelegate.stats != stats;
}

// ── 分析卡片 ─────────────────────────────────────────────────────
class _AnalyseCard extends StatelessWidget {
  final String title;
  final String allocation;
  final int count;
  final String gross;
  final String grossComparedPercent;
  final String relatedRate;
  final bool isUp;
  final bool isLast;

  const _AnalyseCard({
    required this.title,
    required this.allocation,
    required this.count,
    required this.gross,
    required this.grossComparedPercent,
    required this.relatedRate,
    required this.isUp,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
        border: isLast ? null : const Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 左侧：配比 + 品类名
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  allocation,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A84FF)),
                ),
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 右侧：各指标
          Expanded(
            child: Row(
              children: [
                _StatChip(label: '销量', value: '$count'),
                _StatChip(label: '毛利', value: gross),
                _StatChip(
                  label: '环比',
                  value: grossComparedPercent,
                  valueColor: isUp ? const Color(0xFFFF3B30) : const Color(0xFF30D158),
                ),
                _StatChip(label: '连带率', value: relatedRate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? CupertinoColors.label.resolveFrom(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          ),
        ],
      ),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────
class _MonthKey {
  final int year;
  final int month;
  final int start;
  final int end;
  const _MonthKey(this.year, this.month, this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MonthKey && year == other.year && month == other.month && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(year, month, start, end);
}

final _monthAnalyseProvider = FutureProvider.family<ManagerHomepageData, _MonthKey>((ref, key) async {
  final api = storekeeperDataApi;

  // 获取本月的起止时间戳
  final startOfMonth = DateTime(key.year, key.month, 1);
  final endOfMonth = DateTime(key.year, key.month + 1, 0, 23, 59, 59);

  // 调用月度数据接口，返回值中 comparedValue 即为上月同期数据（用于环比计算）
  final monthStats = await api.getTaskProgressActualValue(
    departmentId: 0, // TODO: 后续从用户信息获取真实部门ID
    startAt: startOfMonth.millisecondsSinceEpoch ~/ 1000,
    endAt: endOfMonth.millisecondsSinceEpoch ~/ 1000,
  );

  // 今日数据暂用月度数据代替，后续可增加今日vs昨日的对比
  return ManagerHomepageData(
    updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    todayStatsRes: monthStats,
    monthStatsRes: monthStats,
  );
});

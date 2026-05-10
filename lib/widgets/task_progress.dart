import 'package:flutter/cupertino.dart';

/// 任务进度条颜色套装
/// 与 PWA TaskProgress ColorSuit 对应
enum TaskProgressColorSuit {
  /// 蓝色（默认）
  blue,
  /// 红色（未达标/警告）
  red,
  /// 绿色（达标/完成）
  green,
  /// 灰色（禁用/空）
  grey,
}

/// 任务进度条组件
/// 对应 PWA mobile/TaskProgress.tsx
///
/// 支持：进度比例、期望值、左侧文字、颜色套装、自定义颜色
class TaskProgress extends StatelessWidget {
  /// 当前进度值，0.0 ~ 1.0（超过1.0按1.0处理）
  final double ratio;

  /// 进度条左侧文字（如 "¥45000/100000"）
  final String? barTextLeft;

  /// 是否显示右侧百分比文字
  final bool showPercentText;

  /// 颜色套装
  final TaskProgressColorSuit colorSuit;

  /// 自定义背景色（覆盖 colorSuit）
  final Color? colorBg;

  /// 自定义渐变起始色（覆盖 colorSuit）
  final Color? colorStart;

  /// 自定义渐变结束色（覆盖 colorSuit）
  final Color? colorCurrent;

  /// 期望进度位置比例（0.0 ~ 1.0）
  final double? expectRatio;

  /// 期望值文字（如 "60000"）
  final String? expectText;

  /// 宽度，默认全宽
  final double width;

  /// 进度条高度，默认 20
  final double barHeight;

  /// 字体大小，默认 16
  final double fontSize;

  const TaskProgress({
    super.key,
    required this.ratio,
    this.barTextLeft,
    this.showPercentText = true,
    this.colorSuit = TaskProgressColorSuit.blue,
    this.colorBg,
    this.colorStart,
    this.colorCurrent,
    this.expectRatio,
    this.expectText,
    this.width = double.infinity,
    this.barHeight = 20,
    this.fontSize = 16,
  });

  double get _effectiveRatio => ratio.clamp(0.0, 1.0);

  (Color, Color, Color) get _colors {
    if (colorBg != null || colorStart != null || colorCurrent != null) {
      return (
        colorBg ?? const Color(0xFFE5E5EA),
        colorStart ?? const Color(0xFF0A84FF),
        colorCurrent ?? const Color(0xFF0A84FF),
      );
    }
    switch (colorSuit) {
      case TaskProgressColorSuit.blue:
        return (
          const Color(0xFFCBE2FD),
          const Color(0xFF9182FE),
          const Color(0xFF53A0F9),
        );
      case TaskProgressColorSuit.red:
        return (
          const Color(0xFFFFE6E0),
          const Color(0xFFFB4E25),
          const Color(0xFFFFC664),
        );
      case TaskProgressColorSuit.green:
        return (
          const Color(0xFFD0F7E8),
          const Color(0xFF3BBB9E),
          const Color(0xFF65E3B2),
        );
      case TaskProgressColorSuit.grey:
        return (
          const Color(0xFFDBDCDD),
          const Color(0xFFDBDCDD),
          const Color(0xFFDBDCDD),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final borderRadius = barHeight / 2;
    final percentText = '${(_effectiveRatio * 100).round()}%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度条主体
            SizedBox(
              width: width == double.infinity ? null : width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景条
                  Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: colors.$1,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                  // 进度条
                  FractionallySizedBox(
                    widthFactor: _effectiveRatio,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.$2, colors.$3],
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Stack(
                        children: [
                          // 左侧文字
                          if (barTextLeft != null)
                            Positioned(
                              left: 6,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  barTextLeft!,
                                  style: TextStyle(
                                    fontSize: fontSize * 0.8,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          // 右侧百分比
                          if (showPercentText)
                            Positioned(
                              right: 6,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  percentText,
                                  style: TextStyle(
                                    fontSize: fontSize * 0.8,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.black,
                                  ),
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
            // 期望值标记
            if (expectRatio != null)
              _buildExpectMarker(effectiveWidth),
          ],
        );
      },
    );
  }

  Widget _buildExpectMarker(double effectiveWidth) {
    const markerWidth = 200.0;
    const halfMarkerWidth = markerWidth / 2;
    final markerCenter = effectiveWidth * expectRatio!.clamp(0.0, 1.0);
    final leftMargin = markerCenter.clamp(halfMarkerWidth, effectiveWidth - halfMarkerWidth);

    // 判断文字是否超出边界，调整偏移
    double textLeft = 0;
    if (markerCenter - halfMarkerWidth < 0) {
      textLeft = halfMarkerWidth - markerCenter;
    } else if (markerCenter + halfMarkerWidth > effectiveWidth) {
      textLeft = effectiveWidth - (markerCenter + halfMarkerWidth);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: effectiveWidth,
        child: Stack(
          children: [
            Positioned(
              left: leftMargin - halfMarkerWidth,
              width: markerWidth,
              child: Column(
                children: [
                  Center(
                    child: Text(
                      '▲',
                      style: TextStyle(
                        fontSize: fontSize * 0.5,
                        color: const Color(0xFFFF916F),
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (expectText != null)
                    Center(
                      child: Transform.translate(
                        offset: Offset(textLeft, 0),
                        child: Text(
                          expectText!,
                          style: TextStyle(
                            fontSize: fontSize * 0.9,
                            color: const Color(0xFFFF916F),
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

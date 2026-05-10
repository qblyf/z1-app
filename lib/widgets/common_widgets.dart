import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// 加载中组件
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppText.body.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 错误组件
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? title;

  const AppErrorWidget({
    super.key,
    this.message = '加载失败',
    this.onRetry,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null)
              Text(
                title!,
                style: AppText.subtitle.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppText.body.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('重新加载'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状态组件
class EmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;
  final String? title;

  const EmptyWidget({
    super.key,
    this.message = '暂无数据',
    this.icon = CupertinoIcons.tray,
    this.action,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                icon,
                size: 40,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                style: AppText.subtitle.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              style: AppText.body.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 状态标签
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory StatusBadge.success(String label) =>
      StatusBadge(label: label, color: AppColors.success);
  factory StatusBadge.warning(String label) =>
      StatusBadge(label: label, color: AppColors.warning);
  factory StatusBadge.error(String label) =>
      StatusBadge(label: label, color: AppColors.error);
  factory StatusBadge.info(String label) =>
      StatusBadge(label: label, color: AppColors.info);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppText.label.copyWith(color: color),
      ),
    );
  }
}

/// 金额显示
class AmountText extends StatelessWidget {
  final int amount;
  final double fontSize;
  final Color? color;

  const AmountText({
    super.key,
    required this.amount,
    this.fontSize = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '¥${(amount / 100).toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

/// 日期时间显示
class DateTimeText extends StatelessWidget {
  final int unix;
  final String format;

  const DateTimeText({
    super.key,
    required this.unix,
    this.format = 'yyyy-MM-dd HH:mm',
  });

  @override
  Widget build(BuildContext context) {
    if (unix == 0) return const Text('-');
    // unix 为秒级时间戳
    final date = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return Text(_formatDate(date, format));
  }

  String _formatDate(DateTime date, String format) {
    return format
        .replaceAll('yyyy', date.year.toString())
        .replaceAll('MM', date.month.toString().padLeft(2, '0'))
        .replaceAll('dd', date.day.toString().padLeft(2, '0'))
        .replaceAll('HH', date.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', date.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', date.second.toString().padLeft(2, '0'));
  }
}

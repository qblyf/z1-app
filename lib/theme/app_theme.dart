import 'package:flutter/cupertino.dart';

/// ============================================================
/// Z1 App 设计系统 / Design System
/// 统一颜色、圆角、阴影、间距、字体
/// ============================================================

// ── 品牌色 ──────────────────────────────────────────────────
class AppColors {
  AppColors._();

  /// 主色：深邃蓝（导航栏、按钮、强调）
  static const Color primary = Color(0xFF0A84FF);

  /// 辅助色：品牌绿（会员、扫码入口）
  static const Color accent = Color(0xFF30D158);

  /// 背景：系统浅灰
  static const Color background = Color(0xFFF2F2F7);

  /// 卡片白色
  static const Color card = CupertinoColors.white;

  /// 二级文字
  static Color textSecondary = CupertinoColors.secondaryLabel.darkColor;

  /// 三级文字
  static Color textTertiary = CupertinoColors.tertiaryLabel.darkColor;

  /// 分割线
  static const Color divider = Color(0xFFE5E5EA);

  /// 功能色
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error   = Color(0xFFFF3B30);
  static const Color info    = Color(0xFF0A84FF);

  /// 快捷功能卡片背景色
  static const Color quickActionBg = Color(0xFFF2F2F7);
}

// ── 圆角 ──────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  /// 小（标签、徽章）
  static const double sm = 8;
  /// 中（按钮、输入框）
  static const double md = 12;
  /// 大（卡片）
  static const double lg = 16;
  /// 特大（全屏卡片、底部弹窗）
  static const double xl = 24;
  /// 圆形
  static const double circle = 999;
}

// ── 间距 ──────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// ── 阴影 ──────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  /// 卡片阴影（轻微浮起感）
  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  /// 悬浮阴影（按钮按下、悬浮）
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  /// 底部标签栏阴影（向上投影）
  static List<BoxShadow> tabBar = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];
}

// ── 字体 ──────────────────────────────────────────────────
class AppText {
  AppText._();

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

// ── 通用卡片 ───────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}

// ── 快捷功能卡片 ───────────────────────────────────────────
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null && badge != '0')
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                      child: Text(
                        badge!.length > 3 ? '${badge!.substring(0, 3)}…' : badge!,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.label,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 头像 ──────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final double size;
  final Color? color;

  const UserAvatar({
    super.key,
    this.name,
    this.avatarUrl,
    this.size = 56,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true) ? name!.substring(0, 1) : 'U';
    final bgColor = color ?? AppColors.primary;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitial(bgColor, initial),
        ),
      );
    }
    return _buildInitial(bgColor, initial);
  }

  Widget _buildInitial(Color bgColor, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── 渐变背景登录页装饰 ─────────────────────────────────────
class GradientBgDecoration extends StatelessWidget {
  final Widget child;

  const GradientBgDecoration({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 顶部渐变光晕
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        // 右下角光晕
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

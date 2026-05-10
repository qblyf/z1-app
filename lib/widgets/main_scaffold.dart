import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// 主框架 — Cupertino 风格底部导航
/// 使用 CupertinoTabBar + SafeArea 替代 CupertinoTabScaffold
/// 避免与 GoRouter ShellRoute 的 GlobalKey 冲突
class MainScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _getIndex() {
    if (currentPath.startsWith('/member') || currentPath.startsWith('/stock')) return 1;
    if (currentPath.startsWith('/calendar')) return 2;
    if (currentPath.startsWith('/mall') ||
        currentPath.startsWith('/salesperson') ||
        currentPath.startsWith('/order')) {
      return 3;
    }
    if (currentPath.startsWith('/approval')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/member-management');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/mall-order');
        break;
      case 4:
        context.go('/approval');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // 页面内容层
          Positioned.fill(
            top: 0,
            bottom: 83,
            child: child,
          ),
          // 底部导航栏（固定在底部）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildTabBar(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final activeIndex = _getIndex();
    final labels = ['首页', '会员', '行事历', '订单', '审批'];
    final activeIcons = [
      CupertinoIcons.house_fill,
      CupertinoIcons.person_2_fill,
      CupertinoIcons.calendar_today,
      CupertinoIcons.bag_fill,
      CupertinoIcons.doc_text_fill,
    ];
    final inactiveIcons = [
      CupertinoIcons.house,
      CupertinoIcons.person_2,
      CupertinoIcons.calendar,
      CupertinoIcons.bag,
      CupertinoIcons.doc_text,
    ];

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        boxShadow: AppShadows.tabBar,
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = activeIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTap(context, index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? activeIcons[index] : inactiveIcons[index],
                      size: 24,
                      color: isActive
                          ? AppColors.primary
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

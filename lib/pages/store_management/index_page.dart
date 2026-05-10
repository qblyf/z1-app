import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// 门店管理首页
class StoreManagementIndexPage extends StatelessWidget {
  const StoreManagementIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('门店管理'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MenuCard(
              icon: CupertinoIcons.square_grid_2x2,
              title: '形象与展位',
              subtitle: '管理门店展位信息',
              color: CupertinoColors.activeOrange,
              onTap: () => context.push('/store-management/booth'),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: CupertinoIcons.building_2_fill,
              title: '门店信息',
              subtitle: '查看/编辑门店基本信息',
              color: CupertinoColors.activeBlue,
              onTap: () => context.push('/store-management/base-info'),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: CupertinoIcons.person_2,
              title: '部门切换',
              subtitle: '切换当前所属部门',
              color: CupertinoColors.activeGreen,
              onTap: () => context.push('/store-management/department-switch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

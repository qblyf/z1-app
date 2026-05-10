import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 发票申请入口页
/// 让用户选择"有订单申请"或"无订单申请"
class InvoiceApplicationPage extends StatelessWidget {
  /// 可选：预填的订单号（从其他页面跳转过来时）
  final String? orderNumber;

  const InvoiceApplicationPage({
    super.key,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('发票申请'),
        previousPageTitle: '返回',
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 无订单申请
                _ApplicationCard(
                  title: '无订单申请',
                  subtitle: '手动填写商品信息',
                  icon: CupertinoIcons.doc_text,
                  iconColor: const Color(0xFF0A84FF),
                  backgroundColor: const Color(0xFFE3F2FD),
                  onTap: () {
                    context.push('/invoice/application/form?type=no-order');
                  },
                ),
                const SizedBox(height: 60),
                // 有订单申请
                _ApplicationCard(
                  title: '有订单申请',
                  subtitle: '关联已有销售订单',
                  icon: CupertinoIcons.cart,
                  iconColor: const Color(0xFF34C759),
                  backgroundColor: const Color(0xFFE8F5E9),
                  onTap: () {
                    context.push('/invoice/application/form?type=with-order');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

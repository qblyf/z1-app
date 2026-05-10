import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// 调拨单入口页
/// 对应 PWA /pages/path-d/transfer-order/entry.tsx
class TransferOrderEntryPage extends StatelessWidget {
  const TransferOrderEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('调拨单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _EntryCard(
                icon: CupertinoIcons.cube_box_fill,
                iconColor: const Color(0xFF00C7BE),
                title: '我要出库',
                subtitle: '（面对面调拨）',
                onTap: () => context.push('/transfer-order/out-warehouse'),
              ),
              const SizedBox(height: AppSpacing.md),
              _EntryCard(
                icon: CupertinoIcons.arrow_right_arrow_left,
                iconColor: const Color(0xFF007AFF),
                title: '我要调拨',
                subtitle: '',
                onTap: () => context.push('/transfer-order/create'),
              ),
              const SizedBox(height: AppSpacing.md),
              _EntryCard(
                icon: CupertinoIcons.doc_text,
                iconColor: const Color(0xFF5856D6),
                title: '调拨单查询',
                subtitle: '',
                onTap: () => context.push('/transfer-order/list'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: AppText.caption.copyWith(
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/exclusive_shopping_guide_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 专属导购-我的客户列表页
/// 对应 PWA /pages/path-d/exclusive-shopping-guide/my-customer-list.tsx
class MyCustomerListPage extends ConsumerStatefulWidget {
  const MyCustomerListPage({super.key});

  @override
  ConsumerState<MyCustomerListPage> createState() => _MyCustomerListPageState();
}

class _MyCustomerListPageState extends ConsumerState<MyCustomerListPage> {
  final ExclusiveShoppingGuideApi _api = ExclusiveShoppingGuideApi();

  List<ShoppingGuideMember> _list = [];
  bool _isLoading = false;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userAsync = ref.read(currentUserProvider);
      final userId = userAsync.value?.userIdent;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final count = await _api.memberCount(userId);
      if (count == 0) {
        if (mounted) {
          setState(() {
            _total = 0;
            _list = [];
            _isLoading = false;
          });
        }
        return;
      }

      final list = await _api.memberList(userIdent: userId, limit: count);
      if (mounted) {
        setState(() {
          _total = count;
          _list = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnbindSheet(ShoppingGuideMember member) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('解除与 ${member.name} 的专属导购关系？'),
        message: const Text('解除后将无法查看该客户的消费记录等信息'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _unbind(member);
            },
            child: const Text('确认解除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _unbind(ShoppingGuideMember member) async {
    try {
      final success = await _api.unbind(member.userIdent);
      if (success && mounted) {
        setState(() => _list.remove(member));
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的客户'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => safePop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 统计栏
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Icon(CupertinoIcons.person_2_fill, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '共 $_total 位客户',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.person_2, size: 64, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('暂无专属客户', style: AppText.body),
                              const SizedBox(height: 4),
                              Text('请联系管理员分配客户', style: AppText.caption),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            CupertinoSliverRefreshControl(onRefresh: _loadData),
                            SliverPadding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _CustomerCard(
                                    member: _list[i],
                                    onUnbind: () => _showUnbindSheet(_list[i]),
                                  ),
                                  childCount: _list.length,
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

class _CustomerCard extends StatelessWidget {
  final ShoppingGuideMember member;
  final VoidCallback onUnbind;

  const _CustomerCard({required this.member, required this.onUnbind});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: CupertinoListTile(
        padding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              member.name.isNotEmpty ? member.name[0] : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(member.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                member.memberLevelName,
                style: const TextStyle(fontSize: 10, color: Color(0xFFFF9500)),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(CupertinoIcons.clock, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(member.formattedTime, style: AppText.caption),
            const SizedBox(width: 12),
            Icon(CupertinoIcons.money_dollar_circle, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(member.formattedAmount, style: AppText.caption.copyWith(color: const Color(0xFFFF9500))),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onUnbind,
          child: const Icon(
            CupertinoIcons.xmark_circle,
            size: 22,
            color: Color(0xFFFF3B30),
          ),
        ),
      ),
    );
  }
}

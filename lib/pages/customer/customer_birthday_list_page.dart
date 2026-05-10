import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/member_api.dart';
import '../../theme/app_theme.dart';

/// 客户生日关怀列表页
/// 对应 PWA /pages/path-d/customer/customer-birthday-list.tsx
class CustomerBirthdayListPage extends ConsumerStatefulWidget {
  /// 可选：指定月份的生日
  final int? birthdayMonth;
  final int? birthdayDay;

  const CustomerBirthdayListPage({
    super.key,
    this.birthdayMonth,
    this.birthdayDay,
  });

  @override
  ConsumerState<CustomerBirthdayListPage> createState() => _CustomerBirthdayListPageState();
}

class _CustomerBirthdayListPageState extends ConsumerState<CustomerBirthdayListPage> {
  final MemberApi _api = MemberApi();

  List<BirthdayMember> _list = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.listByBirth(
        month: widget.birthdayMonth,
        day: widget.birthdayDay,
      );
      if (mounted) {
        setState(() {
          _list = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<BirthdayMember> get _filtered {
    if (_searchText.isEmpty) return _list;
    final t = _searchText.toLowerCase();
    return _list.where((m) {
      return (m.name?.toLowerCase().contains(t) ?? false) ||
          (m.phone?.toLowerCase().contains(t) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.birthdayMonth != null
            ? '${widget.birthdayMonth}月${widget.birthdayDay ?? ''}日生日'
            : '客户生日关怀'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: CupertinoSearchTextField(
                placeholder: '搜索姓名/手机号',
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
            // 列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.gift, size: 64, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text('暂无生日会员', style: AppText.body),
                              const SizedBox(height: 4),
                              Text('本月无生日会员或已全部送完关怀', style: AppText.caption),
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
                                  (context, i) => _BirthdayMemberCard(member: _filtered[i]),
                                  childCount: _filtered.length,
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

class _BirthdayMemberCard extends StatelessWidget {
  final BirthdayMember member;
  const _BirthdayMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // 头像
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFFFF9F0A).withValues(alpha: 0.1),
            ),
            child: member.avatar != null && member.avatar!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CachedNetworkImage(
                      imageUrl: member.avatar!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholder(),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    ),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name ?? '未知', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                    if (member.memberLevelName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(member.memberLevelName!, style: const TextStyle(fontSize: 10, color: Color(0xFFFF9500))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (member.phone != null)
                  Text(member.phone!, style: AppText.caption),
                Row(
                  children: [
                    if (member.birthday != null) ...[
                      Icon(CupertinoIcons.gift, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(member.birthday!, style: AppText.caption),
                      const SizedBox(width: 8),
                    ],
                    if (member.lastConsumeTime != null) ...[
                      Icon(CupertinoIcons.clock, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('最近消费: ${member.lastConsumeTime}', style: AppText.caption),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 生日图标
          Column(
            children: [
              const Icon(CupertinoIcons.gift_fill, color: Color(0xFFFF9500), size: 24),
              if (member.consumeCount != null)
                Text('${member.consumeCount}次', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        member.name?.isNotEmpty == true ? member.name![0] : '?',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF9500)),
      ),
    );
  }
}

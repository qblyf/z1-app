import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/mall_activity_api.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

/// 商城活动列表页
/// 对应 PWA /pages/path-d/mall-activitys.tsx
class MallActivityListPage extends ConsumerStatefulWidget {
  const MallActivityListPage({super.key});

  @override
  ConsumerState<MallActivityListPage> createState() => _MallActivityListPageState();
}

class _MallActivityListPageState extends ConsumerState<MallActivityListPage> {
  final MallActivityApi _api = MallActivityApi();

  List<MallActivity> _list = [];
  bool _isLoading = true;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.list(limit: 50),
        _api.count(),
      ]);
      if (mounted) {
        setState(() {
          _list = results[0] as List<MallActivity>;
          _total = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('商城活动'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => safePop(context),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.gift, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('暂无商城活动', style: AppText.body),
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
                            (context, i) => _ActivityCard(
                              activity: _list[i],
                              onTap: () => _showActivityQR(_list[i]),
                            ),
                            childCount: _list.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showActivityQR(MallActivity activity) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _ActivityDetailSheet(activity: activity),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final MallActivity activity;
  final VoidCallback onTap;

  const _ActivityCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coverImage = activity.images.isNotEmpty ? activity.images.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            if (coverImage != null)
              CachedNetworkImage(
                imageUrl: coverImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: CupertinoColors.systemGrey6,
                  child: const Center(child: CupertinoActivityIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: CupertinoColors.systemGrey6,
                  child: const Icon(CupertinoIcons.photo, size: 48, color: CupertinoColors.systemGrey),
                ),
              )
            else
              Container(
                height: 160,
                color: CupertinoColors.systemGrey6,
                child: const Center(
                  child: Icon(CupertinoIcons.gift_fill, size: 48, color: CupertinoColors.systemGrey),
                ),
              ),
            // 信息
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activity.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.statusLabel,
                          style: TextStyle(fontSize: 12, color: activity.statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(activity.formattedTime, style: AppText.caption),
                      const SizedBox(width: 16),
                      Icon(CupertinoIcons.eye, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('${activity.pv}次浏览', style: AppText.caption),
                      if (activity.invitationEnabled) ...[
                        const SizedBox(width: 16),
                        Icon(CupertinoIcons.person_2, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text('邀请', style: AppText.caption),
                      ],
                    ],
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

class _ActivityDetailSheet extends StatelessWidget {
  final MallActivity activity;
  const _ActivityDetailSheet({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(activity.name, style: AppText.body.copyWith(fontWeight: FontWeight.bold)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (activity.images.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activity.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: activity.images[i],
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow('活动时间', activity.formattedTime),
          _InfoRow('状态', activity.statusLabel),
          _InfoRow('浏览量', '${activity.pv}'),
          _InfoRow('允许邀请', activity.invitationEnabled ? '是' : '否'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
          ),
          Expanded(child: Text(value, style: AppText.body)),
        ],
      ),
    );
  }
}

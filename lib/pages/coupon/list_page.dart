import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/coupon_api.dart';
import '../../models/coupon.dart';
import '../../theme/app_theme.dart';

final _couponListProvider = FutureProvider.autoDispose<List<Coupon>>((ref) async {
  return CouponApi().getList(
    limit: 20,
    offset: 0,
  );
});

final _couponCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return CouponApi().getCount();
});

class CouponListPage extends ConsumerStatefulWidget {
  const CouponListPage({super.key});

  @override
  ConsumerState<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends ConsumerState<CouponListPage> {
  int? _selectedStatus;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // TODO: 加载更多
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('重置'),
                      onPressed: () => setState(() => _selectedStatus = null),
                    ),
                    const Text('筛选', style: TextStyle(fontWeight: FontWeight.w600)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('完成'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('卡券状态', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(null, '全部'),
                        _buildChip(2, '可用'),
                        _buildChip(3, '已使用'),
                        _buildChip(1, '已失效'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(_couponCountProvider);
    final listAsync = ref.watch(_couponListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的卡券'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            countAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.systemGrey6,
                child: Text(
                  '共 $count 张卡券',
                  style: AppText.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: listAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.tickets, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无卡券', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async => ref.invalidate(_couponListProvider),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _CouponCard(coupon: list[index]),
                          childCount: list.length,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败: $e', style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(int? value, String label) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  Color get _statusColor {
    switch (coupon.state) {
      case 2: return const Color(0xFF30D158);
      case 3: return const Color(0xFF5E5CE6);
      case 1: return const Color(0xFF8E8E93);
      default: return const Color(0xFF8E8E93);
    }
  }

  String get _statusLabel {
    switch (coupon.state) {
      case 2: return '可用';
      case 3: return '已使用';
      case 1: return '已失效';
      default: return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statusColor.withValues(alpha: 0.8),
                  _statusColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.typeLabel,
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  coupon.formattedAmount,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
                const Spacer(),
                if (coupon.gotAt > 0) ...[
                  Text(
                    '领取: ${_formatDate(coupon.gotAt)}',
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    return '${dt.month}/${dt.day}';
  }
}

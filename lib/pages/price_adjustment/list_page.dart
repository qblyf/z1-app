import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/price_adjustment_api.dart';
import '../../models/price_adjustment.dart';
import '../../theme/app_theme.dart';

final _filterProvider = StateProvider<PriceAdjustmentFilter>((ref) {
  return PriceAdjustmentFilter();
});

class PriceAdjustmentFilter {
  final int? status;
  final int? type;
  final DateTime startDate;
  final DateTime endDate;
  final String? number;

  PriceAdjustmentFilter({
    this.status,
    this.type,
    DateTime? startDate,
    DateTime? endDate,
    this.number,
  })  : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  PriceAdjustmentFilter copyWith({
    int? status,
    int? type,
    DateTime? startDate,
    DateTime? endDate,
    String? number,
  }) {
    return PriceAdjustmentFilter(
      status: status ?? this.status,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      number: number ?? this.number,
    );
  }
}

final _listProvider = FutureProvider.autoDispose<List<PriceAdjustment>>((ref) async {
  final filter = ref.watch(_filterProvider);
  return priceAdjustmentApi.list(
    minCreatedAt: filter.startDate.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: filter.endDate.millisecondsSinceEpoch ~/ 1000 + 86399,
    status: filter.status != null ? [filter.status!] : null,
    types: filter.type != null ? [filter.type!] : null,
    number: filter.number,
  );
});

final _countProvider = FutureProvider.autoDispose<int>((ref) async {
  final filter = ref.watch(_filterProvider);
  return priceAdjustmentApi.count(
    minCreatedAt: filter.startDate.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: filter.endDate.millisecondsSinceEpoch ~/ 1000 + 86399,
    status: filter.status != null ? [filter.status!] : null,
    types: filter.type != null ? [filter.type!] : null,
    number: filter.number,
  );
});

class PriceAdjustmentListPage extends ConsumerStatefulWidget {
  const PriceAdjustmentListPage({super.key});

  @override
  ConsumerState<PriceAdjustmentListPage> createState() => _PriceAdjustmentListPageState();
}

class _PriceAdjustmentListPageState extends ConsumerState<PriceAdjustmentListPage> {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // TODO: 加载更多
    }
  }

  void _showFilterSheet() {
    final filter = ref.read(_filterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _FilterSheet(initialFilter: filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_listProvider);
    final countAsync = ref.watch(_countProvider);
    final filter = ref.watch(_filterProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('调价单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 统计栏
            countAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.systemGrey6,
                child: Row(
                  children: [
                    Text(
                      '共 $count 条调价单',
                      style: AppText.caption.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const Spacer(),
                    _FilterChip(label: _statusLabel(filter.status), onTap: _showFilterSheet),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 列表
            Expanded(
              child: listAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无调价单', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async => ref.invalidate(_listProvider),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _PriceAdjustmentCard(item: list[index]),
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

  String _statusLabel(int? status) {
    if (status == null) return '全部状态';
    return PriceAdjustmentState.fromValue(status)?.label ?? '全部状态';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppText.caption.copyWith(color: AppColors.primary)),
            const SizedBox(width: 2),
            const Icon(CupertinoIcons.chevron_down, size: 10, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _PriceAdjustmentCard extends StatelessWidget {
  final PriceAdjustment item;

  const _PriceAdjustmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.status.colorValue);

    return GestureDetector(
      onTap: () => context.push('/price-adjustment/detail/${item.priceAdjustmentId}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.number,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.label,
                    style: AppText.caption.copyWith(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoTag(
                  icon: CupertinoIcons.tag,
                  label: item.type.label,
                  color: const Color(0xFF5E5CE6),
                ),
                const SizedBox(width: 12),
                _InfoTag(
                  icon: CupertinoIcons.cube_box,
                  label: '${item.itemCount} 个商品',
                  color: const Color(0xFF64D2FF),
                ),
              ],
            ),
            if (item.totalLossCents != 0) ...[
              const SizedBox(height: 8),
              Text(
                '调价损失: ¥${(item.totalLossCents / 100).toStringAsFixed(2)}',
                style: AppText.caption.copyWith(color: const Color(0xFFFF3B30)),
              ),
            ],
            if (item.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTime(item.createdAt!),
                style: AppText.caption.copyWith(color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppText.caption.copyWith(color: color)),
      ],
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final PriceAdjustmentFilter initialFilter;

  const _FilterSheet({required this.initialFilter});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late int? _status;
  late int? _type;

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
    _type = widget.initialFilter.type;
  }

  void _apply() {
    ref.read(_filterProvider.notifier).state = widget.initialFilter.copyWith(
      status: _status,
      type: _type,
    );
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _status = null;
      _type = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // 标题栏
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
                    onPressed: _reset,
                  ),
                  const Text('筛选', style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('完成'),
                    onPressed: _apply,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('单据状态', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(null, '全部'),
                      ...PriceAdjustmentState.values.map(
                        (s) => _buildStatusChip(s.value, s.label),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('调价类型', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTypeChip(null, '全部'),
                      ...PriceAdjustmentType.values.map(
                        (t) => _buildTypeChip(t.value, t.label),
                      ),
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

  Widget _buildStatusChip(int? value, String label) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
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

  Widget _buildTypeChip(int? value, String label) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5E5CE6) : CupertinoColors.systemGrey6,
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

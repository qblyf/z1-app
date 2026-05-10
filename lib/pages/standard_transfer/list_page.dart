import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/transfer_order_api.dart';
import '../../models/transfer_order.dart';
import '../../theme/app_theme.dart';

final transferOrderApi = TransferOrderApi();

final _standardFilterProvider = StateProvider<_StandardFilter>((ref) {
  return _StandardFilter();
});

class _StandardFilter {
  final int? status;
  final DateTime startDate;
  final DateTime endDate;

  _StandardFilter({
    this.status,
    DateTime? startDate,
    DateTime? endDate,
  })  : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  _StandardFilter copyWith({int? status, DateTime? startDate, DateTime? endDate}) {
    return _StandardFilter(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

final _standardListProvider = FutureProvider.autoDispose<List<TransferOrder>>((ref) async {
  final filter = ref.watch(_standardFilterProvider);
  return transferOrderApi.list(
    minCreatedAt: filter.startDate.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: filter.endDate.millisecondsSinceEpoch ~/ 1000 + 86399,
    statusValues: filter.status != null ? [filter.status!] : null,
  );
});

final _standardCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final filter = ref.watch(_standardFilterProvider);
  return transferOrderApi.count(
    minCreatedAt: filter.startDate.millisecondsSinceEpoch ~/ 1000,
    maxCreatedAt: filter.endDate.millisecondsSinceEpoch ~/ 1000 + 86399,
    statusValues: filter.status != null ? [filter.status!] : null,
  );
});

class StandardTransferListPage extends ConsumerStatefulWidget {
  const StandardTransferListPage({super.key});

  @override
  ConsumerState<StandardTransferListPage> createState() => _StandardTransferListPageState();
}

class _StandardTransferListPageState extends ConsumerState<StandardTransferListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final filter = ref.read(_standardFilterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _StandardFilterSheet(initialFilter: filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_standardListProvider);
    final countAsync = ref.watch(_standardCountProvider);
    final filter = ref.watch(_standardFilterProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('标品调拨单'),
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
                      '共 $count 条调拨单',
                      style: AppText.caption.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter.status != null
                                  ? TransferOrderStatus.fromValue(filter.status!).label
                                  : '状态筛选',
                              style: AppText.caption.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(width: 2),
                            const Icon(CupertinoIcons.chevron_down, size: 10, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 48,
                            color: CupertinoColors.systemGrey3.resolveFrom(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '暂无调拨单',
                            style: AppText.body.copyWith(
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async => ref.invalidate(_standardListProvider),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _StandardTransferCard(item: list[index]),
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
}

class _StandardTransferCard extends StatelessWidget {
  final TransferOrder item;

  const _StandardTransferCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final productCount = item.products.length;

    return GestureDetector(
      onTap: () => context.push('/transfer-order/detail/${item.transferOrderID}'),
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
                    item.transferOrderNumber ?? '#${item.transferOrderID}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(status.colorValue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.label,
                    style: AppText.caption.copyWith(
                      color: Color(status.colorValue),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.cube_box, size: 14, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                const SizedBox(width: 4),
                Text(
                  '$productCount 件商品',
                  style: AppText.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
            if (item.createdAt > 0) ...[
              const SizedBox(height: 6),
              Text(
                _formatTime(item.createdAt),
                style: AppText.caption.copyWith(
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
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

class _StandardFilterSheet extends ConsumerStatefulWidget {
  final _StandardFilter initialFilter;

  const _StandardFilterSheet({required this.initialFilter});

  @override
  ConsumerState<_StandardFilterSheet> createState() => _StandardFilterSheetState();
}

class _StandardFilterSheetState extends ConsumerState<_StandardFilterSheet> {
  int? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
  }

  void _apply() {
    ref.read(_standardFilterProvider.notifier).state = widget.initialFilter.copyWith(status: _status);
    Navigator.pop(context);
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
                    onPressed: () => setState(() => _status = null),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(null, '全部'),
                      ...TransferOrderStatus.values.map(
                        (s) => _buildChip(s.value, s.label),
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

  Widget _buildChip(int? value, String label) {
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
}

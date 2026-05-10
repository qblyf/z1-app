import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/repair_order_api.dart';
import '../../models/repair_order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

final _filterProvider = StateProvider<_RepairFilter>((ref) => _RepairFilter());

class _RepairFilter {
  final RepairState? state;
  final RepairType? type;

  _RepairFilter({this.state, this.type});

  _RepairFilter copyWith({RepairState? state, RepairType? type, bool clearState = false, bool clearType = false}) {
    return _RepairFilter(
      state: clearState ? null : (state ?? this.state),
      type: clearType ? null : (type ?? this.type),
    );
  }
}

final _repairListProvider = FutureProvider.autoDispose<List<RepairOrder>>((ref) async {
  final filter = ref.watch(_filterProvider);
  final api = RepairOrderApi();
  return api.list(state: filter.state, repairType: filter.type?.value);
});

final _repairCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final filter = ref.watch(_filterProvider);
  final api = RepairOrderApi();
  return api.count(state: filter.state, repairType: filter.type?.value);
});

class RepairOrderListPage extends ConsumerStatefulWidget {
  const RepairOrderListPage({super.key});

  @override
  ConsumerState<RepairOrderListPage> createState() => _RepairOrderListPageState();
}

class _RepairOrderListPageState extends ConsumerState<RepairOrderListPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  List<RepairOrder> _allItems = [];
  int _offset = 0;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(refresh: true);
  }

  void _loadData({bool refresh = false}) {
    if (refresh) {
      _offset = 0;
      _allItems = [];
    }
    final filter = ref.read(_filterProvider);
    final api = RepairOrderApi();
    api.list(state: filter.state, repairType: filter.type?.value, limit: _limit, offset: _offset)
        .then((list) {
      if (mounted) {
        setState(() {
          if (refresh) {
            _allItems = list;
          } else {
            _allItems.addAll(list);
          }
          _offset += list.length;
          _loadingMore = false;
        });
      }
    });
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadingMore = true;
      _loadData();
    }
  }

  void _showFilterSheet() {
    final filter = ref.read(_filterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _RepairFilterSheet(current: filter, onChanged: (f) {
        ref.read(_filterProvider.notifier).state = f;
        _loadData(refresh: true);
      }),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(_repairCountProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
                leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
        middle: const Text('维修单'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.slider_horizontal_3),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            countAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.white,
                child: Row(
                  children: [
                    Text('共 $count 条', style: AppText.caption),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: _allItems.isEmpty && !_loadingMore
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.wrench, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无数据', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: _allItems.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: CupertinoColors.separator.resolveFrom(context)),
                      itemBuilder: (context, index) {
                        if (index >= _allItems.length) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CupertinoActivityIndicator()));
                        }
                        return _RepairOrderRow(item: _allItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepairOrderRow extends StatelessWidget {
  final RepairOrder item;
  const _RepairOrderRow({required this.item});

  Color _stateColor(BuildContext context) {
    switch (item.repairState) {
      case RepairState.pending:
        return const Color(0xFFFF9500);
      case RepairState.repairing:
        return const Color(0xFF007AFF);
      case RepairState.repairedConfirm:
      case RepairState.repairedNotice:
      case RepairState.repairedNoticed:
      case RepairState.repairedPicked:
        return const Color(0xFF30D158);
      case RepairState.unRepairableConfirm:
      case RepairState.unRepairableNotice:
      case RepairState.unRepairableNoticed:
      case RepairState.unRepairablePicked:
        return const Color(0xFFFF3B30);
      case RepairState.missingParts:
        return const Color(0xFFFF9F0A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.push('/repair-order/${item.repairID}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.repairType == RepairType.local
                        ? const Color(0xFF007AFF).withValues(alpha: 0.1)
                        : const Color(0xFFFF9500).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.repairType.label,
                    style: TextStyle(fontSize: 11, color: item.repairType == RepairType.local ? const Color(0xFF007AFF) : const Color(0xFFFF9500)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.repairNumber,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _stateColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.repairState.label,
                    style: TextStyle(fontSize: 11, color: _stateColor(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.description.isNotEmpty ? item.description : '无故障描述',
                    style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(item.createdAt),
                  style: AppText.caption.copyWith(color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int ts) {
    if (ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month}/${dt.day}';
  }
}

class _RepairFilterSheet extends StatelessWidget {
  final _RepairFilter current;
  final ValueChanged<_RepairFilter> onChanged;
  const _RepairFilterSheet({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('重置'),
                    onPressed: () {
                      onChanged(_RepairFilter());
                      Navigator.pop(context);
                    },
                  ),
                  const Text('筛选', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('完成'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('维修状态', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label: '不限',
                        selected: current.state == null,
                        onTap: () => onChanged(current.copyWith(clearState: true)),
                      ),
                      ...RepairState.values.map((s) => _Chip(
                        label: s.label,
                        selected: current.state == s,
                        onTap: () => onChanged(current.copyWith(state: s)),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('维修类型', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label: '不限',
                        selected: current.type == null,
                        onTap: () => onChanged(current.copyWith(clearType: true)),
                      ),
                      ...RepairType.values.map((t) => _Chip(
                        label: t.label,
                        selected: current.type == t,
                        onTap: () => onChanged(current.copyWith(type: t)),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : CupertinoColors.systemGrey5.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

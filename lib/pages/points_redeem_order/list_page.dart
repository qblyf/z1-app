import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../api/points_redeem_order_api.dart';
import '../../models/points_redeem_order.dart';
import '../../theme/app_theme.dart';

final _filterProvider = StateProvider<PointsRedeemOrderStatus?>((ref) => null);

class PointsRedeemOrderListPage extends ConsumerStatefulWidget {
  const PointsRedeemOrderListPage({super.key});

  @override
  ConsumerState<PointsRedeemOrderListPage> createState() => _PointsRedeemOrderListPageState();
}

class _PointsRedeemOrderListPageState extends ConsumerState<PointsRedeemOrderListPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  List<PointsRedeemOrder> _allItems = [];
  int _offset = 0;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(refresh: true);
  }

  void _loadData({bool refresh = false}) {
    if (refresh) _offset = 0;
    final filter = ref.read(_filterProvider);
    final api = PointsRedeemOrderApi();
    api.userList(limit: _limit, offset: _offset).then((list) {
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
      builder: (ctx) => _FilterSheet(current: filter, onChanged: (f) {
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
    final countAsync = PointsRedeemOrderApi().count(status: ref.watch(_filterProvider));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('积分兑换'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<int>(
              future: countAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.white,
                  child: Row(children: [Text('共 ${snapshot.data} 条', style: AppText.caption)]),
                );
              },
            ),
            Expanded(
              child: _allItems.isEmpty && !_loadingMore
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.gift, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无兑换记录', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
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
                        return _OrderRow(item: _allItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final PointsRedeemOrder item;
  const _OrderRow({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case PointsRedeemOrderStatus.unpaid:
        return const Color(0xFFFF9500);
      case PointsRedeemOrderStatus.paid:
        return const Color(0xFF007AFF);
      case PointsRedeemOrderStatus.completed:
        return const Color(0xFF30D158);
      case PointsRedeemOrderStatus.expired:
        return CupertinoColors.systemGrey;
      case PointsRedeemOrderStatus.applyForRefund:
        return const Color(0xFFFF3B30);
      case PointsRedeemOrderStatus.refunded:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.number, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(item.status.label, style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${item.points}积分', style: const TextStyle(fontSize: 11, color: Color(0xFF5E5CE6), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(item.transport.label, style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              ),
              const Spacer(),
              Text(_formatDate(item.createdAt), style: AppText.caption.copyWith(color: CupertinoColors.tertiaryLabel.resolveFrom(context))),
            ],
          ),
          if (item.payAmountCents != null && item.payAmountCents! > 0) ...[
            const SizedBox(height: 4),
            Text('实付 ¥${(item.payAmountCents! / 100).toStringAsFixed(2)}', style: AppText.caption.copyWith(color: const Color(0xFFFF3B30))),
          ],
        ],
      ),
    );
  }

  String _formatDate(int ts) {
    if (ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month}/${dt.day}';
  }
}

class _FilterSheet extends StatelessWidget {
  final PointsRedeemOrderStatus? current;
  final ValueChanged<PointsRedeemOrderStatus?> onChanged;
  const _FilterSheet({required this.current, required this.onChanged});

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
                    onPressed: () { onChanged(null); Navigator.pop(context); },
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
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: '不限', selected: current == null, onTap: () { onChanged(null); Navigator.pop(context); }),
                  ...PointsRedeemOrderStatus.values.map((s) => _Chip(
                    label: s.label,
                    selected: current == s,
                    onTap: () { onChanged(s); Navigator.pop(context); },
                  )),
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

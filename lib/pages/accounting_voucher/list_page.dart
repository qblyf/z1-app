import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/accounting_voucher_api.dart';
import '../../models/accounting_voucher.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

final _voucherFilterProvider = StateProvider<_VoucherFilter>((ref) => _VoucherFilter());

class _VoucherFilter {
  final int? state;
  final int? type;
  final int? year;
  final int? month;

  _VoucherFilter({this.state, this.type, this.year, this.month});

  _VoucherFilter copyWith({int? state, int? type, int? year, int? month, bool clearState = false, bool clearType = false}) {
    return _VoucherFilter(
      state: clearState ? null : (state ?? this.state),
      type: clearType ? null : (type ?? this.type),
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

class AccountingVoucherListPage extends ConsumerStatefulWidget {
  const AccountingVoucherListPage({super.key});

  @override
  ConsumerState<AccountingVoucherListPage> createState() => _AccountingVoucherListPageState();
}

class _AccountingVoucherListPageState extends ConsumerState<AccountingVoucherListPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  List<AccountingVoucher> _allItems = [];
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
    final filter = ref.read(_voucherFilterProvider);
    final api = AccountingVoucherApi();
    api.list(
      state: filter.state,
      type: filter.type,
      year: filter.year,
      month: filter.month,
      limit: _limit,
      offset: _offset,
    ).then((list) {
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
    final filter = ref.read(_voucherFilterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _VoucherFilterSheet(current: filter, onChanged: (f) {
        ref.read(_voucherFilterProvider.notifier).state = f;
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
    final countAsync = ref.watch(_voucherFilterProvider.notifier).state;

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
        middle: const Text('会计凭证'),
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
            Expanded(
              child: _allItems.isEmpty && !_loadingMore
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无凭证', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
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
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }
                        return _VoucherRow(item: _allItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoucherRow extends StatelessWidget {
  final AccountingVoucher item;
  const _VoucherRow({required this.item});

  Color get _stateColor {
    switch (item.state) {
      case VoucherState.s1:
        return const Color(0xFFFF9500);
      case VoucherState.s2:
        return const Color(0xFF30D158);
      case VoucherState.s3:
        return CupertinoColors.systemGrey;
      case VoucherState.s4:
      case VoucherState.s5:
        return const Color(0xFFFF3B30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/accounting-voucher/audit/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: CupertinoColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _stateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.state.label,
                    style: TextStyle(fontSize: 11, color: _stateColor, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.displayNumber,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5E5CE6), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (item.period.isNotEmpty)
                  Text(
                    item.period,
                    style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                  ),
                const Spacer(),
                Text(
                  _formatDate(item.createdAt),
                  style: AppText.caption.copyWith(color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ),
              ],
            ),
            if (item.remarks != null && item.remarks!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.remarks!,
                style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

class _VoucherFilterSheet extends StatelessWidget {
  final _VoucherFilter current;
  final ValueChanged<_VoucherFilter> onChanged;
  const _VoucherFilterSheet({required this.current, required this.onChanged});

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
                    onPressed: () { onChanged(_VoucherFilter()); Navigator.pop(context); },
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
                  Text('凭证状态', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VChip(
                        label: '不限',
                        selected: current.state == null,
                        onTap: () => onChanged(current.copyWith(clearState: true)),
                      ),
                      ...VoucherState.values.map((s) => _VChip(
                        label: s.label,
                        selected: current.state == s.value,
                        onTap: () => onChanged(current.copyWith(state: s.value)),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('凭证字号', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VChip(
                        label: '不限',
                        selected: current.type == null,
                        onTap: () => onChanged(current.copyWith(clearType: true)),
                      ),
                      ...VoucherType.values.map((t) => _VChip(
                        label: t.label,
                        selected: current.type == t.value,
                        onTap: () => onChanged(current.copyWith(type: t.value)),
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

class _VChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _VChip({required this.label, required this.selected, required this.onTap});

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

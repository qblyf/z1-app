import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/send_notice_api.dart';
import '../../models/send_notice.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 客户提醒列表页
class CustomerRemindListPage extends ConsumerStatefulWidget {
  const CustomerRemindListPage({super.key});

  @override
  ConsumerState<CustomerRemindListPage> createState() => _CustomerRemindListPageState();
}

class _CustomerRemindListPageState extends ConsumerState<CustomerRemindListPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  bool _isLoading = true;
  List<SendNotice> _list = [];
  int _offset = 0;
  int _total = 0;
  static const _limit = 20;

  // 筛选状态
  String? _statusFilter;
  String? _typeFilter;
  int _startDate = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
  int _endDate = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _isLoading = true;
    }

    final api = SendNoticeApi();
    try {
      final list = await api.list(
        types: _typeFilter != null ? [_typeFilter!] : null,
        status: _statusFilter != null ? [_statusFilter!] : null,
        minCreatedAt: _startDate,
        maxCreatedAt: _endDate,
        limit: _limit,
        offset: _offset,
      );
      final count = await api.count(
        types: _typeFilter != null ? [_typeFilter!] : null,
        status: _statusFilter != null ? [_statusFilter!] : null,
        minCreatedAt: _startDate,
        maxCreatedAt: _endDate,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _list = list;
          } else {
            _list.addAll(list);
          }
          _offset += list.length;
          _total = count;
          _isLoading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      setState(() => _loadingMore = true);
      _loadData();
    }
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _FilterSheet(
        statusFilter: _statusFilter,
        typeFilter: _typeFilter,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (status, type, start, end) {
          setState(() {
            _statusFilter = status;
            _typeFilter = type;
            _startDate = start;
            _endDate = end;
          });
          _loadData(refresh: true);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        middle: const Text('客户提醒'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/customer-remind/create'),
              child: const Icon(CupertinoIcons.add),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showFilterSheet,
              child: const Icon(CupertinoIcons.slider_horizontal_3),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Text('共 $_total 条', style: AppText.caption),
                  const Spacer(),
                  Text('本页 ${_list.length} 条', style: AppText.caption),
                ],
              ),
            ),
            Expanded(
              child: _isLoading && _list.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : _list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.bell, size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 8),
                              Text('暂无提醒', style: AppText.caption),
                            ],
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && !_loadingMore) {
                              setState(() => _loadingMore = true);
                              _loadData();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _list.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              if (index >= _list.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(child: CupertinoActivityIndicator()),
                                );
                              }
                              return _RemindCard(
                                item: _list[index],
                                onTap: () => context.push('/customer-remind/detail/${_list[index].sendNoticeId}'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemindCard extends StatelessWidget {
  final SendNotice item;
  final VoidCallback? onTap;

  const _RemindCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                    item.sendNoticeNumber,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(item.status.colorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(fontSize: 12, color: Color(item.status.colorValue), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(item.type.colorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.type.label, style: TextStyle(fontSize: 11, color: Color(item.type.colorValue))),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(item.method.colorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.method.label, style: TextStyle(fontSize: 11, color: Color(item.method.colorValue))),
                ),
                const SizedBox(width: 8),
                Text(item.formattedCreatedTime, style: AppText.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.info, style: AppText.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${item.receiverCount} 人', style: AppText.caption),
                const Spacer(),
                Icon(CupertinoIcons.clock, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('发送: ${item.formattedSendTime}', style: AppText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? statusFilter;
  final String? typeFilter;
  final int startDate;
  final int endDate;
  final void Function(String?, String?, int, int) onApply;

  const _FilterSheet({
    this.statusFilter,
    this.typeFilter,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _statusIndex;
  late int _typeIndex;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.statusFilter == null
        ? 0
        : SendNoticeStatus.values.indexWhere((s) => s.name == widget.statusFilter) + 1;
    if (_statusIndex < 0) _statusIndex = 0;
    _typeIndex = widget.typeFilter == null
        ? 0
        : SendNoticeType.values.indexWhere((t) => t.name == widget.typeFilter) + 1;
    if (_typeIndex < 0) _typeIndex = 0;
    _start = DateTime.fromMillisecondsSinceEpoch(widget.startDate * 1000);
    _end = DateTime.fromMillisecondsSinceEpoch(widget.endDate * 1000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md, right: AppSpacing.md,
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
              const Text('筛选', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('状态', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Chip(label: '全部', isActive: _statusIndex == 0, onTap: () => setState(() => _statusIndex = 0)),
              ...SendNoticeStatus.values.asMap().entries.map((e) =>
                _Chip(
                  label: e.value.label,
                  isActive: _statusIndex == e.key + 1,
                  onTap: () => setState(() => _statusIndex = e.key + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('类型', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Chip(label: '全部', isActive: _typeIndex == 0, onTap: () => setState(() => _typeIndex = 0)),
              ...SendNoticeType.values.asMap().entries.map((e) =>
                _Chip(
                  label: e.value.label,
                  isActive: _typeIndex == e.key + 1,
                  onTap: () => setState(() => _typeIndex = e.key + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              final status = _statusIndex == 0 ? null : SendNoticeStatus.values[_statusIndex - 1].name;
              final type = _typeIndex == 0 ? null : SendNoticeType.values[_typeIndex - 1].name;
              Navigator.pop(context);
              widget.onApply(status, type, _start.millisecondsSinceEpoch ~/ 1000, _end.millisecondsSinceEpoch ~/ 1000);
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? CupertinoColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

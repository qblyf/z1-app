import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../api/notice_center_api.dart';
import '../../models/notice_center.dart';
import '../../theme/app_theme.dart';

final _noticeFilterProvider = StateProvider<ReceiverType?>((ref) => null);

class NoticeCenterListPage extends ConsumerStatefulWidget {
  const NoticeCenterListPage({super.key});

  @override
  ConsumerState<NoticeCenterListPage> createState() => _NoticeCenterListPageState();
}

class _NoticeCenterListPageState extends ConsumerState<NoticeCenterListPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  List<NoticeLog> _allItems = [];
  int _offset = 0;
  NoticeCount _count = const NoticeCount(carbonCopyCount: 0, receiverCount: 0);
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(refresh: true);
    _loadCount();
  }

  void _loadData({bool refresh = false}) {
    if (refresh) _offset = 0;
    final filter = ref.read(_noticeFilterProvider);
    final api = NoticeCenterApi();
    api.list(receiverType: filter, limit: _limit, offset: _offset).then((list) {
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

  void _loadCount() {
    NoticeCenterApi().myCount().then((count) {
      if (mounted) setState(() => _count = count);
    });
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadingMore = true;
      _loadData();
    }
  }

  void _onFilterChanged(ReceiverType? type) {
    ref.read(_noticeFilterProvider.notifier).state = type;
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeType = ref.watch(_noticeFilterProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('通知中心'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 统计卡片
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  _StatCard(
                    label: '全部',
                    count: _count.total,
                    selected: activeType == null,
                    onTap: () => _onFilterChanged(null),
                  ),
                  _StatCard(
                    label: '收件人',
                    count: _count.receiverCount,
                    selected: activeType == ReceiverType.receiver,
                    onTap: () => _onFilterChanged(ReceiverType.receiver),
                  ),
                  _StatCard(
                    label: '抄送人',
                    count: _count.carbonCopyCount,
                    selected: activeType == ReceiverType.carbonCopy,
                    onTap: () => _onFilterChanged(ReceiverType.carbonCopy),
                  ),
                ],
              ),
            ),
            // 列表
            Expanded(
              child: _allItems.isEmpty && !_loadingMore
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.bell, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无通知', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
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
                        return _NoticeRow(item: _allItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primary : CupertinoColors.label.resolveFrom(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final NoticeLog item;
  const _NoticeRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUnread = item.readStatus == ReadStatus.unread;
    return Container(
      padding: const EdgeInsets.all(16),
      color: isUnread ? const Color(0xFFF0F7FF) : CupertinoColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  item.title,
                  style: AppText.body.copyWith(
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(item.createdAt),
                style: AppText.caption.copyWith(color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
              ),
            ],
          ),
          if (item.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.content,
              style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: item.receiverType == ReceiverType.carbonCopy
                      ? const Color(0xFFFF9500).withValues(alpha: 0.1)
                      : const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.receiverType.label,
                  style: TextStyle(fontSize: 10, color: item.receiverType == ReceiverType.carbonCopy ? const Color(0xFFFF9500) : const Color(0xFF007AFF)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(int ts) {
    if (ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    }
    return '${dt.month}/${dt.day}';
  }
}

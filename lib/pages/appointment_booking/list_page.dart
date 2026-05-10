import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/appointment_booking_api.dart';
import '../../models/appointment_booking.dart';
import '../../theme/app_theme.dart';

final _bookingFilterProvider = StateProvider<_BookingFilter>((ref) => _BookingFilter());

class _BookingFilter {
  final BookingStatus? status;
  _BookingFilter({this.status});
  _BookingFilter copyWith({BookingStatus? status, bool clearStatus = false}) {
    return _BookingFilter(status: clearStatus ? null : (status ?? this.status));
  }
}

class AppointmentBookingListPage extends ConsumerStatefulWidget {
  const AppointmentBookingListPage({super.key});

  @override
  ConsumerState<AppointmentBookingListPage> createState() => _AppointmentBookingListPageState();
}

class _AppointmentBookingListPageState extends ConsumerState<AppointmentBookingListPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  List<AppointmentBooking> _allItems = [];
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
    final filter = ref.read(_bookingFilterProvider);
    final api = AppointmentBookingApi();
    api.list(status: filter.status, limit: _limit, offset: _offset).then((list) {
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
    final filter = ref.read(_bookingFilterProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _BookingFilterSheet(current: filter, onChanged: (f) {
        ref.read(_bookingFilterProvider.notifier).state = f;
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
    final countAsync = AppointmentBookingApi().count(status: ref.watch(_bookingFilterProvider).status);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('国补预约'),
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
                          Icon(CupertinoIcons.calendar, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无预约', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
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
                        return _BookingRow(item: _allItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final AppointmentBooking item;
  const _BookingRow({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case BookingStatus.processing:
        return const Color(0xFFFF9500);
      case BookingStatus.accepted:
        return const Color(0xFF007AFF);
      case BookingStatus.completed:
        return const Color(0xFF30D158);
      case BookingStatus.canceled:
      case BookingStatus.closed:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.push('/appointment-booking/${item.id}'),
      child: Container(
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
                  child: Text(item.status.label, style: TextStyle(fontSize: 11, color: _statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.person, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Text(item.name, style: AppText.caption),
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.phone, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Text(item.phone, style: AppText.caption),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.location, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(item.fullAddress, style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Text(
                  _formatTime(item.appointmentStartTime),
                  style: AppText.caption.copyWith(color: const Color(0xFF007AFF)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int ts) {
    if (ts == 0) return '未设置';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _BookingFilterSheet extends StatelessWidget {
  final _BookingFilter current;
  final ValueChanged<_BookingFilter> onChanged;
  const _BookingFilterSheet({required this.current, required this.onChanged});

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
                    onPressed: () { onChanged(_BookingFilter()); Navigator.pop(context); },
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
                  Text('状态', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FChip(
                        label: '不限',
                        selected: current.status == null,
                        onTap: () => onChanged(current.copyWith(clearStatus: true)),
                      ),
                      ...BookingStatus.values.map((s) => _FChip(
                        label: s.label,
                        selected: current.status == s,
                        onTap: () => onChanged(current.copyWith(status: s)),
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

class _FChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FChip({required this.label, required this.selected, required this.onTap});

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

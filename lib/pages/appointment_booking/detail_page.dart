import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/appointment_booking_api.dart';
import '../../models/appointment_booking.dart';
import '../../theme/app_theme.dart';

class AppointmentBookingDetailPage extends ConsumerStatefulWidget {
  final int bookingID;

  const AppointmentBookingDetailPage({super.key, required this.bookingID});

  @override
  ConsumerState<AppointmentBookingDetailPage> createState() => _AppointmentBookingDetailPageState();
}

class _AppointmentBookingDetailPageState extends ConsumerState<AppointmentBookingDetailPage> {
  AppointmentBooking? _booking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = AppointmentBookingApi();
      final detail = await api.detail(widget.bookingID);
      if (mounted) {
        setState(() {
          _booking = detail;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('预约详情'),
        previousPageTitle: '返回',
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? Center(child: Text('加载失败: $_error', style: const TextStyle(color: CupertinoColors.systemRed)))
                : _booking == null
                    ? const Center(child: Text('未找到该预约'))
                    : _buildContent(_booking!),
      ),
    );
  }

  Widget _buildContent(AppointmentBooking booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor(booking.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor(booking.status).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(booking.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(booking.status.label, style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(booking.type.label, style: const TextStyle(color: Color(0xFF5E5CE6), fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(booking.number, style: AppText.subtitle.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 客户信息
          _Section(title: '客户信息', children: [
            _InfoRow(label: '姓名', value: booking.name),
            _InfoRow(label: '电话', value: booking.phone),
            _InfoRow(label: '地址', value: booking.fullAddress),
          ]),

          const SizedBox(height: 16),

          // 预约信息
          _Section(title: '预约时间', children: [
            _InfoRow(label: '开始时间', value: _formatDateTime(booking.appointmentStartTime)),
            _InfoRow(label: '结束时间', value: _formatDateTime(booking.appointmentEndTime)),
            if (booking.mallOrderNumber != null && booking.mallOrderNumber!.isNotEmpty)
              _InfoRow(label: '关联订单', value: booking.mallOrderNumber!),
          ]),

          const SizedBox(height: 16),

          // 处理信息
          _Section(title: '处理信息', children: [
            if (booking.handler != null)
              _InfoRow(label: '上门员工', value: 'ID: ${booking.handler}'),
            if (booking.dispatcher != null)
              _InfoRow(label: '指派人', value: 'ID: ${booking.dispatcher}'),
            if (booking.acceptedAt != null)
              _InfoRow(label: '接单时间', value: _formatDateTime(booking.acceptedAt!)),
            if (booking.completedAt != null)
              _InfoRow(label: '完成时间', value: _formatDateTime(booking.completedAt!)),
          ]),

          const SizedBox(height: 16),

          // 备注
          if (booking.remarks != null && booking.remarks!.isNotEmpty) ...[
            _Section(title: '备注', children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(booking.remarks!, style: AppText.body),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // 时间信息
          _Section(title: '时间信息', children: [
            _InfoRow(label: '创建时间', value: _formatDateTime(booking.createdAt)),
          ]),
        ],
      ),
    );
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
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

  String _formatDateTime(int ts) {
    if (ts == 0) return '未知';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator.resolveFrom(context), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }
}

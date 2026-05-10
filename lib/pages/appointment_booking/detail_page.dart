import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/appointment_booking_api.dart';
import '../../models/appointment_booking.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

class AppointmentBookingDetailPage extends ConsumerStatefulWidget {
  final int bookingID;

  const AppointmentBookingDetailPage({super.key, required this.bookingID});

  @override
  ConsumerState<AppointmentBookingDetailPage> createState() => _AppointmentBookingDetailPageState();
}

class _AppointmentBookingDetailPageState extends ConsumerState<AppointmentBookingDetailPage> {
  final AppointmentBookingApi _api = AppointmentBookingApi();

  AppointmentBooking? _booking;
  bool _loading = true;
  String? _error;
  bool _isOperating = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _api.detail(widget.bookingID);
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

  String _formatDateTime(int ts) {
    if (ts == 0) return '未知';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

  /// 统一的操作确认+执行
  Future<void> _doAction(
    String title,
    String confirmText,
    Future<bool> Function() action,
  ) async {
    if (_isOperating) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(confirmText),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isOperating = true);
    try {
      final ok = await action();
      if (mounted) {
        if (ok) {
          _loadDetail();
        } else {
          _showError('操作失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('操作失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  /// 带备注的操作（关闭/重新打开）
  Future<void> _doActionWithRemark(
    String title,
    Future<bool> Function(String remark) action,
  ) async {
    if (_isOperating) return;

    final textController = TextEditingController();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: textController,
            placeholder: '请输入备注',
            maxLines: 4,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (textController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true || textController.text.trim().isEmpty) return;

    setState(() => _isOperating = true);
    try {
      final ok = await action(textController.text.trim());
      if (mounted) {
        if (ok) {
          _loadDetail();
        } else {
          _showError('操作失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('操作失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
                    : Column(
                        children: [
                          Expanded(child: _buildContent(_booking!)),
                          _buildBottomActions(_booking!),
                        ],
                      ),
      ),
    );
  }

  Widget _buildBottomActions(AppointmentBooking booking) {
    final isAccepted = booking.status == BookingStatus.accepted;
    final isClosed = booking.status == BookingStatus.closed;

    if (!isAccepted && !isClosed) {
      // 待处理/已完成/已取消：无底栏按钮
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isAccepted
            ? Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isOperating
                          ? null
                          : () => _doActionWithRemark(
                                '关闭预约',
                                (remark) => _api.close(booking.id, remark),
                              ),
                      child: _isOperating
                          ? const CupertinoActivityIndicator()
                          : Container(
                              height: 44,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF007AFF)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '关闭',
                                style: TextStyle(color: Color(0xFF007AFF), fontSize: 15),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      padding: EdgeInsets.zero,
                      minSize: 44,
                      onPressed: _isOperating
                          ? null
                          : () => context.push(
                                '/store-retail/order/${booking.client}?appointmentBookingId=${booking.id}&appointmentBookingSkuID=${booking.sku}',
                              ),
                      child: const Text('创建零售单', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              )
            : // 已关闭 → 重新打开
            SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isOperating
                      ? null
                      : () => _doActionWithRemark(
                            '重新打开',
                            (remark) => _api.resetToProcessing(booking.id, remark),
                          ),
                  child: _isOperating
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('重新打开', style: TextStyle(fontSize: 15)),
                ),
              ),
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

          // 单据信息
          _Section(title: '单据信息', children: [
            _InfoRow(label: '预约单号', value: booking.number),
            _InfoRow(label: '创建时间', value: _formatDateTime(booking.createdAt)),
            if (booking.dispatcher != null)
              _InfoRow(label: '指派人', value: 'ID: ${booking.dispatcher}'),
            if (booking.editor != null)
              _InfoRow(label: '编辑员', value: 'ID: ${booking.editor}'),
            if (booking.handler != null)
              _InfoRow(label: '上门员工', value: 'ID: ${booking.handler}'),
          ]),
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

          // 预约商品
          _Section(title: '预约商品', children: [
            _InfoRow(label: '商品ID', value: 'SKU: ${booking.sku}'),
          ]),
          const SizedBox(height: 16),

          // 处理信息
          _Section(title: '处理信息', children: [
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

          // 职员备注
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('职员备注', style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              if (!(_isOperating))
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _showAddRemarkDialog(),
                  child: const Text('添加', style: TextStyle(fontSize: 14, color: Color(0xFF007AFF))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (booking.appointmentRemarks.isEmpty)
            _Section(title: '', children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('暂无备注', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
              ),
            ])
          else
            ...booking.appointmentRemarks.asMap().entries.map((entry) {
              final idx = entry.key;
              final remark = entry.value;
              return Column(
                children: [
                  _Section(title: '', children: [
                    _InfoRow(label: '时间', value: _formatDateTime(remark.createdAt)),
                    _InfoRow(label: '职员', value: 'ID: ${remark.employee}'),
                    _InfoRow(label: '内容', value: remark.remark),
                  ]),
                  if (idx < booking.appointmentRemarks.length - 1)
                    const SizedBox(height: 8),
                ],
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAddRemarkDialog() async {
    final textController = TextEditingController();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('添加备注'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: textController,
            placeholder: '请输入备注内容',
            maxLines: 4,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (textController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true || textController.text.trim().isEmpty) return;

    if (_isOperating) return;
    setState(() => _isOperating = true);
    try {
      final ok = await _api.callerEdit(widget.bookingID, appointmentRemarks: textController.text.trim());
      if (mounted) {
        if (ok) {
          _loadDetail();
        } else {
          _showError('添加备注失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('添加备注失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }
}

// ── 小组件 ────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ),
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

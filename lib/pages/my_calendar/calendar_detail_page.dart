import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar.dart';
import '../../providers/calendar_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 行事历详情页面
class CalendarDetailPage extends ConsumerStatefulWidget {
  final String id;

  const CalendarDetailPage({super.key, required this.id});

  @override
  ConsumerState<CalendarDetailPage> createState() => _CalendarDetailPageState();
}

class _CalendarDetailPageState extends ConsumerState<CalendarDetailPage> {
  CalendarTask? _calendar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final api = ref.read(calendarApiProvider);
      final calendar = await api.getDetail(widget.id);
      setState(() {
        _calendar = calendar;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('加载失败'),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('行事历详情'),
        ),
        child: const LoadingWidget(message: '加载中...'),
      );
    }

    if (_calendar == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('行事历详情'),
        ),
        child: const AppErrorWidget(message: '未找到行事历'),
      );
    }

    final calendar = _calendar!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('行事历详情'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.pencil),
          onPressed: () {},
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题和状态
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          calendar.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: calendar.statusLabel,
                        color: _getStatusColor(calendar.status),
                      ),
                    ],
                  ),
                  if (calendar.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      calendar.description!,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 时间信息
            _buildSection('时间', [
              _buildDetailItem(
                CupertinoIcons.play_arrow,
                '开始时间',
                DateTimeText(unix: calendar.startTime),
              ),
              _buildDetailItem(
                CupertinoIcons.stop,
                '结束时间',
                DateTimeText(unix: calendar.endTime),
              ),
            ]),

            // 地点
            if (calendar.location != null)
              _buildSection('地点', [
                _buildDetailItem(
                  CupertinoIcons.location,
                  '位置',
                  Text(calendar.location!),
                ),
              ]),

            // 签到记录
            _buildSection('签到记录', [
              _buildDetailItem(
                CupertinoIcons.arrow_right_circle,
                '签到',
                calendar.isCheckedIn
                    ? Row(
                        children: [
                          Icon(CupertinoIcons.checkmark_circle,
                              color: CupertinoColors.activeGreen, size: 16),
                          const SizedBox(width: 4),
                          DateTimeText(unix: calendar.checkInTime!),
                        ],
                      )
                    : Text('未签到',
                        style: TextStyle(
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context))),
              ),
              _buildDetailItem(
                CupertinoIcons.arrow_left_circle,
                '签退',
                calendar.isCheckedOut
                    ? Row(
                        children: [
                          Icon(CupertinoIcons.checkmark_circle_fill,
                              color: CupertinoColors.activeGreen, size: 16),
                          const SizedBox(width: 4),
                          DateTimeText(unix: calendar.checkOutTime!),
                        ],
                      )
                    : Text('未签退',
                        style: TextStyle(
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context))),
              ),
            ]),

            // 备注
            if (calendar.remark != null)
              _buildSection('备注', [Text(calendar.remark!)]),

            const SizedBox(height: 24),

            // 操作按钮
            if (!calendar.isCheckedIn)
              CupertinoButton.filled(
                onPressed: () => _handleCheckIn(context),
                child: const Text('签到'),
              ),

            if (calendar.isCheckedIn && !calendar.isCheckedOut) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                color: CupertinoColors.activeOrange,
                onPressed: () => _handleCheckOut(context),
                child: const Text('签退'),
              ),
            ],

            if (calendar.status == 2) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                color: CupertinoColors.activeGreen,
                onPressed: () => _handleComplete(context),
                child: const Text('完成'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CupertinoColors.secondaryLabel),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    final actionService = ref.read(calendarActionProvider);
    final result = await actionService.checkIn(_calendar!.id);

    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(result.success ? '成功' : '失败'),
          content:
              Text(result.success ? '签到成功' : '签到失败: ${result.message}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }

    if (result.success) _loadData();
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    final actionService = ref.read(calendarActionProvider);
    final result = await actionService.checkOut(_calendar!.id);

    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(result.success ? '成功' : '失败'),
          content:
              Text(result.success ? '签退成功' : '签退失败: ${result.message}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }

    if (result.success) _loadData();
  }

  Future<void> _handleComplete(BuildContext context) async {
    final actionService = ref.read(calendarActionProvider);
    final result = await actionService.complete(_calendar!.id);

    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(result.success ? '成功' : '失败'),
          content:
              Text(result.success ? '已完成' : '操作失败: ${result.message}'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }

    if (result.success) _loadData();
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return CupertinoColors.activeBlue;
      case 2:
        return CupertinoColors.activeOrange;
      case 3:
        return CupertinoColors.activeGreen;
      case 4:
        return CupertinoColors.systemGrey;
      case 5:
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/employee_score_api.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 员工积分申报详情页面
/// 对应 PWA: /employee-score/info
class EmployeeScoreInfoPage extends ConsumerStatefulWidget {
  /// 申报单ID
  final int applyId;

  const EmployeeScoreInfoPage({super.key, required this.applyId});

  @override
  ConsumerState<EmployeeScoreInfoPage> createState() => _EmployeeScoreInfoPageState();
}

class _EmployeeScoreInfoPageState extends ConsumerState<EmployeeScoreInfoPage> {
  late final FutureProvider<ScoreApply> _detailProvider;

  @override
  void initState() {
    super.initState();
    _detailProvider = FutureProvider.autoDispose((ref) async {
      final api = EmployeeScoreApi();
      return api.getApplyDetail(widget.applyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(_detailProvider);

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
        middle: const Text('申报详情'),
        trailing: detailAsync.whenOrNull(
          data: (apply) => apply.status == 1
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('操作', style: TextStyle(fontSize: 15)),
                  onPressed: () => _showActions(context, apply),
                )
              : null,
        ),
      ),
      child: detailAsync.when(
        data: (apply) => _buildContent(context, apply),
        loading: () => const LoadingWidget(message: '加载中...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_detailProvider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScoreApply apply) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 状态卡片
          _StatusCard(apply: apply),
          const SizedBox(height: AppSpacing.lg),
          // 基本信息
          _SectionCard(
            title: '申报信息',
            children: [
              _InfoRow('申报标题', apply.title ?? '积分申报'),
              _InfoRow('申报分类', apply.className ?? '未知分类'),
              _InfoRow('发生时间', _formatTime(apply.happenedAt)),
              _InfoRow('申报部门', apply.departmentName ?? '未知部门'),
              _InfoRow('创建人', apply.creatorName ?? '未知'),
              _InfoRow('创建时间', _formatTime(apply.createdAt)),
              if (apply.description != null && apply.description!.isNotEmpty)
                _InfoRow('事件描述', apply.description!, isLast: true),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 申报明细
          _SectionCard(
            title: '申报明细',
            children: [
              ...apply.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == apply.items.length - 1;
                return _EmployeeScoreRow(item: item, isLast: isLast);
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, ScoreApply apply) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('申报操作'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmApply(apply);
            },
            child: const Text('确认通过'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _rejectApply(apply);
            },
            child: const Text('拒绝申报'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _confirmApply(ScoreApply apply) async {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('确认通过'),
        content: Text('确认 "${apply.title ?? '该申报'}" 通过审核？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('确认'),
            onPressed: () async {
              Navigator.pop(context);
              final api = EmployeeScoreApi();
              final ok = await api.confirmApply(apply.id);
              if (ok) {
                ref.invalidate(_detailProvider);
              }
            },
          ),
        ],
      ),
    );
  }

  void _rejectApply(ScoreApply apply) {
    final reasonController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('拒绝申报'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text('请输入拒绝原因（可选）'),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: reasonController,
              placeholder: '拒绝原因',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('拒绝'),
            onPressed: () async {
              Navigator.pop(context);
              final api = EmployeeScoreApi();
              await api.rejectApply(
                apply.id,
                reason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              ref.invalidate(_detailProvider);
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── 状态卡片 ─────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final ScoreApply apply;

  const _StatusCard({required this.apply});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (apply.status) {
      case 1:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF9500);
        statusText = '待确认';
        icon = CupertinoIcons.clock;
        break;
      case 2:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF30D158);
        statusText = '已确认';
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case 3:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFFF3B30);
        statusText = '已拒绝';
        icon = CupertinoIcons.xmark_circle_fill;
        break;
      default:
        bgColor = const Color(0xFFF2F2F7);
        textColor = const Color(0xFF8E8E93);
        statusText = '未知';
        icon = CupertinoIcons.info_circle;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (apply.status == 2 && apply.confirmedName != null)
                  Text(
                    '确认人: ${apply.confirmedName}',
                    style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.8)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 信息区域卡片 ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppText.subtitle.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── 信息行 ─────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
            ),
          ),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }
}

// ── 员工积分明细行 ─────────────────────────────────────────────────────
class _EmployeeScoreRow extends StatelessWidget {
  final ScoreApplyItem item;
  final bool isLast;

  const _EmployeeScoreRow({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                (item.userName?.isNotEmpty == true)
                    ? item.userName!.substring(0, 1)
                    : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 姓名
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.userName ?? '员工 ${item.userId}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                if (item.remark != null && item.remark!.isNotEmpty)
                  Text(
                    item.remark!,
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // 积分
          Text(
            _formatScore(item.score),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: (item.score ?? 0) >= 0
                  ? const Color(0xFF30D158)
                  : const Color(0xFFFF3B30),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int? score) {
    if (score == null || score == 0) return '0';
    // 积分可能是分（fen），也可能是整数
    // 如果绝对值大于10000，认为是分
    if (score.abs() > 10000) {
      return (score / 100).toStringAsFixed(1);
    }
    return score.toString();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/task_log_api.dart';
import '../../theme/app_theme.dart';

/// 任务日志详情页
/// 对应 PWA /pages/path-d/task-management/task-log-info.tsx
class TaskLogDetailPage extends ConsumerStatefulWidget {
  final int taskLogId;

  const TaskLogDetailPage({super.key, required this.taskLogId});

  @override
  ConsumerState<TaskLogDetailPage> createState() => _TaskLogDetailPageState();
}

class _TaskLogDetailPageState extends ConsumerState<TaskLogDetailPage> {
  final TaskLogApi _api = TaskLogApi();

  TaskLogDetail? _detail;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _selfScore = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _api.detail(widget.taskLogId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
          if (detail != null) _selfScore = detail.selfScore ?? 5;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSelfEvaluation() async {
    setState(() => _isSubmitting = true);
    try {
      final success = await _api.selfEvaluationFinished(
        taskLogId: widget.taskLogId,
        score: _selfScore,
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _showToast('提交成功');
          _loadData();
        } else {
          _showToast('提交失败');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast('提交失败');
      }
    }
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
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
        middle: const Text('任务详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _detail == null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('加载失败', style: AppText.caption),
          CupertinoButton(onPressed: _loadData, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    final status = d.status;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态卡片
                _SectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (status?.color ?? CupertinoColors.systemGrey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(d.taskLogStatus),
                          color: status?.color ?? CupertinoColors.systemGrey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status?.label ?? d.taskLogStatus,
                              style: AppText.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (d.employeeName != null)
                              Text(d.employeeName!, style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 任务信息
                _SectionTitle('任务信息'),
                _SectionCard(
                  children: [
                    if (d.taskTitle != null) _InfoRow('任务标题', d.taskTitle!),
                    if (d.taskContent != null) _InfoRow('任务内容', d.taskContent!),
                    if (d.taskTemplateName != null) _InfoRow('任务模板', d.taskTemplateName!),
                    if (d.departmentName != null) _InfoRow('部门', d.departmentName!),
                    if (d.startAt != null) _InfoRow('开始时间', _formatTs(d.startAt!)),
                    if (d.endAt != null) _InfoRow('截止时间', _formatTs(d.endAt!)),
                    if (d.remarks != null) _InfoRow('备注', d.remarks!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 评分信息
                _SectionTitle('评分信息'),
                _SectionCard(
                  children: [
                    _InfoRow('自评', d.selfScore != null ? '${d.selfScore}分' : '未评分'),
                    _InfoRow('上级评分', d.taskScore != null ? '${d.taskScore}分' : '未评分'),
                    _InfoRow('最终评分', d.checkScore != null ? '${d.checkScore}分' : '未评分'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 自评内容
                if (d.selfEvaluationContent != null && d.selfEvaluationContent!.isNotEmpty) ...[
                  _SectionTitle('自评内容'),
                  _SectionCard(
                    child: Text(d.selfEvaluationContent!, style: AppText.body),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 验收备注
                if (d.lastCheckRemarks != null && d.lastCheckRemarks!.isNotEmpty) ...[
                  _SectionTitle('验收备注'),
                  _SectionCard(
                    children: [
                      if (d.lastCheckByName != null) _InfoRow('验收人', d.lastCheckByName!),
                      _InfoRow('备注', d.lastCheckRemarks!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),

        // 底部操作栏
        if (d.taskLogStatus == 'doing')
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('自评得分: ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: CupertinoSlidingSegmentedControl<int>(
                        groupValue: _selfScore,
                        children: const {
                          1: Text('1'),
                          2: Text('2'),
                          3: Text('3'),
                          4: Text('4'),
                          5: Text('5'),
                        },
                        onValueChanged: (v) => setState(() => _selfScore = v ?? 5),
                      ),
                    ),
                    Text(
                      ' $_selfScore 分',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _scoreColor(_selfScore),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _isSubmitting ? null : _submitSelfEvaluation,
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('提交自评'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'doing': return CupertinoIcons.clock;
      case 'unchecked': return CupertinoIcons.checkmark_circle;
      case 'finished': return CupertinoIcons.checkmark_seal_fill;
      case 'overdueFinished': return CupertinoIcons.exclamationmark_triangle;
      case 'unfinished': return CupertinoIcons.xmark_circle;
      default: return CupertinoIcons.circle;
    }
  }

  Color _scoreColor(int score) {
    switch (score) {
      case 1: return const Color(0xFFFF3B30);
      case 2: return const Color(0xFFFF9500);
      case 3: return const Color(0xFF5E5CE6);
      case 4: return const Color(0xFF30D158);
      case 5: return const Color(0xFF00C7BE);
      default: return CupertinoColors.systemGrey;
    }
  }

  String _formatTs(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: AppText.label.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget>? children;
  final Widget? child;

  const _SectionCard({this.children, this.child}) : assert(children != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child ?? Column(children: children!),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption.copyWith(color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }
}

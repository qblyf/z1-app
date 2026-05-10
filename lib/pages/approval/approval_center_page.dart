import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/approval.dart';
import '../../api/approval_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 审批中心 Provider
final approvalApiProvider = Provider<ApprovalApi>((ref) => ApprovalApi());

/// 待我审批列表
final pendingApprovalsProvider = FutureProvider<List<Approval>>((ref) async {
  final api = ref.read(approvalApiProvider);
  return api.getPending();
});

/// 我发起的列表
final myApprovalsProvider = FutureProvider<List<Approval>>((ref) async {
  final api = ref.read(approvalApiProvider);
  return api.getMyApplications();
});

/// 审批中心页面
class ApprovalCenterPage extends ConsumerStatefulWidget {
  const ApprovalCenterPage({super.key});

  @override
  ConsumerState<ApprovalCenterPage> createState() =>
      _ApprovalCenterPageState();
}

class _ApprovalCenterPageState extends ConsumerState<ApprovalCenterPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('审批中心'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('提示'),
                content: const Text('新建审批功能开发中...'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedIndex,
                  children: const {
                    0: Text('待我审批'),
                    1: Text('我发起的'),
                  },
                  onValueChanged: (index) {
                    if (index == null) return;
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),
            Expanded(
              child: [
                const _PendingApprovalsView(),
                const _MyApprovalsView(),
              ][_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingApprovalsView extends ConsumerWidget {
  const _PendingApprovalsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    return approvalsAsync.when(
      data: (approvals) {
        if (approvals.isEmpty) {
          return const EmptyWidget(
            message: '暂无待审批',
            icon: CupertinoIcons.checkmark_circle,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(pendingApprovalsProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ApprovalCard(
                    approval: approvals[index],
                    onTap: () => context.push('/approval/${approvals[index].id}'),
                  ),
                  childCount: approvals.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(pendingApprovalsProvider),
      ),
    );
  }
}

class _MyApprovalsView extends ConsumerWidget {
  const _MyApprovalsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(myApprovalsProvider);

    return approvalsAsync.when(
      data: (approvals) {
        if (approvals.isEmpty) {
          return const EmptyWidget(
            message: '暂无审批记录',
            icon: CupertinoIcons.doc_text,
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => ref.invalidate(myApprovalsProvider),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ApprovalCard(
                    approval: approvals[index],
                    onTap: () => context.push('/approval/${approvals[index].id}'),
                  ),
                  childCount: approvals.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: '加载中...'),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(myApprovalsProvider),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final Approval approval;
  final VoidCallback onTap;

  const _ApprovalCard({required this.approval, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeIcon(type: approval.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          approval.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          approval.applicantName ?? '未知',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: approval.status.label,
                    color: _getStatusColor(approval.status),
                  ),
                ],
              ),
              if (approval.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  approval.description!,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 4),
                  DateTimeText(unix: approval.createdAt, format: 'MM-dd HH:mm'),
                  if (approval.departmentName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      CupertinoIcons.building_2_fill,
                      size: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      approval.departmentName!,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return CupertinoColors.activeOrange;
      case ApprovalStatus.approved:
        return CupertinoColors.activeGreen;
      case ApprovalStatus.rejected:
        return CupertinoColors.destructiveRed;
      case ApprovalStatus.cancelled:
        return CupertinoColors.systemGrey;
    }
  }
}

class _TypeIcon extends StatelessWidget {
  final ApprovalType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case ApprovalType.leave:
        icon = CupertinoIcons.sun_max;
        color = CupertinoColors.activeBlue;
        break;
      case ApprovalType.expense:
        icon = CupertinoIcons.doc_text;
        color = CupertinoColors.destructiveRed;
        break;
      case ApprovalType.purchase:
        icon = CupertinoIcons.cart;
        color = CupertinoColors.activeOrange;
        break;
      case ApprovalType.overtime:
        icon = CupertinoIcons.clock;
        color = CupertinoColors.systemPurple;
        break;
      case ApprovalType.other:
        icon = CupertinoIcons.ellipsis;
        color = CupertinoColors.systemGrey;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}

/// 审批详情页面
class ApprovalDetailPage extends ConsumerStatefulWidget {
  final String id;

  const ApprovalDetailPage({super.key, required this.id});

  @override
  ConsumerState<ApprovalDetailPage> createState() =>
      _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends ConsumerState<ApprovalDetailPage> {
  Approval? _approval;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final api = ref.read(approvalApiProvider);
      final approval = await api.getDetail(widget.id);
      setState(() {
        _approval = approval;
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
          middle: Text('审批详情'),
        ),
        child: const LoadingWidget(message: '加载中...'),
      );
    }

    if (_approval == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('审批详情'),
        ),
        child: const AppErrorWidget(message: '未找到审批记录'),
      );
    }

    final approval = _approval!;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('审批详情'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // 状态卡片
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _getStatusColor(approval.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(approval.status),
                    color: _getStatusColor(approval.status),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval.status.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(approval.status),
                        ),
                      ),
                      if (approval.processedAt != null)
                        DateTimeText(unix: approval.processedAt!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 审批信息
            _buildSection('审批信息', [
              _buildDetailRow('标题', approval.title),
              _buildDetailRow('类型', approval.type.label),
              _buildDetailRow('申请人', approval.applicantName ?? '-'),
              _buildDetailRow('部门', approval.departmentName ?? '-'),
              _buildDetailRow('申请时间', DateTimeText(unix: approval.createdAt)),
            ]),

            // 审批流程
            if (approval.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                '审批流程',
                style: AppText.subtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: approval.steps.map((step) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  _getStepColor(step.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getStepIcon(step.status),
                              size: 16,
                              color: _getStepColor(step.status),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.approverName ?? '未知',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                if (step.operatedAt != null)
                                  DateTimeText(
                                    unix: step.operatedAt!,
                                    format: 'MM-dd HH:mm',
                                  ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: step.statusLabel,
                            color: _getStepColor(step.status),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // 操作按钮
            if (approval.status == ApprovalStatus.pending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.destructiveRed,
                      onPressed: () => _handleProcess(context, false),
                      child: const Text('拒绝'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () => _handleProcess(context, true),
                      child: const Text('通过'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.subtitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: CupertinoColors.secondaryLabel)),
          value is Widget
              ? value
              : Text(value?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _handleProcess(BuildContext context, bool approved) async {
    final api = ref.read(approvalApiProvider);

    try {
      final success = await api.process(
        id: _approval!.id,
        approved: approved,
      );

      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(success ? '成功' : '失败'),
            content: Text(success ? '操作成功' : '操作失败'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );

        if (success) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('失败'),
            content: Text('操作失败: $e'),
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

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return CupertinoColors.activeOrange;
      case ApprovalStatus.approved:
        return CupertinoColors.activeGreen;
      case ApprovalStatus.rejected:
        return CupertinoColors.destructiveRed;
      case ApprovalStatus.cancelled:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStatusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return CupertinoIcons.clock;
      case ApprovalStatus.approved:
        return CupertinoIcons.checkmark_circle_fill;
      case ApprovalStatus.rejected:
        return CupertinoIcons.xmark_circle;
      case ApprovalStatus.cancelled:
        return CupertinoIcons.arrow_uturn_left;
    }
  }

  Color _getStepColor(int status) {
    switch (status) {
      case 1:
        return CupertinoColors.activeOrange;
      case 2:
        return CupertinoColors.activeGreen;
      case 3:
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStepIcon(int status) {
    switch (status) {
      case 1:
        return CupertinoIcons.clock;
      case 2:
        return CupertinoIcons.checkmark;
      case 3:
        return CupertinoIcons.xmark;
      default:
        return CupertinoIcons.question;
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_score_providers.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 申报管理页面（管理员查看/审批申报）
class ManagementPage extends ConsumerStatefulWidget {
  const ManagementPage({super.key});

  @override
  ConsumerState<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends ConsumerState<ManagementPage> {
  int _statusFilter = 0; // 0=全部 1=待确认 2=已确认 3=已拒绝
  int _page = 0;
  List<ScoreApply> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(employeeScoreApiProvider);
      final status = _statusFilter > 0 ? _statusFilter : null;
      final list = await api.getApplyList(status: status, limit: 20, offset: _page * 20);
      setState(() {
        if (_page == 0) {
          _items = list;
        } else {
          _items.addAll(list);
        }
        _hasMore = list.length >= 20;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    _page = 0;
    await _loadData();
  }

  void _confirmApply(ScoreApply apply) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('确认申报'),
        content: Text('确认 "${apply.title ?? '该申报'}" 通过？'),
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
              final api = ref.read(employeeScoreApiProvider);
              final ok = await api.confirmApply(apply.id);
              if (ok) {
                _refresh();
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
            Text('请输入拒绝原因（可选）'),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: reasonController,
              placeholder: '拒绝原因',
              maxLines: 2,
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
              final api = ref.read(employeeScoreApiProvider);
              final ok = await api.rejectApply(
                apply.id,
                reason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              if (ok) _refresh();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('申报管理'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 状态筛选
            _StatusFilterBar(selected: _statusFilter, onChanged: (v) {
              setState(() { _statusFilter = v; _page = 0; });
              _loadData();
            }),

            // 列表
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.doc_text, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('暂无申报记录', style: AppText.caption),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
                          _page++;
                          _loadData();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        slivers: [
                          CupertinoSliverRefreshControl(onRefresh: _refresh),
                          SliverPadding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _ApplyCard(
                                  apply: _items[i],
                                  onConfirm: () => _confirmApply(_items[i]),
                                  onReject: () => _rejectApply(_items[i]),
                                ),
                                childCount: _items.length,
                              ),
                            ),
                          ),
                          if (_isLoading && _page > 0)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(child: CupertinoActivityIndicator()),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态筛选栏
class _StatusFilterBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _StatusFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (0, '全部'),
      (1, '待确认'),
      (2, '已确认'),
      (3, '已拒绝'),
    ];
    return Container(
      height: 44,
      color: CupertinoColors.white,
      child: Row(
        children: tabs.map((t) {
          final isActive = selected == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.$1),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey5,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? const Color(0xFF0A84FF) : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 申报卡片
class _ApplyCard extends StatelessWidget {
  final ScoreApply apply;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const _ApplyCard({required this.apply, required this.onConfirm, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/employee-score/info/${apply.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 状态
          Row(
            children: [
              Expanded(
                child: Text(
                  apply.title ?? '积分申报',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: apply.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  apply.statusLabel,
                  style: TextStyle(fontSize: 12, color: apply.statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 分类
          Row(
            children: [
              Icon(CupertinoIcons.star, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(apply.className ?? '积分', style: AppText.caption),
              const SizedBox(width: 12),
              Icon(CupertinoIcons.person, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(apply.creatorName ?? '未知', style: AppText.caption),
            ],
          ),

          // 描述
          if (apply.description != null && apply.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(apply.description!, style: AppText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],

          // 申报明细
          if (apply.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: apply.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.userName ?? '成员'} +${item.score ?? 0}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFFF9500), fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],

          // 时间
          const SizedBox(height: 8),
          Text(_formatTime(apply.happenedAt), style: AppText.caption),

          // 操作按钮（仅待确认状态显示）
          if (apply.status == 1) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: onReject,
                    child: const Text('拒绝', style: TextStyle(color: Color(0xFFFF3B30))),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFF30D158).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: onConfirm,
                    child: const Text('确认', style: TextStyle(color: Color(0xFF30D158))),
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

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

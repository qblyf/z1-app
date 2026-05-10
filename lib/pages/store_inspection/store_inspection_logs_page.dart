import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_inspection_api.dart';
import '../../models/store_inspection.dart';
import '../../theme/app_theme.dart';

/// 巡店/自检 - 记录列表页
/// 对应 PWA /pages/path-d/store-inspection/logs.tsx
/// 显示所有巡店记录，支持按状态筛选
class StoreInspectionLogsPage extends ConsumerStatefulWidget {
  const StoreInspectionLogsPage({super.key});

  @override
  ConsumerState<StoreInspectionLogsPage> createState() => _StoreInspectionLogsPageState();
}

class _StoreInspectionLogsPageState extends ConsumerState<StoreInspectionLogsPage> {
  final StoreInspectionApi _api = StoreInspectionApi();

  List<StoreInspectionLogDetail> _list = [];
  bool _isLoading = true;
  int _offset = 0;
  int _total = 0;
  String? _errorMsg;

  // 筛选状态
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    if (refresh) { _offset = 0; }

    setState(() { if (refresh) _isLoading = true; });

    try {
      final params = <String, dynamic>{
        'limit': 300,
        'offset': _offset,
      };
      if (_statusFilter != null) params['status'] = _statusFilter!;

      final countFuture = _api.logCount(
        status: _statusFilter != null ? [_statusFilter!] : null,
      );
      final listFuture = _api.logList(
        status: _statusFilter != null ? [_statusFilter!] : null,
        limit: 300,
        offset: _offset,
      );

      final results = await Future.wait([countFuture, listFuture]);
      final count = results[0] as int;
      final list = results[1] as List<StoreInspectionLogDetail>;

      if (mounted) {
        setState(() {
          if (refresh) {
            _list = list;
          } else {
            _list.addAll(list);
          }
          // loaded all
          _offset += list.length;
          _total = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMsg = '加载失败：$e'; });
      }
    }
  }

  String _fmt(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('巡店记录'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
          onPressed: _showFilterSheet,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 统计栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Text('共 $_total 条', style: AppText.caption),
                  const Spacer(),
                  Text('本页 ${_list.length} 条', style: AppText.caption),
                ],
              ),
            ),
            // 状态筛选
            _buildStatusFilter(),
            // 列表
            Expanded(
              child: _isLoading && _list.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : _errorMsg != null && _list.isEmpty
                      ? Center(child: Text(_errorMsg!, style: AppText.body))
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 44,
      color: CupertinoColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            _StatusChip(
              label: '全部',
              isActive: _statusFilter == null,
              color: const Color(0xFF0A84FF),
              onTap: () => _setFilter(null),
            ),
            const SizedBox(width: 8),
            ...StoreInspectionLogStatus.values.map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatusChip(
                label: s.label,
                isActive: _statusFilter == s.value,
                color: s.color,
                onTap: () => _setFilter(s.value),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _setFilter(String? status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    _loadData(refresh: true);
  }

  Widget _buildList() {
    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.map, size: 64, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 16),
            Text('暂无巡店记录', style: AppText.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _list.length,
        itemBuilder: (_, i) => _LogCard(
          log: _list[i],
          formatTime: _fmt,
          onTap: () => context.push('/store-inspection/info/${_list[i].id}'),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _FilterSheet(
        currentStatus: _statusFilter,
        onApply: (status) {
          setState(() => _statusFilter = status);
          _loadData(refresh: true);
        },
      ),
    );
  }
}

class RefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const RefreshIndicator({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.isActive, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? CupertinoColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final StoreInspectionLogDetail log;
  final String Function(int) formatTime;
  final VoidCallback onTap;
  const _LogCard({required this.log, required this.formatTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = log.logStatus;
    return GestureDetector(
      onTap: onTap,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.storeInspectionType == 'selfInspection' ? '自检' : '巡店',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5856D6)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.inspectionName ?? '项目${log.inspectionID}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status.label, style: TextStyle(fontSize: 12, color: status.color, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.building_2_fill, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(log.departmentName ?? '部门${log.departmentID}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.person, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(log.createdByName ?? '用户${log.createdBy}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 13, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(formatTime(log.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                if (log.score != null) ...[
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.star_fill, size: 13, color: Color(0xFFFF9500)),
                  const SizedBox(width: 4),
                  Text('${log.score}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFF9500), fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? currentStatus;
  final void Function(String?) onApply;
  const _FilterSheet({this.currentStatus, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStatus;
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
                child: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFFCCCCCC)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('状态', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _FilterChip(label: '全部', isActive: _selected == null, onTap: () => setState(() => _selected = null)),
              ...StoreInspectionLogStatus.values.map((s) =>
                _FilterChip(label: s.label, isActive: _selected == s.value, color: s.color,
                    onTap: () => setState(() => _selected = s.value)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_selected);
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, this.color = const Color(0xFF0A84FF), required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : CupertinoColors.systemGrey6,
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

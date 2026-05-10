import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/draft_api.dart';
import '../../theme/app_theme.dart';

/// 标品调拨单草稿页
/// 对应 PWA /pages/path-d/transfer-order/my-standard-transfer-draft.tsx
class StandardTransferDraftPage extends ConsumerStatefulWidget {
  const StandardTransferDraftPage({super.key});

  @override
  ConsumerState<StandardTransferDraftPage> createState() => _StandardTransferDraftPageState();
}

class _StandardTransferDraftPageState extends ConsumerState<StandardTransferDraftPage> {
  final DraftApi _api = DraftApi();

  List<GeneralDraft> _list = [];
  bool _isLoading = false;
  Set<int> _selectedIds = {};

  // 筛选
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  int? _outWarehouseId;
  int? _inWarehouseId;
  List<int>? _createdBys;
  GeneralDraftType? _draftType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final types = _draftType != null
          ? [_draftType!.value]
          : [1, 2, 3, 4, 5]; // 所有调拨类型

      final data = await _api.list(
        createdBys: _createdBys?.map((e) => e.toString()).toList(),
        types: types,
        inWarehouseIDs: _inWarehouseId != null ? [_inWarehouseId!] : null,
        outWarehouseIDs: _outWarehouseId != null ? [_outWarehouseId!] : null,
        minCreatedAt: _startDate.millisecondsSinceEpoch ~/ 1000,
        maxCreatedAt: _endDate.millisecondsSinceEpoch ~/ 1000,
        limit: 300,
        offset: 0,
      );

      if (mounted) {
        data.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        setState(() { _list = data; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMerge() async {
    if (_selectedIds.length < 2) {
      _showToast(_selectedIds.length == 1 ? '仅选中一条草稿不需要合并' : '请选择至少两条草稿');
      return;
    }
    final selected = _list.where((d) => _selectedIds.contains(d.id)).toList();
    if (selected.isEmpty) return;

    // 草稿类型必须一致
    final types = selected.map((d) => d.type).toSet();
    if (types.length > 1) {
      _showToast('当前选中草稿来源不一，不能合并');
      return;
    }

    // 出入库仓库必须一致
    final sampleIn = selected.first.inWarehouseId;
    final sampleOut = selected.first.outWarehouseId;
    for (final d in selected.skip(1)) {
      if (d.inWarehouseId != sampleIn || d.outWarehouseId != sampleOut) {
        _showToast('当前选中草稿出入库仓库不一致，请修改后重试');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final newId = await _api.mergeTransfer(_selectedIds.toList());
      if (newId > 0 && mounted) {
        _selectedIds = {};
        setState(() => _isLoading = false);
        context.push('/transfer-order/create?draftID=$newId');
      } else {
        setState(() => _isLoading = false);
        _showToast('合并失败');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('合并失败：$e');
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('标品调拨单草稿'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.slider_horizontal_3, size: 22),
          onPressed: () => _showFilterSheet(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF0A84FF).withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Text('已选 ${_selectedIds.length} 条', style: const TextStyle(fontSize: 14, color: Color(0xFF0A84FF))),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _handleMerge,
                      child: const Text('合并', style: TextStyle(fontSize: 14, color: Color(0xFF0A84FF))),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('取消', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                      onPressed: () => setState(() => _selectedIds = {}),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading && _list.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : _list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.doc_text, size: 48, color: Color(0xFFDDDDE0)),
                              const SizedBox(height: 16),
                              Text('暂无草稿', style: AppText.body),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            CupertinoSliverRefreshControl(onRefresh: () async { await _loadData(); }),
                            SliverPadding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => _DraftCard(
                                    draft: _list[i],
                                    isSelected: _selectedIds.contains(_list[i].id),
                                    onToggle: (id, selected) {
                                      setState(() {
                                        if (selected) { _selectedIds = {..._selectedIds, id}; }
                                        else { _selectedIds = {..._selectedIds}..remove(id); }
                                      });
                                    },
                                    onTap: (id) => context.push('/transfer-order/create?draftID=$id'),
                                  ),
                                  childCount: _list.length,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    DateTime start = _startDate;
    DateTime end = _endDate;
    GeneralDraftType? draftType = _draftType;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('重置', style: TextStyle(color: Color(0xFF666666))),
                      onPressed: () => setSheetState(() {
                        start = DateTime.now().subtract(const Duration(days: 7));
                        end = DateTime.now();
                        draftType = null;
                      }),
                    ),
                    const Spacer(),
                    const Text('筛选', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('确定', style: TextStyle(color: Color(0xFF0A84FF))),
                      onPressed: () {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                          _draftType = draftType;
                        });
                        _loadData();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('创建日期', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _DateBtn(date: start, onTap: () async {
                            await showCupertinoModalPopup(
                              context: ctx,
                              builder: (_) => Container(
                                height: 260, color: CupertinoColors.white,
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: start,
                                  onDateTimeChanged: (d) => setSheetState(() => start = d),
                                ),
                              ),
                            );
                          })),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至')),
                          Expanded(child: _DateBtn(date: end, onTap: () async {
                            await showCupertinoModalPopup(
                              context: ctx,
                              builder: (_) => Container(
                                height: 260, color: CupertinoColors.white,
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: end,
                                  onDateTimeChanged: (d) => setSheetState(() => end = d),
                                ),
                              ),
                            );
                          })),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('草稿来源', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _FilterChip(label: '全部', selected: draftType == null, onTap: () => setSheetState(() => draftType = null)),
                          ...GeneralDraftType.values.where((t) => t.value >= 1 && t.value <= 5).map((t) =>
                            _FilterChip(label: t.label, selected: draftType == t, onTap: () => setSheetState(() => draftType = t)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final GeneralDraft draft;
  final bool isSelected;
  final void Function(int id, bool selected) onToggle;
  final void Function(int id) onTap;

  const _DraftCard({required this.draft, required this.isSelected, required this.onToggle, required this.onTap});

  String _draftTypeLabel() {
    final t = GeneralDraftType.fromValue(draft.type);
    return t?.label ?? '未知';
  }

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(draft.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
          border: isSelected ? Border.all(color: const Color(0xFF0A84FF), width: 1.5) : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onToggle(draft.id, !isSelected),
              child: Container(
                width: 48, height: 80,
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF0A84FF), size: 22)
                    : const Icon(CupertinoIcons.circle, color: Color(0xFFCCCCCC), size: 22),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('草稿 ${draft.id}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_draftTypeLabel(),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5856D6))),
                        ),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF999999)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('更新时间 ${_formatTime(draft.updatedAt)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ),
                      ],
                    ),
                    if (draft.outWarehouseId != null || draft.inWarehouseId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('出库: ${draft.outWarehouseId ?? '-'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                          const SizedBox(width: 12),
                          Text('入库: ${draft.inWarehouseId ?? '-'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ],
                      ),
                    ],
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

class _DateBtn extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateBtn({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A84FF) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? CupertinoColors.white : const Color(0xFF666666))),
      ),
    );
  }
}

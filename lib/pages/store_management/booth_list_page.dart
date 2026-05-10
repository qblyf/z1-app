import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/display_case_api.dart';
import '../../api/display_standard_api.dart';
import '../../models/display_case.dart';
import '../../models/display_standard.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// Booth（展位）列表页
class BoothListPage extends ConsumerStatefulWidget {
  const BoothListPage({super.key});

  @override
  ConsumerState<BoothListPage> createState() => _BoothListPageState();
}

class _BoothListPageState extends ConsumerState<BoothListPage> {
  final DisplayCaseApi _api = DisplayCaseApi();
  final DisplayStandardApi _standardApi = DisplayStandardApi();

  List<DisplayCase> _allCases = [];
  Map<int, DisplayStandard> _standardCache = {};
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _offset = 0;
    });
    try {
      final cases = await _api.list(
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _allCases = cases;
          _hasMore = cases.length >= _pageSize;
          _isLoading = false;
        });
        // 加载标准数据
        _loadStandards(cases);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      _offset += _pageSize;
      final cases = await _api.list(
        limit: _pageSize,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _allCases = [..._allCases, ...cases];
          _hasMore = cases.length >= _pageSize;
          _isLoading = false;
        });
        _loadStandards(cases);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStandards(List<DisplayCase> cases) async {
    final standardIds = cases
        .where((c) => !_standardCache.containsKey(c.standardID))
        .map((c) => c.standardID)
        .toSet()
        .toList();
    if (standardIds.isEmpty) return;
    try {
      final standards = await _standardApi.list(ids: standardIds);
      if (mounted) {
        setState(() {
          for (final s in standards) {
            _standardCache[s.standardID] = s;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteCase(DisplayCase booth) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除展位'),
        content: Text('确认删除"${booth.name}"吗？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _api.delete([booth.caseID]);
      if (success && mounted) {
        setState(() {
          _allCases = _allCases.where((c) => c.caseID != booth.caseID).toList();
        });
      } else if (mounted) {
        _showError('删除失败');
      }
    } catch (_) {
      if (mounted) _showError('删除失败');
    }
  }

  void _showError(String message) {
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

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
        middle: const Text('展位列表'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => context.push('/store-management/booth/add'),
        ),
      ),
      child: SafeArea(
        child: _isLoading && _allCases.isEmpty
            ? const Center(child: CupertinoActivityIndicator())
            : _allCases.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.cube_box,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('暂无展位', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: () => context.push('/store-management/booth/add'),
            child: const Text('新增展位'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _allCases.length) {
                  if (_hasMore) {
                    _loadMore();
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return null;
                }
                final booth = _allCases[index];
                final standard = _standardCache[booth.standardID];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BoothCard(
                    booth: booth,
                    standard: standard,
                    onTap: () => context.push('/store-management/booth/edit/${booth.caseID}'),
                    onDelete: () => _deleteCase(booth),
                    formatTime: _formatTime,
                  ),
                );
              },
              childCount: _allCases.length + (_hasMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoothCard extends StatelessWidget {
  final DisplayCase booth;
  final DisplayStandard? standard;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(int?) formatTime;

  const _BoothCard({
    required this.booth,
    this.standard,
    required this.onTap,
    required this.onDelete,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      booth.name,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    child: const Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: Color(0xFFFF3B30),
                    ),
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '›',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),
            // 标准展示图片
            if (standard?.hasImages == true)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('标准展陈', style: AppText.caption),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: standard!.imgs!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) => _buildImage(
                          standard!.imgs![idx],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 当前陈列图片
            if (booth.hasImages)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前陈列', style: AppText.caption),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: booth.imgs!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) => _buildImage(
                          booth.imgs![idx],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (standard?.hasImages == true || booth.hasImages)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: AppColors.divider,
              ),
            // 备注 & 更新时间
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (booth.remarks != null && booth.remarks!.isNotEmpty) ...[
                    Text(
                      '备注：${booth.remarks}',
                      style: AppText.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '更新时间：${formatTime(booth.updatedAt)}',
                    style: AppText.caption.copyWith(
                      color: AppColors.textTertiary,
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

  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: const Color(0xFFF2F2F7),
          child: const Icon(
            CupertinoIcons.photo,
            size: 20,
            color: Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

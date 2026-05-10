import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/recycle_order_api.dart';
import '../../models/recycle_order.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 回收订单列表页
class RecycleOrderListPage extends ConsumerStatefulWidget {
  const RecycleOrderListPage({super.key});

  @override
  ConsumerState<RecycleOrderListPage> createState() =>
      _RecycleOrderListPageState();
}

class _RecycleOrderListPageState
    extends ConsumerState<RecycleOrderListPage> {
  final RecycleOrderApi _api = RecycleOrderApi();

  List<RecycleOrder> _list = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  /// 当前选中的状态（null=全部）
  RecycleOrderState? _selectedState;

  /// 搜索关键字
  String _searchKeyword = '';
  final _searchController = TextEditingController();

  /// 统计数据
  int _totalCount = 0;
  String _totalAmount = '0.00';
  String _totalCostAmount = '0.00';

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 状态列表（排除已撤销）
  static const List<RecycleOrderState?> _stateFilters = [
    null, // 全部
    RecycleOrderState.unpaid,
    RecycleOrderState.paid,
    RecycleOrderState.transfer,
    RecycleOrderState.notRechecked,
    RecycleOrderState.rechecked,
    RecycleOrderState.vendor,
    RecycleOrderState.vendorSold,
  ];

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      List<String>? states;
      if (_selectedState != null) {
        states = [_selectedState!.value];
      } else {
        // 默认排除已撤销
        states = _stateFilters
            .where((s) => s != null)
            .map((s) => s!.value)
            .where((v) => v != RecycleOrderState.undone.value)
            .toList();
      }

      // 搜索条件
      final number = _searchKeyword.isNotEmpty ? _searchKeyword : null;
      final serial = _searchKeyword.isNotEmpty ? _searchKeyword : null;

      // 并行请求列表和统计
      final results = await Future.wait([
        _api.list(
          number: number,
          serial: serial,
          states: states,
          limit: 20,
          offset: _page * 20,
        ),
        _api.count(
          number: number,
          serial: serial,
          states: states,
        ),
      ]);

      final data = results[0] as List<RecycleOrder>;
      final stats = results[1] as List<RecycleOrderStatistics>;

      setState(() {
        if (refresh) {
          _list = data;
        } else {
          _list.addAll(data);
        }
        _hasMore = data.length >= 20;
        _isLoading = false;
        _page++;

        // 统计数据
        if (stats.isNotEmpty) {
          _totalCount = stats[0].count;
          _totalAmount = stats[0].totalActualAmountYuan;
          _totalCostAmount = stats[0].totalCostAmountYuan;
        }
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadData(refresh: true);
  }

  void _onStateChanged(RecycleOrderState? state) {
    setState(() {
      _selectedState = state;
    });
    _loadData(refresh: true);
  }

  void _onSearch() {
    setState(() {
      _searchKeyword = _searchController.text.trim();
    });
    _loadData(refresh: true);
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
        middle: const Text('回收订单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            context.push('/store-retail/recycle-order/create');
          },
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: CupertinoColors.white,
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '搜索单号/串号',
                onSubmitted: (_) => _onSearch(),
              ),
            ),
            // 状态筛选标签
            Container(
              height: 40,
              color: CupertinoColors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                itemCount: _stateFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final state = _stateFilters[index];
                  final isSelected = _selectedState == state;
                  return GestureDetector(
                    onTap: () => _onStateChanged(state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0A84FF)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        state == null ? '全部' : state.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? CupertinoColors.white
                              : const Color(0xFF636366),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 统计栏
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              color: CupertinoColors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: '订单数',
                    value: '$_totalCount',
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.divider,
                  ),
                  _StatItem(
                    label: '回收总额',
                    value: '¥$_totalAmount',
                    valueColor: const Color(0xFFFF3B30),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.divider,
                  ),
                  _StatItem(
                    label: '估价总额',
                    value: '¥$_totalCostAmount',
                    valueColor: const Color(0xFF34C759),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // 列表
            Expanded(
              child: _isLoading && _list.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : _list.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ],
        ),
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
          Text('暂无回收订单', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100 &&
            !_isLoading &&
            _hasMore) {
          _loadData();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _refresh,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _list.length) {
                    return _hasMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _RecycleOrderCard(
                      order: _list[index],
                      onTap: () {
                        context.push(
                          '/store-retail/recycle-order/detail/${_list[index].number}',
                        );
                      },
                    ),
                  );
                },
                childCount: _list.length + (_hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? CupertinoColors.label,
          ),
        ),
      ],
    );
  }
}

/// 回收订单卡片
class _RecycleOrderCard extends StatelessWidget {
  final RecycleOrder order;
  final VoidCallback onTap;

  const _RecycleOrderCard({
    required this.order,
    required this.onTap,
  });

  Color get _stateColor {
    switch (order.stateEnum) {
      case RecycleOrderState.unpaid:
        return const Color(0xFFFF9500);
      case RecycleOrderState.paid:
        return const Color(0xFF34C759);
      case RecycleOrderState.transfer:
        return const Color(0xFF5856D6);
      case RecycleOrderState.notRechecked:
        return const Color(0xFFFF3B30);
      case RecycleOrderState.rechecked:
        return const Color(0xFF34C759);
      case RecycleOrderState.nonStandardGoods:
        return const Color(0xFFFF2D55);
      case RecycleOrderState.vendor:
        return const Color(0xFF007AFF);
      case RecycleOrderState.vendorSold:
        return const Color(0xFF34C759);
      case RecycleOrderState.undone:
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(
      order.createdAt * 1000,
    );
    final timeStr =
        '${createdTime.year}-${createdTime.month.toString().padLeft(2, '0')}-${createdTime.day.toString().padLeft(2, '0')} ${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
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
                      order.number,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _stateColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.stateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _stateColor,
                      ),
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
            // 商品信息
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.ruleTitle,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (order.specification.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.specification.join(' / '),
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),
            // 底部信息
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              child: Row(
                children: [
                  // 串号
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('串号', style: AppText.caption),
                        const SizedBox(height: 2),
                        Text(
                          order.serial.isNotEmpty ? order.serial : '-',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF636366),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 回收价
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('回收价', style: AppText.caption),
                      const SizedBox(height: 2),
                      Text(
                        '¥${order.actualAmountYuan}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 时间
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 12,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '查看详情 ›',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0A84FF),
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
}

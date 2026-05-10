import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/order_api.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 销售订单列表页（商城订单）
/// 路由：/mall-order/sales-order-list
/// 支持按状态筛选：待支付/已付款/已完成
class SalesOrderListPage extends ConsumerStatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  ConsumerState<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends ConsumerState<SalesOrderListPage> {
  /// 状态筛选：0=待支付, 1=已付款, 2=已完成
  int _statusTab = 0;

  /// 搜索条件
  String? _orderNumber;
  String? _phoneNumber;
  int? _sellerIdent;
  int? _labelId;

  /// 日期范围（默认近3个月）
  late DateTime _minDate;
  late DateTime _maxDate;

  /// 控制筛选面板展开
  bool _showFilters = false;

  /// 输入框控制器
  final _orderNumberController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _minDate = DateTime.now().subtract(const Duration(days: 90));
    _maxDate = DateTime.now();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 将状态tab转为API状态值
  List<int> get _statusValues {
    switch (_statusTab) {
      case 0:
        return [0]; // 待支付
      case 1:
        return [1, 5]; // 已付款（含部分支付）
      case 2:
        return [3, 6]; // 已完成/已评价
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: const Text('销售订单', style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            _showFilters ? CupertinoIcons.line_horizontal_3_decrease : CupertinoIcons.slider_horizontal_3,
            size: 24,
          ),
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 状态 Tab
            _buildStatusTabs(),

            // 筛选面板
            if (_showFilters) _buildFilterPanel(),

            // 订单列表
            Expanded(
              child: _SalesOrderListContent(
                statusValues: _statusValues,
                minDate: _minDate,
                maxDate: _maxDate,
                orderNumber: _orderNumber,
                phoneNumber: _phoneNumber,
                sellerIdent: _sellerIdent,
                labelId: _labelId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      height: 44,
      color: CupertinoColors.white,
      child: Row(
        children: [
          _buildTab(0, '待支付'),
          _buildTab(1, '已付款'),
          _buildTab(2, '已完成'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _statusTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statusTab = index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0x00000000),
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: CupertinoColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期范围
          Row(
            children: [
              const Text('创建日期', style: AppText.body),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDate(_minDate)} - ${_formatDate(_maxDate)}',
                          style: AppText.body,
                        ),
                        const Icon(CupertinoIcons.calendar, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 订单编号
          Row(
            children: [
              const Text('订单编号', style: AppText.body),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: _orderNumberController,
                  placeholder: '请输入',
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 手机号
          Row(
            children: [
              const Text('用户手机', style: AppText.body),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: _phoneController,
                  placeholder: '请输入',
                  keyboardType: TextInputType.phone,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  onPressed: _resetFilters,
                  child: Text(
                    '重置',
                    style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: _applyFilters,
                  child: const Text('查询'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('确认'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _minDate,
                onDateTimeChanged: (date) {
                  setState(() => _minDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    _orderNumberController.clear();
    _phoneController.clear();
    setState(() {
      _orderNumber = null;
      _phoneNumber = null;
      _sellerIdent = null;
      _labelId = null;
      _minDate = DateTime.now().subtract(const Duration(days: 90));
      _maxDate = DateTime.now();
    });
  }

  void _applyFilters() {
    setState(() {
      _orderNumber = _orderNumberController.text.trim().isNotEmpty ? _orderNumberController.text.trim() : null;
      _phoneNumber = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 销售订单列表内容
class _SalesOrderListContent extends ConsumerStatefulWidget {
  final List<int> statusValues;
  final DateTime minDate;
  final DateTime maxDate;
  final String? orderNumber;
  final String? phoneNumber;
  final int? sellerIdent;
  final int? labelId;

  const _SalesOrderListContent({
    required this.statusValues,
    required this.minDate,
    required this.maxDate,
    this.orderNumber,
    this.phoneNumber,
    this.sellerIdent,
    this.labelId,
  });

  @override
  ConsumerState<_SalesOrderListContent> createState() => _SalesOrderListContentState();
}

class _SalesOrderListContentState extends ConsumerState<_SalesOrderListContent> {
  final OrderApi _api = OrderApi();
  List<MallOrder> _orders = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void didUpdateWidget(_SalesOrderListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusValues != widget.statusValues ||
        oldWidget.orderNumber != widget.orderNumber ||
        oldWidget.phoneNumber != widget.phoneNumber) {
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    _orders = [];
    _hasMore = true;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!_hasMore && _orders.isNotEmpty) return;

    setState(() {
      if (_orders.isEmpty) {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final minCreatedAt = widget.minDate.millisecondsSinceEpoch ~/ 1000;
      final maxCreatedAt = widget.maxDate.millisecondsSinceEpoch ~/ 1000 + 86400; // 加1天

      // 如果有多个状态，合并结果
      List<MallOrder> allOrders = [];
      for (final status in widget.statusValues) {
        final orders = await _api.getMallOrderList(
          status: status,
          minCreatedAt: minCreatedAt,
          maxCreatedAt: maxCreatedAt,
          limit: _limit,
          offset: 0,
        );
        allOrders.addAll(orders);
      }

      // 去重
      final seen = <String>{};
      allOrders = allOrders.where((o) => seen.add(o.number)).toList();

      // 过滤
      if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) {
        allOrders = allOrders.where((o) => o.number.contains(widget.orderNumber!)).toList();
      }
      if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
        allOrders = allOrders.where((o) => o.customerPhone?.contains(widget.phoneNumber!) ?? false).toList();
      }

      // 按创建时间排序
      allOrders.sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));

      if (mounted) {
        setState(() {
          _orders = allOrders;
          _isLoading = false;
          _hasMore = allOrders.length >= _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    _resetAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orders.isEmpty) {
      return const LoadingWidget(message: '加载中...');
    }

    if (_error != null && _orders.isEmpty) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return EmptyWidget(
        message: '暂无$_statusLabel订单',
        icon: CupertinoIcons.bag,
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = _orders[index];
                return _SalesOrderCard(
                  order: order,
                  onTap: () => context.push('/mall-order/order-info/${order.number}'),
                );
              },
              childCount: _orders.length,
            ),
          ),
        ),
      ],
    );
  }

  String get _statusLabel {
    if (widget.statusValues.contains(0)) return '待支付';
    if (widget.statusValues.contains(1) || widget.statusValues.contains(5)) return '已付款';
    if (widget.statusValues.contains(3) || widget.statusValues.contains(6)) return '已完成';
    return '订单';
  }
}

/// 销售订单卡片
class _SalesOrderCard extends StatelessWidget {
  final MallOrder order;
  final VoidCallback onTap;

  const _SalesOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order.statusInfo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // 头部：订单编号 + 状态
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: status.label, color: status.color),
                ],
              ),
            ),

            // 商品信息
            if (order.products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    ...order.products.take(2).map((p) => _buildProductRow(context, p)),
                    if (order.products.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              '共 ${order.products.length} 件商品',
                              style: AppText.caption.copyWith(
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // 底部：金额 + 时间
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.formattedCreatedAt,
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '实付: ${order.formattedAmount}',
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (order.discountAmount < order.orderAmount)
                        Text(
                          '原价: ${order.formattedOrderAmount}',
                          style: AppText.caption.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, MallOrderProduct p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: p.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.thumbnail!, fit: BoxFit.cover),
                  )
                : const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.skuName ?? p.productName ?? '商品',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'x${p.qty}',
                  style: AppText.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            p.subtotal,
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

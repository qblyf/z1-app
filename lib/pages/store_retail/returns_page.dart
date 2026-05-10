import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 可退货订单列表 Provider
final returnableOrdersProvider =
    FutureProvider.family<List<MallOrder>, int>((ref, userIdent) async {
  final api = StoreRetailApi();
  try {
    final orders = await api.getAllowAssociatedOrderList(customer: userIdent);
    return orders.map((o) => MallOrder.fromJson(o)).toList();
  } catch (_) {
    return [];
  }
});

/// 退货订单详情 Provider（包含订单完整信息和已退记录）
final returnOrderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderNumber) async {
  return StoreRetailApi().getNewOrderDetailByNumber(orderNumber);
});

/// ════════════════════════════════════════════════════════════════════════════
/// 退货退款主页面（订单列表 + 详情编辑）
/// 对应 PWA /pages/path-d/store-retail/returns.tsx
/// 功能：选择订单 → 选择退货商品/数量 → 选择退款方式 → 提交
/// ════════════════════════════════════════════════════════════════════════════
class ReturnsPage extends ConsumerStatefulWidget {
  final int userIdent;

  const ReturnsPage({super.key, required this.userIdent});

  @override
  ConsumerState<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends ConsumerState<ReturnsPage> {
  MallOrder? _selectedOrder;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(returnableOrdersProvider(widget.userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('退货退款'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return EmptyWidget(
                message: '暂无可退货的订单',
                icon: CupertinoIcons.arrow_counterclockwise,
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _ReturnableOrderCard(
                        order: order,
                        isSelected: _selectedOrder?.number == order.number,
                        onTap: () => setState(() => _selectedOrder = order),
                      );
                    },
                  ),
                ),
                if (_selectedOrder != null)
                  _ReturnDetailPanel(
                    order: _selectedOrder!,
                    onSubmit: _handleReturn,
                    isSubmitting: _isSubmitting,
                  ),
              ],
            );
          },
          loading: () => const LoadingWidget(message: '加载订单...'),
          error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
        ),
      ),
    );
  }

  Future<void> _handleReturn({
    required String orderNumber,
    required Map<String, dynamic> info,
    int? coinAmount,
    int? cashCouponAmount,
    String? payMode,
    List<int>? giftGoodsIds,
    String? remarks,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      final api = StoreRetailApi();
      final success = await api.mallOrderBack(
        mallOrderNumber: orderNumber,
        info: info,
        coinAmount: coinAmount,
        cashCouponAmount: cashCouponAmount,
        payMode: payMode,
        giftGoodsIds: giftGoodsIds,
        remarks: remarks,
      );
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.xmark_circle_fill,
                color: success ? AppColors.accent : CupertinoColors.destructiveRed,
              ),
              const SizedBox(width: 8),
              Text(success ? '退货申请已提交' : '提交失败'),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () {
                Navigator.pop(ctx);
                if (success) context.pop();
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('提交失败'),
            content: Text('网络错误: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 订单卡片
// ─────────────────────────────────────────────────────────────────────────────
class _ReturnableOrderCard extends StatelessWidget {
  final MallOrder order;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReturnableOrderCard({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : CupertinoColors.systemGrey5,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.elevated : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '订单号: ${order.number}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                StatusBadge(
                  label: order.statusEnum.label,
                  color: order.statusEnum.color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.products.isNotEmpty)
              ...order.products.take(3).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: p.thumbnail != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(p.thumbnail!,
                                      fit: BoxFit.cover),
                                )
                              : const Icon(
                                  CupertinoIcons.cube_box,
                                  size: 20,
                                  color: CupertinoColors.systemGrey,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.displayName,
                            style: AppText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('x${p.qty}', style: AppText.caption),
                      ],
                    ),
                  )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(order.createdAt), style: AppText.caption),
                Text(
                  '实付: ¥${(order.discountAmount / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 退货详情面板（底部弹出/内嵌）
// ─────────────────────────────────────────────────────────────────────────────
class _ReturnDetailPanel extends ConsumerStatefulWidget {
  final MallOrder order;
  final Future<void> Function({
    required String orderNumber,
    required Map<String, dynamic> info,
    int? coinAmount,
    int? cashCouponAmount,
    String? payMode,
    List<int>? giftGoodsIds,
    String? remarks,
  }) onSubmit;
  final bool isSubmitting;

  const _ReturnDetailPanel({
    required this.order,
    required this.onSubmit,
    required this.isSubmitting,
  });

  @override
  ConsumerState<_ReturnDetailPanel> createState() => _ReturnDetailPanelState();
}

class _ReturnDetailPanelState extends ConsumerState<_ReturnDetailPanel> {
  final _remarkController = TextEditingController();

  // 商品退货
  final Map<int, _ProductReturnItem> _productReturns = {};

  // 服务退货
  final Map<int, _ServiceReturnItem> _serviceReturns = {};

  // 赠品退货
  final Set<int> _giftGoodsIds = {};

  // 退款方式
  String _refundPayMode = '原路退回';

  // 积分退
  bool _returnCoin = false;

  // 代金券退
  bool _returnCashCoupon = false;

  // 订单详情数据（已退记录）
  Map<String, dynamic>? _orderDetail;
  bool _detailLoading = true;
  String? _detailError;

  // 可用优惠券
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _initReturnItems();
    _loadOrderDetail();
    _loadCoupons();
  }

  void _initReturnItems() {
    // 初始化：默认选中全部商品
    for (final p in widget.order.products) {
      _productReturns[p.skuId] = _ProductReturnItem(
        skuId: p.skuId,
        skuName: p.displayName,
        thumbnail: p.thumbnail,
        totalQty: p.qty,
        returnQty: p.qty,
        unitPrice: p.discountPrice,
      );
    }
  }

  Future<void> _loadOrderDetail() async {
    setState(() => _detailLoading = true);
    try {
      final detail = await ref.read(returnOrderDetailProvider(widget.order.number).future);
      if (mounted) {
        setState(() {
          _orderDetail = detail;
          _detailLoading = false;
        });
        _parseReturnedItems(detail);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailError = e.toString();
          _detailLoading = false;
        });
      }
    }
  }

  void _parseReturnedItems(Map<String, dynamic> detail) {
    // 从 netSaleBackOrder 解析已退数量
    final backOrders = detail['netSaleBackOrder'] as List<dynamic>? ?? [];
    for (final back in backOrders) {
      final products = back['productInfo'] as List<dynamic>? ?? [];
      for (final p in products) {
        final skuId = p['skuID'] as int? ?? 0;
        if (_productReturns.containsKey(skuId)) {
          final returnedQty = p['qty'] as int? ?? 0;
          final item = _productReturns[skuId]!;
          setState(() {
            _productReturns[skuId] = item.copyWith(
              totalQty: item.totalQty + returnedQty,
              returnQty: item.totalQty, // 可退数量 = 原数量（含已退）
            );
          });
        }
      }
      final services = back['serviceInfo'] as List<dynamic>? ?? [];
      for (final s in services) {
        final serviceId = s['serviceID'] as int? ?? 0;
        final returnedQty = s['qty'] as int? ?? 0;
        if (_serviceReturns.containsKey(serviceId)) {
          final item = _serviceReturns[serviceId]!;
          setState(() {
            _serviceReturns[serviceId] = item.copyWith(
              totalQty: item.totalQty + returnedQty,
              returnQty: item.totalQty,
            );
          });
        }
      }
    }
  }

  Future<void> _loadCoupons() async {
    try {
      final coupons = await StoreRetailApi().getReturnCoupons(widget.order.number);
      if (mounted) {
        setState(() => _coupons = coupons);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  /// 计算可退金额
  int get _expectedRefund {
    int total = 0;
    for (final item in _productReturns.values) {
      if (item.returnQty > 0) {
        total += (item.unitPrice * item.returnQty);
      }
    }
    for (final item in _serviceReturns.values) {
      if (item.returnQty > 0) {
        total += (item.unitPrice * item.returnQty);
      }
    }
    // 积分退
    if (_returnCoin) total += _orderDetail?['coinAmount'] as int? ?? 0;
    // 代金券退
    if (_returnCashCoupon) total += _orderDetail?['cashCouponAmount'] as int? ?? 0;
    return total;
  }

  bool get _hasReturnItems {
    final hasProducts = _productReturns.values.any((i) => i.returnQty > 0);
    final hasServices = _serviceReturns.values.any((i) => i.returnQty > 0);
    return hasProducts || hasServices;
  }

  void _submit() {
    if (!_hasReturnItems) return;

    final info = <String, dynamic>{};
    final productIds = <int>[];
    final serviceIds = <int>[];

    for (final item in _productReturns.values) {
      if (item.returnQty > 0) {
        productIds.add(item.skuId);
      }
    }
    for (final item in _serviceReturns.values) {
      if (item.returnQty > 0) {
        serviceIds.add(item.serviceId);
      }
    }

    if (productIds.isNotEmpty) info['productIDs'] = productIds;
    if (serviceIds.isNotEmpty) info['serviceIDs'] = serviceIds;

    widget.onSubmit(
      orderNumber: widget.order.number,
      info: info,
      coinAmount: _returnCoin ? (_orderDetail?['coinAmount'] as int? ?? 0) : null,
      cashCouponAmount: _returnCashCoupon ? (_orderDetail?['cashCouponAmount'] as int? ?? 0) : null,
      payMode: _refundPayMode,
      giftGoodsIds: _giftGoodsIds.isNotEmpty ? _giftGoodsIds.toList() : null,
      remarks: _remarkController.text.trim().isNotEmpty
          ? _remarkController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('退货详情', style: AppText.subtitle),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.systemGrey3, size: 24),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 内容区
          Expanded(
            child: _detailLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _detailError != null
                    ? Center(
                        child: Text('加载失败: $_detailError',
                            style: const TextStyle(color: CupertinoColors.systemRed)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 商品退货
                            if (_productReturns.isNotEmpty) ...[
                              _SectionTitle('退货商品'),
                              const SizedBox(height: 8),
                              ..._productReturns.values.map((item) => _ProductReturnRow(
                                    item: item,
                                    onQtyChanged: (qty) {
                                      setState(() {
                                        _productReturns[item.skuId] =
                                            item.copyWith(returnQty: qty);
                                      });
                                    },
                                  )),
                              const SizedBox(height: 16),
                            ],
                            // 服务退货
                            if (_serviceReturns.isNotEmpty) ...[
                              _SectionTitle('退服务'),
                              const SizedBox(height: 8),
                              ..._serviceReturns.values.map((item) => _ServiceReturnRow(
                                    item: item,
                                    onChanged: (selected) {
                                      setState(() {
                                        _serviceReturns[item.serviceId] = item.copyWith(
                                          returnQty: selected ? item.totalQty : 0,
                                        );
                                      });
                                    },
                                  )),
                              const SizedBox(height: 16),
                            ],
                            // 退款方式
                            _SectionTitle('退款方式'),
                            const SizedBox(height: 8),
                            _RefundPayModeRow(
                              value: _refundPayMode,
                              onChanged: (v) => setState(() => _refundPayMode = v),
                            ),
                            const SizedBox(height: 16),
                            // 积分退 / 代金券退
                            if (_orderDetail != null) ...[
                              _SectionTitle('积分/代金券退'),
                              const SizedBox(height: 8),
                              _CoinCouponReturnRow(
                                coinAmount: _orderDetail!['coinAmount'] as int? ?? 0,
                                cashCouponAmount: _orderDetail!['cashCouponAmount'] as int? ?? 0,
                                returnCoin: _returnCoin,
                                returnCashCoupon: _returnCashCoupon,
                                onCoinChanged: (v) => setState(() => _returnCoin = v),
                                onCashCouponChanged: (v) => setState(() => _returnCashCoupon = v),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // 优惠券提示
                            if (_coupons.isNotEmpty) ...[
                              _SectionTitle('优惠券'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFE69C)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.ticket,
                                        color: Color(0xFFFF9500), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '该订单使用了 ${_coupons.length} 张优惠券，退货后需退还',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF8B5E00)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // 备注
                            _SectionTitle('备注'),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                              controller: _remarkController,
                              placeholder: '退货原因（选填）',
                              padding: const EdgeInsets.all(12),
                              maxLines: 2,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 预计退款金额
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.money_yen_circle,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text('预计退款金额', style: AppText.body),
                                  const Spacer(),
                                  Text(
                                    '¥${(_expectedRefund / 100).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          // 提交按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: !_hasReturnItems || widget.isSubmitting
                      ? null
                      : _submit,
                  child: widget.isSubmitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text('提交退货申请（¥${(_expectedRefund / 100).toStringAsFixed(2)}）'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 小组件 ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.label.copyWith(
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }
}

/// 商品退货行（含数量选择）
class _ProductReturnRow extends StatelessWidget {
  final _ProductReturnItem item;
  final ValueChanged<int> onQtyChanged;
  const _ProductReturnRow({required this.item, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Row(
        children: [
          // 商品图
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(6),
            ),
            child: item.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(item.thumbnail!, fit: BoxFit.cover),
                  )
                : const Icon(CupertinoIcons.cube_box,
                    size: 22, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: 10),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.skuName,
                  style: AppText.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '¥${(item.unitPrice / 100).toStringAsFixed(2)}/件  |  可退 ${item.totalQty} 件',
                  style: AppText.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          // 数量选择
          _QtyStepper(
            value: item.returnQty,
            min: 0,
            max: item.totalQty,
            onChanged: onQtyChanged,
          ),
        ],
      ),
    );
  }
}

/// 服务退货行（勾选）
class _ServiceReturnRow extends StatelessWidget {
  final _ServiceReturnItem item;
  final ValueChanged<bool> onChanged;
  const _ServiceReturnRow({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = item.returnQty > 0;
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : CupertinoColors.systemGrey5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: isSelected ? AppColors.primary : CupertinoColors.systemGrey4,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.serviceName, style: AppText.body),
                  Text(
                    '¥${(item.unitPrice / 100).toStringAsFixed(2)}',
                    style: AppText.caption,
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

/// 退款方式选择
class _RefundPayModeRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RefundPayModeRow({required this.value, required this.onChanged});

  static const _options = ['原路退回', '现金', '银行卡', '微信', '支付宝', '其他'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((opt) {
        final selected = value == opt;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                color: selected ? CupertinoColors.white : CupertinoColors.label,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 积分/代金券退
class _CoinCouponReturnRow extends StatelessWidget {
  final int coinAmount;
  final int cashCouponAmount;
  final bool returnCoin;
  final bool returnCashCoupon;
  final ValueChanged<bool> onCoinChanged;
  final ValueChanged<bool> onCashCouponChanged;

  const _CoinCouponReturnRow({
    required this.coinAmount,
    required this.cashCouponAmount,
    required this.returnCoin,
    required this.returnCashCoupon,
    required this.onCoinChanged,
    required this.onCashCouponChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (coinAmount > 0)
          _ToggleRow(
            label: '退积分',
            sublabel: '积分抵扣 ¥${(coinAmount / 100).toStringAsFixed(2)}',
            value: returnCoin,
            onChanged: onCoinChanged,
          ),
        if (cashCouponAmount > 0)
          _ToggleRow(
            label: '退代金券',
            sublabel: '¥${(cashCouponAmount / 100).toStringAsFixed(2)}',
            value: returnCashCoupon,
            onChanged: onCashCouponChanged,
          ),
        if (coinAmount == 0 && cashCouponAmount == 0)
          Text('该订单未使用积分或代金券',
              style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body),
                Text(sublabel, style: AppText.caption),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// 数量步进器
class _QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _QtyStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value > min
                  ? CupertinoColors.systemGrey5
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.minus,
              size: 14,
              color: value > min
                  ? CupertinoColors.label
                  : CupertinoColors.systemGrey3,
            ),
          ),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text('$value', style: AppText.body),
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value < max
                  ? CupertinoColors.systemGrey5
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.plus,
              size: 14,
              color: value < max
                  ? CupertinoColors.label
                  : CupertinoColors.systemGrey3,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 数据模型 ─────────────────────────────────────────────────────────────────

class _ProductReturnItem {
  final int skuId;
  final String skuName;
  final String? thumbnail;
  final int totalQty; // 可退总数（含已退）
  final int returnQty; // 计划退货数量
  final int unitPrice; // 单价（分）

  _ProductReturnItem({
    required this.skuId,
    required this.skuName,
    this.thumbnail,
    required this.totalQty,
    required this.returnQty,
    required this.unitPrice,
  });

  _ProductReturnItem copyWith({
    int? skuId,
    String? skuName,
    String? thumbnail,
    int? totalQty,
    int? returnQty,
    int? unitPrice,
  }) {
    return _ProductReturnItem(
      skuId: skuId ?? this.skuId,
      skuName: skuName ?? this.skuName,
      thumbnail: thumbnail ?? this.thumbnail,
      totalQty: totalQty ?? this.totalQty,
      returnQty: returnQty ?? this.returnQty,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class _ServiceReturnItem {
  final int serviceId;
  final String serviceName;
  final int totalQty;
  final int returnQty;
  final int unitPrice; // 单价（分）

  _ServiceReturnItem({
    required this.serviceId,
    required this.serviceName,
    required this.totalQty,
    required this.returnQty,
    required this.unitPrice,
  });

  _ServiceReturnItem copyWith({
    int? serviceId,
    String? serviceName,
    int? totalQty,
    int? returnQty,
    int? unitPrice,
  }) {
    return _ServiceReturnItem(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      totalQty: totalQty ?? this.totalQty,
      returnQty: returnQty ?? this.returnQty,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

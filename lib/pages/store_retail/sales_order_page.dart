import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../api/member_api.dart';
import '../../api/warehouse_api.dart';
import '../../api/appointment_booking_api.dart';
import '../../api/product_api.dart';
import '../../models/user.dart';
import '../../models/store_retail.dart';
import '../../models/appointment_booking.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';
import '../clerk/select_specification_page.dart';

/// 门店零售代下单页 Provider
final salesOrderMemberProvider =
    FutureProvider.family<Member, int>((ref, userIdent) async {
  return MemberApi().getByIdent(userIdent);
});

/// 商品搜索 Provider
final retailProductSearchProvider =
    FutureProvider.family<List<RetailSkuItem>, String>((ref, keyword) async {
  if (keyword.trim().isEmpty) return [];
  return StoreRetailApi().searchMallProducts(keyword: keyword);
});

/// 仓库绑定商品 Provider（支持搜索和全量加载）
/// 当 keyword 为空时返回全量商品列表
final retailProductsWithStockProvider =
    FutureProvider.family<List<RetailSkuItem>, ({String keyword, int deptId})>(
        (ref, params) async {
  // keyword 为空时调用全量接口
  final products = await StoreRetailApi().searchMallProducts(
    keyword: params.keyword,
  );
  if (products.isEmpty) return products;

  // 获取当前用户部门的绑定仓库ID列表（对应 PWA getWarehouseIDsByMainDeptID）
  final warehouseIds = await WarehouseApi()
      .getWarehouseIdsByMainDeptId(params.deptId);
  if (warehouseIds.isEmpty) return products;

  // 获取各商品的库存
  final productIds = products.map((p) => p.skuId).toList();
  final stockMap = await StoreRetailApi().getStockStats(
    warehouseIds: warehouseIds,
    productIds: productIds,
  );

  // 将库存合并到商品数据中
  return products.map((p) {
    final stock = stockMap[p.skuId.toString()] ?? stockMap['${p.skuId}'] ?? 0;
    return p.copyWith(stock: stock);
  }).toList();
});

/// 零售购物车 Provider（StateNotifier）
final retailCartProvider =
    StateNotifierProvider.family<RetailCartNotifier, RetailCart, int>(
  (ref, userIdent) => RetailCartNotifier(),
);

class RetailCartNotifier extends StateNotifier<RetailCart> {
  RetailCartNotifier() : super(const RetailCart());

  void addProduct(RetailSkuItem product) {
    final existing = state.products.indexWhere((p) => p.skuId == product.skuId);
    if (existing >= 0) {
      // 已存在，增加数量
      final updated = [...state.products];
      updated[existing] = updated[existing].copyWith(
        qty: updated[existing].qty + 1,
      );
      state = state.copyWith(products: updated, orderType: RetailOrderType.standard);
    } else {
      state = state.copyWith(
        products: [...state.products, product],
        orderType: RetailOrderType.standard,
      );
    }
  }

  void addService(RetailServiceItem service) {
    final existing = state.services.indexWhere((s) => s.serviceId == service.serviceId);
    if (existing >= 0) {
      final updated = [...state.services];
      updated[existing] = updated[existing].copyWith(
        qty: updated[existing].qty + 1,
      );
      state = state.copyWith(services: updated);
    } else {
      state = state.copyWith(services: [...state.services, service]);
    }
  }

  void addNonStandard(RetailNonStandardItem item) {
    final existing = state.nonStandards.indexWhere((n) => n.itemId == item.itemId);
    if (existing >= 0) {
      final updated = [...state.nonStandards];
      final current = updated[existing];
      // NonStandardItem 没有 copyWith，手动重建
      updated[existing] = RetailNonStandardItem(
        itemId: current.itemId,
        name: current.name,
        itemPrice: current.itemPrice,
        discountPrice: current.discountPrice,
        services: current.services,
        goodsId: current.goodsId,
        qty: current.qty + 1,
      );
      state = state.copyWith(nonStandards: updated, orderType: RetailOrderType.nonStandard);
    } else {
      state = state.copyWith(
        nonStandards: [...state.nonStandards, item],
        orderType: RetailOrderType.nonStandard,
      );
    }
  }

  void updateProductQty(int skuId, int qty) {
    if (qty <= 0) {
      removeProduct(skuId);
      return;
    }
    final updated = state.products.map((p) {
      if (p.skuId == skuId) return p.copyWith(qty: qty);
      return p;
    }).toList();
    state = state.copyWith(products: updated);
  }

  void updateServiceQty(int serviceId, int qty) {
    if (qty <= 0) {
      removeService(serviceId);
      return;
    }
    final updated = state.services.map((s) {
      if (s.serviceId == serviceId) {
        return RetailServiceItem(
          serviceId: s.serviceId,
          name: s.name,
          shortName: s.shortName,
          price: s.price,
          discountPrice: s.discountPrice,
          qty: qty,
          goodsId: s.goodsId,
          isGoods: s.isGoods,
          isHasGiveawaysActivity: s.isHasGiveawaysActivity,
        );
      }
      return s;
    }).toList();
    state = state.copyWith(services: updated);
  }

  void removeProduct(int skuId) {
    final updatedGiveaways = Map<String, List<CartGiveaway>>.from(state.giveaways);
    updatedGiveaways.remove('sku-$skuId');
    state = state.copyWith(
      products: state.products.where((p) => p.skuId != skuId).toList(),
      giveaways: updatedGiveaways,
    );
  }

  void removeService(int serviceId) {
    final updatedGiveaways = Map<String, List<CartGiveaway>>.from(state.giveaways);
    updatedGiveaways.remove('service-$serviceId');
    state = state.copyWith(
      services: state.services.where((s) => s.serviceId != serviceId).toList(),
      giveaways: updatedGiveaways,
    );
  }

  void removeNonStandard(int itemId) {
    final updatedGiveaways = Map<String, List<CartGiveaway>>.from(state.giveaways);
    updatedGiveaways.remove('item-$itemId');
    state = state.copyWith(
      nonStandards: state.nonStandards.where((n) => n.itemId != itemId).toList(),
      giveaways: updatedGiveaways,
    );
  }

  /// 设置优惠券
  void setCoupon(SelectedCoupon? coupon) {
    state = state.copyWith(selectedCoupon: coupon, clearCoupon: coupon == null);
  }

  /// 添加赠品
  void addGiveaway(String itemKey, CartGiveaway giveaway) {
    final updated = Map<String, List<CartGiveaway>>.from(state.giveaways);
    final existing = updated[itemKey] ?? [];
    if (!existing.any((g) => g.giftId == giveaway.giftId)) {
      updated[itemKey] = [...existing, giveaway];
    }
    state = state.copyWith(giveaways: updated);
  }

  /// 移除赠品
  void removeGiveaway(String itemKey, int giftId) {
    final updated = Map<String, List<CartGiveaway>>.from(state.giveaways);
    final existing = updated[itemKey] ?? [];
    updated[itemKey] = existing.where((g) => g.giftId != giftId).toList();
    if (updated[itemKey]!.isEmpty) updated.remove(itemKey);
    state = state.copyWith(giveaways: updated);
  }

  void clear() {
    state = const RetailCart();
  }
}

/// 代下单页面
class SalesOrderPage extends ConsumerStatefulWidget {
  final int userIdent;
  /// 从预约单带入商品时传入的预约单ID
  final int? appointmentBookingId;
  /// 从预约单直接带入的SKU ID（优先使用，跳过详情接口）
  final int? appointmentBookingSkuId;
  /// 从积分兑换单带入时传入的兑换单ID
  final int? pointsRedeemOrderId;
  /// 从积分兑换单带入时传入的商品SKU ID
  final int? pointsRedeemOrderSkuId;
  /// 从积分兑换单带入时传入的服务ID
  final int? pointsRedeemOrderServiceId;
  /// 从预售订单带入时的商品SKU ID
  final int? preSaleOrderSkuId;
  /// 从预售订单带入时的订单编号
  final String? preSaleOrderNumber;
  /// 从预售订单带入时的捆绑服务ID列表（JSON字符串）
  final String? preSaleOrderServices;

  const SalesOrderPage({
    super.key,
    required this.userIdent,
    this.appointmentBookingId,
    this.appointmentBookingSkuId,
    this.pointsRedeemOrderId,
    this.pointsRedeemOrderSkuId,
    this.pointsRedeemOrderServiceId,
    this.preSaleOrderSkuId,
    this.preSaleOrderNumber,
    this.preSaleOrderServices,
  });

  @override
  ConsumerState<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends ConsumerState<SalesOrderPage> {
  int _currentTab = 0; // 0=商品, 1=服务, 2=非标
  bool _isLoadingBooking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExternalOrder();
    });
  }

  Future<void> _loadExternalOrder() async {
    // 从预约单预填充（优先使用直接传入的SKU ID，跳过详情接口）
    if (widget.appointmentBookingSkuId != null) {
      await _loadSkuForRedeem(widget.appointmentBookingSkuId!);
    } else if (widget.appointmentBookingId != null) {
      await _loadAppointmentBooking(widget.appointmentBookingId!);
    }
    // 从积分兑换单预填充
    if (widget.pointsRedeemOrderSkuId != null) {
      await _loadSkuForRedeem(widget.pointsRedeemOrderSkuId!);
    }
    // 从预售订单预填充（商品SKU + 捆绑服务）
    if (widget.preSaleOrderSkuId != null) {
      await _loadPreSaleOrder(
        widget.preSaleOrderSkuId!,
        widget.preSaleOrderServices,
      );
    }
  }

  /// 从预售订单预填充：商品SKU + 捆绑服务
  Future<void> _loadPreSaleOrder(int skuId, String? servicesJson) async {
    setState(() => _isLoadingBooking = true);
    try {
      final storeApi = StoreRetailApi();
      // 加载商品 SKU
      final skus = await storeApi.getSkuDetails([skuId]);
      if (skus.isNotEmpty && mounted) {
        ref
            .read(retailCartProvider(widget.userIdent).notifier)
            .addProduct(skus.first.copyWith(qty: 1));
      }
      // 加载捆绑服务
      if (servicesJson != null && servicesJson.isNotEmpty) {
        try {
          final serviceIds = (servicesJson.startsWith('[')
                  ? (jsonDecode(servicesJson) as List).cast<int>()
                  : <int>[])
              .toList();
          if (serviceIds.isNotEmpty) {
            final services = await storeApi.getServiceDetails(serviceIds);
            for (final svc in services) {
              ref
                  .read(retailCartProvider(widget.userIdent).notifier)
                  .addService(svc);
            }
          }
        } catch (_) {}
      }
    } catch (_) {
      // 忽略错误
    } finally {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  Future<void> _loadAppointmentBooking(int bookingId) async {
    setState(() => _isLoadingBooking = true);
    try {
      final api = AppointmentBookingApi();
      final booking = await api.detail(bookingId);
      if (booking == null || !mounted) return;

      if (booking.sku > 0) {
        final storeApi = StoreRetailApi();
        final skus = await storeApi.getSkuDetails([booking.sku]);
        if (skus.isNotEmpty && mounted) {
          ref
              .read(retailCartProvider(widget.userIdent).notifier)
              .addProduct(skus.first.copyWith(qty: 1));
        }
      }
    } catch (_) {
      // 忽略错误
    } finally {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  Future<void> _loadSkuForRedeem(int skuId) async {
    setState(() => _isLoadingBooking = true);
    try {
      final storeApi = StoreRetailApi();
      final skus = await storeApi.getSkuDetails([skuId]);
      if (skus.isNotEmpty && mounted) {
        ref
            .read(retailCartProvider(widget.userIdent).notifier)
            .addProduct(skus.first.copyWith(qty: 1));
      }
    } catch (_) {
      // 忽略错误
    } finally {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(salesOrderMemberProvider(widget.userIdent));
    final cart = ref.watch(retailCartProvider(widget.userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('创建零售单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () {
            ref.read(retailCartProvider(widget.userIdent).notifier).clear();
            context.pop();
          },
        ),
        trailing: memberAsync.whenOrNull(
          data: (member) => CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.person),
            onPressed: () => context.push('/store-retail/home/${widget.userIdent}'),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 会员信息条
            memberAsync.when(
              data: (member) => _MemberBar(member: member, cart: cart),
              loading: () => _MemberBarLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Tab 切换
            _buildTabBar(),

            // Tab 内容
            Expanded(
              child: _currentTab == 0
                  ? _ProductTab(userIdent: widget.userIdent)
                  : _currentTab == 1
                      ? _ServiceTab(userIdent: widget.userIdent)
                      : _NonStandardTab(userIdent: widget.userIdent),
            ),

            // 底部购物车 + 结算
            if (!cart.isEmpty) _BottomBar(cart: cart, userIdent: widget.userIdent),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['商品', '服务', '非标品'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isActive ? AppShadows.card : null,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: isActive
                          ? CupertinoColors.white
                          : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 会员信息条
class _MemberBar extends StatelessWidget {
  final Member member;
  final RetailCart cart;

  const _MemberBar({required this.member, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: CupertinoColors.white,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: member.wxAcatar != null && member.wxAcatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      member.wxAcatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        CupertinoIcons.person_fill,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    CupertinoIcons.person_fill,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.realName ?? '顾客',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  member.mobilePhone ?? '',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${member.coin}积分',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBarLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: CupertinoColors.white,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 商品 Tab
class _ProductTab extends ConsumerStatefulWidget {
  final int userIdent;

  const _ProductTab({required this.userIdent});

  @override
  ConsumerState<_ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends ConsumerState<_ProductTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim();
    final memberAsync = ref.watch(salesOrderMemberProvider(widget.userIdent));

    return Column(
      children: [
        // 搜索栏 + 规格选品按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: '搜索商品名称/编码',
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                minSize: 0,
                onPressed: _openSpecSelectSearch,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('规格选品', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 商品列表
        Expanded(
          child: memberAsync.when(
            data: (member) {
              final deptId = member.deptId ?? 0;
              return keyword.isEmpty
                  ? _buildCategoryProducts(deptId)
                  : _buildSearchResults(keyword, deptId);
            },
            loading: () => const LoadingWidget(message: '加载中...'),
            error: (e, _) => AppErrorWidget(message: '获取会员信息失败: $e'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProducts(int deptId) {
    // 默认展示所有商品（按分类），带仓库库存
    final productsAsync = ref.watch(
      retailProductsWithStockProvider((keyword: '', deptId: deptId)),
    );
    return productsAsync.when(
      data: (products) => products.isEmpty
          ? const EmptyWidget(
              message: '暂无商品，请搜索查找',
              icon: CupertinoIcons.cube_box,
            )
          : _buildProductList(products),
      loading: () => const LoadingWidget(message: '加载商品...'),
      error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
    );
  }

  Widget _buildSearchResults(String keyword, int deptId) {
    final searchAsync = ref.watch(
      retailProductsWithStockProvider((keyword: keyword, deptId: deptId)),
    );
    return searchAsync.when(
      data: (products) => products.isEmpty
          ? EmptyWidget(
              message: '未找到"$keyword"相关商品',
              icon: CupertinoIcons.search,
            )
          : _buildProductList(products),
      loading: () => const LoadingWidget(message: '搜索中...'),
      error: (e, _) => AppErrorWidget(message: '搜索失败: $e'),
    );
  }

  Widget _buildProductList(List<RetailSkuItem> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductGridCard(
          product: product,
          onTap: () => _showAddDialog(product),
        );
      },
    );
  }

  void _showAddDialog(RetailSkuItem product) {
    int qty = 1;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product.thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.thumbnail!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(CupertinoIcons.cube_box),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(product.formattedPrice, style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (product.stock > 0)
                            Text('库存: ${product.stock}', style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('数量', style: AppText.body),
                    const Spacer(),
                    _QtyStepper(
                      value: qty,
                      max: product.stock > 0 ? product.stock : 99,
                      onChanged: (v) => setSheetState(() => qty = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CupertinoButton.filled(
                  onPressed: () {
                    ref.read(retailCartProvider(widget.userIdent).notifier)
                        .addProduct(product.copyWith(qty: qty));
                    Navigator.pop(ctx);
                  },
                  child: const Text('加入零售单'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开规格选品搜索 → 规格选择页 → 加入购物车
  /// 对标 PWA SelectSpecification 组件完整流程
  Future<void> _openSpecSelectSearch() async {
    // 弹出商品搜索对话框
    final result = await showCupertinoModalPopup<(int spuId, String name)?>(
      context: context,
      builder: (ctx) => _SpecProductSearchSheet(
        onSelect: (spuId, name) => Navigator.pop(ctx, (spuId, name)),
      ),
    );

    if (result == null || !mounted) return;
    final (spuId, _) = result;

    // 打开规格选择页
    final specResult = await SelectSpecificationPage.push(context, spuID: spuId);
    if (specResult == null || !mounted) return;

    // 转换并加入购物车
    // MallSkuInfo → RetailSkuItem
    final skuItem = RetailSkuItem(
      skuId: specResult.skuInfo.id,
      spuId: specResult.spuInfo.spuID,
      name: specResult.skuInfo.name,
      qty: specResult.quantity,
      discountPrice: specResult.skuInfo.price ?? 0,
      skuPrice: specResult.skuInfo.listPrice ?? (specResult.skuInfo.price ?? 0),
      thumbnail: specResult.skuInfo.thumbnail,
      stock: specResult.skuInfo.stock,
      services: specResult.services
          .map((s) => RetailServiceItem(
                serviceId: s.id,
                name: s.shortName,
                shortName: s.shortName,
                price: s.price,
              ))
          .toList(),
    );

    ref.read(retailCartProvider(widget.userIdent).notifier).addProduct(skuItem);
  }
}

/// 规格选品 - 商品搜索底部弹出页
class _SpecProductSearchSheet extends StatefulWidget {
  final void Function(int spuId, String name) onSelect;

  const _SpecProductSearchSheet({required this.onSelect});

  @override
  State<_SpecProductSearchSheet> createState() => _SpecProductSearchSheetState();
}

class _SpecProductSearchSheetState extends State<_SpecProductSearchSheet> {
  final _controller = TextEditingController();
  final _api = ProductApi();
  List<SpuSearchResult> _results = [];
  bool _loading = false;

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await _api.searchSpu(keyword: keyword);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 拖动条
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoSearchTextField(
                controller: _controller,
                placeholder: '搜索商品名称',
                autofocus: true,
                onChanged: _search,
                onSubmitted: _search,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _controller.text.isEmpty ? '输入关键词搜索商品' : '未找到商品',
                            style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey5,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: item.mainImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(item.mainImage!, fit: BoxFit.cover),
                                      )
                                    : const Icon(CupertinoIcons.cube_box, color: CupertinoColors.systemGrey),
                              ),
                              title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: item.shortName != null ? Text(item.shortName!, style: AppText.caption) : null,
                              trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
                              onTap: () => widget.onSelect(item.id, item.name),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final RetailSkuItem product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: product.thumbnail != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: Image.network(
                          product.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.cube_box,
                            size: 40,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          CupertinoIcons.cube_box,
                          size: 40,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.formattedPrice,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.stock > 0
                                  ? '库存：${product.stock}'
                                  : '库存不足',
                              style: TextStyle(
                                color: product.stock > 0
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.destructiveRed,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.add_circled,
                        color: product.stock > 0
                            ? AppColors.primary
                            : CupertinoColors.systemGrey3,
                        size: 24,
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
}

/// 服务 Tab
class _ServiceTab extends ConsumerStatefulWidget {
  final int userIdent;

  const _ServiceTab({required this.userIdent});

  @override
  ConsumerState<_ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends ConsumerState<_ServiceTab> {
  final _searchController = TextEditingController();
  List<RetailServiceItem> _allServices = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    // 加载服务列表（从商品接口的服务字段或单独的服务接口）
    try {
      final products = await StoreRetailApi().searchMallProducts(keyword: '', limit: 50);
      final services = <RetailServiceItem>[];
      for (final p in products) {
        services.addAll(p.services);
      }
      if (mounted) setState(() => _allServices = services);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim().toLowerCase();
    final filtered = keyword.isEmpty
        ? _allServices
        : _allServices.where((s) =>
            s.name.contains(keyword) ||
            (s.shortName?.contains(keyword) ?? false)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: '搜索服务名称',
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyWidget(
                  message: '暂无服务项目',
                  icon: CupertinoIcons.wrench,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final service = filtered[index];
                    return _ServiceListCard(
                      service: service,
                      onTap: () => _addService(service),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addService(RetailServiceItem service) {
    ref.read(retailCartProvider(widget.userIdent).notifier).addService(service);
    _showAddedToast(service.name);
  }

  void _showAddedToast(String name) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('已添加: $name'),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }
}

class _ServiceListCard extends StatelessWidget {
  final RetailServiceItem service;
  final VoidCallback onTap;

  const _ServiceListCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                CupertinoIcons.wrench,
                color: const Color(0xFF5856D6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.shortName ?? service.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    service.name,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.formattedPrice,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  CupertinoIcons.add_circled,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 非标品 Tab
class _NonStandardTab extends ConsumerStatefulWidget {
  final int userIdent;

  const _NonStandardTab({required this.userIdent});

  @override
  ConsumerState<_NonStandardTab> createState() => _NonStandardTabState();
}

class _NonStandardTabState extends ConsumerState<_NonStandardTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Icon(CupertinoIcons.exclamationmark_triangle,
                        color: const Color(0xFFFF9500)),
                    const SizedBox(width: 8),
                    Text(
                      '添加非标准商品',
                      style: AppText.subtitle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '非标品无法与标准商品混合下单',
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                _LabeledField(
                  label: '商品名称',
                  child: CupertinoTextField(
                    controller: _nameController,
                    placeholder: '请输入商品名称',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _LabeledField(
                  label: '单价（元）',
                  child: CupertinoTextField(
                    controller: _priceController,
                    placeholder: '请输入单价',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CupertinoButton.filled(
            onPressed: _handleAddNonStandard,
            child: const Text('添加非标品'),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 已添加的非标品列表
          Consumer(
            builder: (context, ref, _) {
              final cart = ref.watch(retailCartProvider(widget.userIdent));
              if (cart.nonStandards.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已添加 (${cart.nonStandards.length})', style: AppText.label),
                  const SizedBox(height: 8),
                  ...cart.nonStandards.map((item) => _NonStandardItemCard(
                        item: item,
                        onRemove: () => ref
                            .read(retailCartProvider(widget.userIdent).notifier)
                            .removeNonStandard(item.itemId),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleAddNonStandard() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty) {
      _showError('请输入商品名称');
      return;
    }

    final price = (double.tryParse(priceText) ?? 0) * 100;
    if (price <= 0) {
      _showError('请输入正确的价格');
      return;
    }

    final item = RetailNonStandardItem(
      itemId: DateTime.now().millisecondsSinceEpoch,
      name: name,
      itemPrice: price.toInt(),
      discountPrice: price.toInt(),
    );

    ref.read(retailCartProvider(widget.userIdent).notifier).addNonStandard(item);
    _nameController.clear();
    _priceController.clear();
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _NonStandardItemCard extends StatelessWidget {
  final RetailNonStandardItem item;
  final VoidCallback onRemove;

  const _NonStandardItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                Text(item.formattedPrice, style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onRemove,
            child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
          ),
        ],
      ),
    );
  }
}

/// 数量步进器
class _QtyStepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _QtyStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperBtn(
          icon: CupertinoIcons.minus,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        _StepperBtn(
          icon: CupertinoIcons.plus,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.primary : CupertinoColors.systemGrey3,
        ),
      ),
    );
  }
}

/// 底部购物车栏
class _BottomBar extends ConsumerStatefulWidget {
  final RetailCart cart;
  final int userIdent;

  const _BottomBar({required this.cart, required this.userIdent});

  @override
  ConsumerState<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<_BottomBar> {
  final _remarkController = TextEditingController();
  bool _isExpanded = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 展开按钮
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.cart.itemCount}',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isExpanded ? '收起商品列表' : '查看已选商品',
                        style: AppText.caption,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_up,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),

            // 已选商品列表（展开时）
            if (_isExpanded) _buildCartItems(),

            // 合计 + 提交
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.cart.selectedCoupon != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '已选券: ${widget.cart.selectedCoupon!.title}',
                                style: TextStyle(
                                  color: CupertinoColors.activeOrange,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => ref.read(retailCartProvider(widget.userIdent).notifier).setCoupon(null),
                              child: const Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: CupertinoColors.systemGrey3),
                            ),
                          ],
                        ),
                      if (widget.cart.selectedCoupon != null)
                        Text(
                          widget.cart.formattedCouponDiscount,
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text('合计', style: AppText.caption),
                      Text(
                        widget.cart.selectedCoupon != null
                            ? widget.cart.formattedPayable
                            : widget.cart.formattedTotal,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 领券中心按钮
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: CupertinoColors.activeOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () => _showCouponCenter(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.tag_fill, size: 14, color: CupertinoColors.activeOrange),
                        const SizedBox(width: 4),
                        Text(
                          widget.cart.selectedCoupon != null ? '换券' : '领券',
                          style: TextStyle(color: CupertinoColors.activeOrange, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    onPressed: _isSubmitting ? null : () => _handleSubmit(context),
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('创建订单'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    final uid = widget.userIdent;
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        shrinkWrap: true,
        children: [
          ...widget.cart.products.map((p) {
            final itemKey = 'sku-${p.skuId}';
            final giveaways = widget.cart.giveaways[itemKey] ?? [];
            final hasGiveaways = giveaways.isNotEmpty;
            return Column(
              children: [
                _CartItemRow(
                  icon: CupertinoIcons.cube_box,
                  color: AppColors.primary,
                  title: p.name,
                  qty: p.qty,
                  price: p.formattedPrice,
                  onQtyChange: (v) => ref
                      .read(retailCartProvider(uid).notifier)
                      .updateProductQty(p.skuId, v),
                  onRemove: () => ref
                      .read(retailCartProvider(uid).notifier)
                      .removeProduct(p.skuId),
                  onGiveawayTap: p.isHasGiveawaysActivity
                      ? () => _showGiveawaySelect(context, itemKey, skuId: p.skuId, itemName: p.name, qty: p.qty)
                      : null,
                  hasGiveaways: hasGiveaways,
                  giveawayCount: giveaways.length,
                ),
                if (hasGiveaways)
                  Padding(
                    padding: const EdgeInsets.only(left: 26, bottom: 4),
                    child: Row(
                      children: giveaways.map((g) => Container(
                        margin: const EdgeInsets.only(right: 6, top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: CupertinoColors.activeGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.gift, size: 10, color: CupertinoColors.activeGreen),
                            const SizedBox(width: 4),
                            Text(
                              g.giftName ?? '赠品',
                              style: const TextStyle(fontSize: 10, color: CupertinoColors.activeGreen),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => ref.read(retailCartProvider(uid).notifier).removeGiveaway(itemKey, g.giftId),
                              child: const Icon(CupertinoIcons.xmark_circle, size: 12, color: CupertinoColors.activeGreen),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            );
          }),
          ...widget.cart.services.map((s) {
            final itemKey = 'service-${s.serviceId}';
            final giveaways = widget.cart.giveaways[itemKey] ?? [];
            final hasGiveaways = giveaways.isNotEmpty;
            return Column(
              children: [
                _CartItemRow(
                  icon: CupertinoIcons.wrench,
                  color: const Color(0xFF5856D6),
                  title: s.name,
                  qty: s.qty,
                  price: s.formattedPrice,
                  onQtyChange: (v) => ref
                      .read(retailCartProvider(uid).notifier)
                      .updateServiceQty(s.serviceId, v),
                  onRemove: () => ref
                      .read(retailCartProvider(uid).notifier)
                      .removeService(s.serviceId),
                  onGiveawayTap: s.isHasGiveawaysActivity
                      ? () => _showGiveawaySelect(context, itemKey, serviceId: s.serviceId, itemName: s.name, qty: s.qty)
                      : null,
                  hasGiveaways: hasGiveaways,
                  giveawayCount: giveaways.length,
                ),
              ],
            );
          }),
          ...widget.cart.nonStandards.map((n) {
            return Column(
              children: [
                _CartItemRow(
                  icon: CupertinoIcons.cube,
                  color: const Color(0xFFFF9500),
                  title: n.name,
                  qty: n.qty,
                  price: n.formattedPrice,
                  onRemove: () => ref
                      .read(retailCartProvider(uid).notifier)
                      .removeNonStandard(n.itemId),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showGiveawaySelect(
    BuildContext context,
    String itemKey, {
    int? skuId,
    int? serviceId,
    int? itemId,
    String? itemName,
    int qty = 1,
  }) async {
    final result = await context.push<List<CartGiveaway>>(
      '/store-retail/giveaway-select',
      extra: {
        'itemKey': itemKey,
        'skuId': skuId,
        'serviceId': serviceId,
        'itemId': itemId,
        'itemName': itemName,
        'qty': qty,
      },
    );
    if (result != null && result.isNotEmpty && mounted) {
      for (final g in result) {
        ref.read(retailCartProvider(widget.userIdent).notifier).addGiveaway(itemKey, g);
      }
    }
  }

  Future<void> _showCouponCenter(BuildContext context) async {
    final api = StoreRetailApi();
    final coupons = await api.getMemberAvailableCoupons(
      userIdent: widget.userIdent,
      minOrderAmount: widget.cart.totalAmount,
    );

    if (!mounted) return;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _CouponSelectSheet(
        coupons: coupons,
        selectedCoupon: widget.cart.selectedCoupon,
        orderAmount: widget.cart.totalAmount,
        onSelect: (coupon) {
          ref.read(retailCartProvider(widget.userIdent).notifier).setCoupon(coupon);
          Navigator.pop(ctx);
        },
        onClear: () {
          ref.read(retailCartProvider(widget.userIdent).notifier).setCoupon(null);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    // 弹出确认对话框
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认创建零售单'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            Text('订单金额: ${widget.cart.formattedTotal}'),
            if (widget.cart.selectedCoupon != null)
              Text(
                '优惠: ${widget.cart.formattedCouponDiscount}',
                style: const TextStyle(color: CupertinoColors.destructiveRed),
              ),
            if (widget.cart.selectedCoupon != null)
              Text('实付: ${widget.cart.formattedPayable}'),
            const SizedBox(height: 4),
            CupertinoTextField(
              controller: _remarkController,
              placeholder: '备注（选填）',
              padding: const EdgeInsets.all(10),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doSubmit();
            },
            child: const Text('确认创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _doSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final api = StoreRetailApi();
      final result = await api.emplAddMallOrder(
        customerIdent: widget.userIdent,
        products: widget.cart.toOrderProducts(),
        remark: _remarkController.text.trim().isNotEmpty
            ? _remarkController.text.trim()
            : null,
        couponIds: widget.cart.selectedCoupon != null
            ? [widget.cart.selectedCoupon!.id]
            : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final orderNumber = result['orderNumber'] ?? '';
        ref.read(retailCartProvider(0).notifier).clear();
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text('订单创建成功'),
              ],
            ),
            content: Column(
              children: [
                const SizedBox(height: 8),
                Text('订单号: $orderNumber'),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/mall-order'); // 跳转商城订单列表
                },
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('创建失败'),
            content: Text(result['message'] ?? '未知错误'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('创建失败'),
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

class _CartItemRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int qty;
  final String price;
  final ValueChanged<int>? onQtyChange;
  final VoidCallback onRemove;
  final VoidCallback? onGiveawayTap;
  final bool hasGiveaways;
  final int giveawayCount;

  const _CartItemRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.qty,
    required this.price,
    this.onQtyChange,
    required this.onRemove,
    this.onGiveawayTap,
    this.hasGiveaways = false,
    this.giveawayCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppText.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 赠品按钮
          if (onGiveawayTap != null)
            GestureDetector(
              onTap: onGiveawayTap,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasGiveaways
                      ? CupertinoColors.activeGreen.withValues(alpha: 0.1)
                      : CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.gift,
                      size: 12,
                      color: hasGiveaways ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      hasGiveaways ? '已选$giveawayCount' : '赠品',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasGiveaways ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (onQtyChange != null) ...[
            GestureDetector(
              onTap: () => onQtyChange!(qty - 1),
              child: Icon(CupertinoIcons.minus_circle, size: 20, color: AppColors.textTertiary),
            ),
            SizedBox(
              width: 28,
              child: Text('$qty', textAlign: TextAlign.center, style: AppText.body),
            ),
            GestureDetector(
              onTap: () => onQtyChange!(qty + 1),
              child: Icon(CupertinoIcons.plus_circle, size: 20, color: AppColors.primary),
            ),
          ] else
            Text('x$qty', style: AppText.caption),
          const SizedBox(width: 8),
          Text(price, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(CupertinoIcons.trash, size: 18, color: CupertinoColors.destructiveRed),
          ),
        ],
      ),
    );
  }
}

/// 优惠券选择底部弹窗
class _CouponSelectSheet extends StatefulWidget {
  final List<Coupon> coupons;
  final SelectedCoupon? selectedCoupon;
  final int orderAmount; // 分
  final void Function(SelectedCoupon?) onSelect;
  final VoidCallback onClear;

  const _CouponSelectSheet({
    required this.coupons,
    this.selectedCoupon,
    required this.orderAmount,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<_CouponSelectSheet> createState() => _CouponSelectSheetState();
}

class _CouponSelectSheetState extends State<_CouponSelectSheet> {
  @override
  Widget build(BuildContext context) {
    final availableCoupons = widget.coupons
        .where((c) => c.state == 2)
        .where((c) => c.minOrderAmount == null || c.minOrderAmount! <= widget.orderAmount)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('选择优惠券', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey3),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 清除按钮
          if (widget.selectedCoupon != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onClear,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.xmark, size: 12, color: CupertinoColors.destructiveRed),
                    const SizedBox(width: 4),
                    Text('不使用优惠券', style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
                  ],
                ),
              ),
            ),
          // 优惠券列表
          Expanded(
            child: availableCoupons.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.tag, size: 48, color: CupertinoColors.systemGrey3),
                        SizedBox(height: 12),
                        Text('暂无可用优惠券', style: TextStyle(color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableCoupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final coupon = availableCoupons[index];
                      final isSelected = widget.selectedCoupon?.id == coupon.id;
                      return _CouponCard(
                        coupon: coupon,
                        isSelected: isSelected,
                        onTap: () {
                          widget.onSelect(SelectedCoupon(
                            id: coupon.id,
                            cent: coupon.cent,
                            title: coupon.title,
                            minOrderAmount: coupon.minOrderAmount,
                          ));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CouponCard({required this.coupon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue.withValues(alpha: 0.05)
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 金额区域
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.activeOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    coupon.cent > 0
                        ? '¥${(coupon.cent / 100).toStringAsFixed(0)}'
                        : '免费',
                    style: TextStyle(
                      color: CupertinoColors.activeOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (coupon.minOrderAmount != null)
                    Text(
                      '满${(coupon.minOrderAmount! / 100).toStringAsFixed(0)}可用',
                      style: TextStyle(
                        color: CupertinoColors.activeOrange,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    coupon.description ?? coupon.typeLabel,
                    style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (coupon.invalidAt != null)
                    Text(
                      '有效期至 ${DateTime.fromMillisecondsSinceEpoch(coupon.invalidAt! * 1000).toString().substring(0, 10)}',
                      style: TextStyle(color: CupertinoColors.tertiaryLabel, fontSize: 11),
                    ),
                ],
              ),
            ),
            // 选中状态
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

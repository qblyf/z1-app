import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../api/member_api.dart';
import '../../models/user.dart';
import '../../models/store_retail.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

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
    state = state.copyWith(
      products: state.products.where((p) => p.skuId != skuId).toList(),
    );
  }

  void removeService(int serviceId) {
    state = state.copyWith(
      services: state.services.where((s) => s.serviceId != serviceId).toList(),
    );
  }

  void removeNonStandard(int itemId) {
    state = state.copyWith(
      nonStandards: state.nonStandards.where((n) => n.itemId != itemId).toList(),
    );
  }

  void clear() {
    state = const RetailCart();
  }
}

/// 代下单页面
class SalesOrderPage extends ConsumerStatefulWidget {
  final int userIdent;

  const SalesOrderPage({super.key, required this.userIdent});

  @override
  ConsumerState<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends ConsumerState<SalesOrderPage> {
  int _currentTab = 0; // 0=商品, 1=服务, 2=非标

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

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: '搜索商品名称/编码',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => setState(() {}),
          ),
        ),

        // 商品列表
        Expanded(
          child: keyword.isEmpty
              ? _buildCategoryProducts()
              : _buildSearchResults(keyword),
        ),
      ],
    );
  }

  Widget _buildCategoryProducts() {
    // 默认展示所有商品（按分类）
    final productsAsync = ref.watch(retailProductSearchProvider(''));
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

  Widget _buildSearchResults(String keyword) {
    final searchAsync = ref.watch(retailProductSearchProvider(keyword));
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
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
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
                      Text('合计', style: AppText.caption),
                      Text(
                        widget.cart.formattedTotal,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
          ...widget.cart.products.map((p) => _CartItemRow(
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
              )),
          ...widget.cart.services.map((s) => _CartItemRow(
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
              )),
          ...widget.cart.nonStandards.map((n) => _CartItemRow(
                icon: CupertinoIcons.cube,
                color: const Color(0xFFFF9500),
                title: n.name,
                qty: n.qty,
                price: n.formattedPrice,
                onRemove: () => ref
                    .read(retailCartProvider(uid).notifier)
                    .removeNonStandard(n.itemId),
              )),
          const SizedBox(height: 8),
        ],
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

  const _CartItemRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.qty,
    required this.price,
    this.onQtyChange,
    required this.onRemove,
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

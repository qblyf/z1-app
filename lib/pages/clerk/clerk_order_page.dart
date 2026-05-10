import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/member_api.dart';
import '../../api/order_api.dart';
import '../../api/product_api.dart';
import '../../api/store_retail_api.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import '../../providers/auth_provider.dart';

/// 店员开单流程页面
/// 对应 PWA /pages/path-d/clerk/clerk-order.tsx
/// 4步流程: 1.输入手机号 → 2.会员信息 → 3.添加商品 → 4.确认订单
class ClerkOrderPage extends ConsumerStatefulWidget {
  const ClerkOrderPage({super.key});

  @override
  ConsumerState<ClerkOrderPage> createState() => _ClerkOrderPageState();
}

class _ClerkOrderPageState extends ConsumerState<ClerkOrderPage> {
  int _step = 1;
  int? _memberIdent;
  Member? _member;
  List<ClerkCartItem> _cart = [];

  void _onMemberFound(int userIdent) {
    setState(() {
      _memberIdent = userIdent;
      _step = 2;
    });
  }

  void _onMemberLoaded(Member member) {
    setState(() {
      _member = member;
      _step = 2;
    });
  }

  void _goToAddProduct() {
    setState(() => _step = 3);
  }

  void _goBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  void _addToCart(ClerkCartItem item) {
    setState(() {
      final existingIndex = _cart.indexWhere((i) => i.key == item.key);
      if (existingIndex >= 0) {
        _cart[existingIndex] = _cart[existingIndex].copyWith(
          quantity: _cart[existingIndex].quantity + 1,
        );
      } else {
        _cart.add(item);
      }
    });
  }

  void _removeFromCart(String key) {
    setState(() {
      _cart.removeWhere((i) => i.key == key);
    });
  }

  void _goToConfirm() {
    if (_cart.isEmpty) return;
    setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_stepTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: _goBack,
        ),
        trailing: _step > 1
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('重置'),
                onPressed: () {
                  setState(() {
                    _step = 1;
                    _member = null;
                    _memberIdent = null;
                    _cart = [];
                  });
                },
              )
            : null,
      ),
      child: SafeArea(
        child: _buildStep(),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 1: return '输入手机号';
      case 2: return '会员信息';
      case 3: return '添加商品';
      case 4: return '确认订单';
      default: return '店员开单';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _PhoneStepPage(
          onNext: _onMemberFound,
          onMemberLoaded: _onMemberLoaded,
        );
      case 2:
        if (_member == null && _memberIdent != null) {
          return _MemberInfoPage(
            userIdent: _memberIdent!,
            onAddProduct: _goToAddProduct,
            onCartChanged: (cart) => setState(() => _cart = cart),
          );
        }
        return _MemberInfoPage(
          userIdent: _member?.userIdent ?? _memberIdent ?? 0,
          onAddProduct: _goToAddProduct,
          onCartChanged: (cart) => setState(() => _cart = cart),
        );
      case 3:
        return _AddProductPage(
          cart: _cart,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
          onConfirm: _goToConfirm,
        );
      case 4:
        return _OrderConfirmPage(
          member: _member,
          cart: _cart,
          onBack: () => setState(() => _step = 3),
          onReset: () {
            setState(() {
              _step = 1;
              _member = null;
              _memberIdent = null;
              _cart = [];
            });
          },
        );
      default:
        return const SizedBox();
    }
  }
}

// ─── Step 1: 输入手机号 ─────────────────────────────────────

class _PhoneStepPage extends StatefulWidget {
  final void Function(int userIdent) onNext;
  final void Function(Member member) onMemberLoaded;

  const _PhoneStepPage({required this.onNext, required this.onMemberLoaded});

  @override
  State<_PhoneStepPage> createState() => _PhoneStepPageState();
}

class _PhoneStepPageState extends State<_PhoneStepPage> {
  final _phoneController = TextEditingController();
  final _storeRetailApi = StoreRetailApi();
  final _memberApi = MemberApi();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  Future<void> _search() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMsg = '请输入手机号');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(() => _errorMsg = '请输入合法手机号');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // 查找会员
      final member = await _storeRetailApi.getMemberByPhone(phone);
      if (!mounted) return;

      if (member != null) {
        widget.onMemberLoaded(member);
        widget.onNext(member.userIdent);
      } else {
        // 未找到，自动创建会员
        final newId = await _storeRetailApi.addMember(mobilePhone: phone);
        if (!mounted) return;

        if (newId > 0) {
          // 获取新创建的会员信息
          final newMember = await _memberApi.getByIdent(newId);
          if (!mounted) return;
          widget.onMemberLoaded(newMember);
          widget.onNext(newId);
        } else {
          setState(() {
            _isLoading = false;
            _errorMsg = '创建会员失败';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = '操作失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          // 标题
          const Text(
            '请输入手机号',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '用于查询或创建会员',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // 手机号输入框
          CupertinoTextField(
            controller: _phoneController,
            placeholder: '请输入手机号码',
            keyboardType: TextInputType.phone,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            style: const TextStyle(fontSize: 18),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMsg != null
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFFE5E5EA),
              ),
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMsg!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF3B30)),
            ),
          ],

          const SizedBox(height: 24),

          // 下一步按钮
          CupertinoButton.filled(
            onPressed: _isLoading ? null : _search,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('下一步'),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Step 2: 会员信息 ─────────────────────────────────────

class _MemberInfoPage extends ConsumerStatefulWidget {
  final int userIdent;
  final VoidCallback onAddProduct;
  final void Function(List<ClerkCartItem>) onCartChanged;

  const _MemberInfoPage({
    required this.userIdent,
    required this.onAddProduct,
    required this.onCartChanged,
  });

  @override
  ConsumerState<_MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends ConsumerState<_MemberInfoPage> {
  final _memberApi = MemberApi();
  Member? _member;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() => _isLoading = true);
    try {
      final m = await _memberApi.getByIdent(widget.userIdent);
      if (mounted) {
        setState(() {
          _member = m;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final member = _member;
    final currentUser = ref.watch(currentUserProvider).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 会员信息卡片
          _InfoCard(
            title: '会员信息',
            children: [
              _InfoRow('会员姓名', member?.realName ?? '未知'),
              _InfoRow('手机号码', member?.mobilePhone ?? '-'),
              _InfoRow('会员等级', 'LV${member?.grade ?? 0}'),
              _InfoRow('可用积分', '${member?.coin ?? 0}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 操作员信息
          _InfoCard(
            title: '基础信息',
            children: [
              _InfoRow('操作员', currentUser?.realName ?? '员工${currentUser?.userIdent ?? 0}'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 按钮
          CupertinoButton.filled(
            onPressed: widget.onAddProduct,
            child: const Text('下一步'),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: 添加商品 ─────────────────────────────────────

class _AddProductPage extends StatefulWidget {
  final List<ClerkCartItem> cart;
  final void Function(ClerkCartItem) onAddToCart;
  final void Function(String key) onRemoveFromCart;
  final VoidCallback onConfirm;

  const _AddProductPage({
    required this.cart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onConfirm,
  });

  @override
  State<_AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<_AddProductPage> {
  final _searchController = TextEditingController();
  final _productApi = ProductApi();
  List<SpuSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchText = keyword;
    });

    try {
      final results = await _productApi.searchSpu(keyword: keyword.trim(), limit: 20);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  int get _totalCount => widget.cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: CupertinoColors.white,
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: '搜索商品名称',
                  onChanged: _search,
                  onSubmitted: _search,
                ),
              ),
            ],
          ),
        ),

        // 商品列表
        Expanded(
          child: _isSearching
              ? const Center(child: CupertinoActivityIndicator())
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchText.isEmpty
                                ? '输入商品名称搜索'
                                : '未找到相关商品',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final spu = _searchResults[index];
                        return _SpuSearchCard(
                          spu: spu,
                          onTap: () => _showSkuSelector(spu),
                        );
                      },
                    ),
        ),

        // 购物车预览 & 确认按钮
        if (widget.cart.isNotEmpty)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('已选 $_totalCount 件商品', style: AppText.caption),
                    Text(
                      '合计: ¥${_calcTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  onPressed: widget.onConfirm,
                  child: const Text('去结算'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  double _calcTotal() {
    return widget.cart.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  void _showSkuSelector(SpuSearchResult spu) async {
    // TODO: 显示 SKU 选择弹窗（规格选择）
    // 暂时直接添加一个默认项
    final item = ClerkCartItem(
      key: '${spu.id}_0',
      spuId: spu.id,
      spuName: spu.name,
      skuId: 0,
      skuName: '默认规格',
      price: 0,
      quantity: 1,
      thumbnail: spu.mainImage,
    );
    widget.onAddToCart(item);
  }
}

class _SpuSearchCard extends StatelessWidget {
  final SpuSearchResult spu;
  final VoidCallback onTap;

  const _SpuSearchCard({required this.spu, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: spu.mainImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(spu.mainImage!, fit: BoxFit.cover),
                    )
                  : Icon(CupertinoIcons.cube_box_fill, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spu.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (spu.shortName != null) ...[
                    const SizedBox(height: 4),
                    Text(spu.shortName!, style: AppText.caption),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.plus_circle_fill,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 4: 确认订单 ─────────────────────────────────────

class _OrderConfirmPage extends ConsumerStatefulWidget {
  final Member? member;
  final List<ClerkCartItem> cart;
  final VoidCallback onBack;
  final VoidCallback onReset;

  const _OrderConfirmPage({
    required this.member,
    required this.cart,
    required this.onBack,
    required this.onReset,
  });

  @override
  ConsumerState<_OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends ConsumerState<_OrderConfirmPage> {
  final _orderApi = OrderApi();
  bool _isSubmitting = false;

  double get _totalAmount =>
      widget.cart.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  Future<void> _submitOrder() async {
    if (widget.member == null) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      final products = widget.cart.map((item) {
        return {
          'skuID': item.skuId,
          'qty': item.quantity,
          'skuPrice': (item.price * 100).toInt(),
          'discountPrice': (item.price * 100).toInt(),
          'services': <Map<String, dynamic>>[],
        };
      }).toList();

      final success = await _orderApi.emplAddMallOrder(
        customerIdent: widget.member!.userIdent,
        products: products,
        departmentId: currentUser?.deptId,
        remark: '店员开单',
      );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        _showToast('下单失败');
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('下单失败: $e');
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('下单成功'),
        content: const Text('订单已创建，可在销售订单列表中查看'),
        actions: [
          CupertinoDialogAction(
            child: const Text('继续开单'),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onReset();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('查看订单'),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onReset();
              context.push(Routes.mallOrderSalesList);
            },
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 会员信息
                _InfoCard(
                  title: '会员信息',
                  children: [
                    _InfoRow('会员姓名', widget.member?.realName ?? '-'),
                    _InfoRow('手机号码', widget.member?.mobilePhone ?? '-'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 商品列表
                _InfoCard(
                  title: '商品列表',
                  children: [
                    for (int i = 0; i < widget.cart.length; i++) ...[
                      _CartItemRow(item: widget.cart[i]),
                      if (i < widget.cart.length - 1)
                        Container(
                          height: 0.5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: AppColors.divider,
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 金额汇总
                _InfoCard(
                  title: '金额汇总',
                  children: [
                    _InfoRow('商品总额', '¥${_totalAmount.toStringAsFixed(2)}'),
                    _InfoRow('优惠金额', '¥0.00'),
                    _InfoRow('应付金额', '¥${_totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 底部按钮
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: CupertinoColors.white,
                onPressed: widget.onBack,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: const Text('上一步', style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  disabledColor: CupertinoColors.systemGrey4,
                  onPressed: _isSubmitting ? null : _submitOrder,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('提交订单'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 通用组件 ─────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          Container(height: 0.5, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.caption),
          Text(
            value,
            style: highlight
                ? const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9500),
                  )
                : AppText.body,
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final ClerkCartItem item;

  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: item.thumbnail != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(item.thumbnail!, fit: BoxFit.cover),
                )
              : Icon(CupertinoIcons.cube_box, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.spuName,
                style: AppText.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.skuName} x ${item.quantity}',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        Text(
          '¥${(item.price * item.quantity).toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}

/// 店员购物车商品
class ClerkCartItem {
  final String key;
  final int spuId;
  final String spuName;
  final int skuId;
  final String skuName;
  final double price;
  int quantity;
  final String? thumbnail;

  ClerkCartItem({
    required this.key,
    required this.spuId,
    required this.spuName,
    required this.skuId,
    required this.skuName,
    required this.price,
    required this.quantity,
    this.thumbnail,
  });

  ClerkCartItem copyWith({
    int? quantity,
  }) {
    return ClerkCartItem(
      key: key,
      spuId: spuId,
      spuName: spuName,
      skuId: skuId,
      skuName: skuName,
      price: price,
      quantity: quantity ?? this.quantity,
      thumbnail: thumbnail,
    );
  }
}

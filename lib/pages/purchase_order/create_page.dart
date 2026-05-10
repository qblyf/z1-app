import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../api/vendor_api.dart';
import '../../api/warehouse_api.dart';
import '../../api/draft_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 采购商品数据
class PurchaseProduct {
  final int productId;
  final String productName;
  final String? thumbnail;
  int quantity;
  int price; // 分

  PurchaseProduct({
    required this.productId,
    required this.productName,
    this.thumbnail,
    this.quantity = 1,
    this.price = 0,
  });
}


class PurchaseOrderCreatePage extends ConsumerStatefulWidget {
  const PurchaseOrderCreatePage({super.key});

  @override
  ConsumerState<PurchaseOrderCreatePage> createState() =>
      _PurchaseOrderCreatePageState();
}

class _PurchaseOrderCreatePageState
    extends ConsumerState<PurchaseOrderCreatePage> {
  Vendor? _selectedVendor;
  WarehouseBase? _selectedWarehouse;
  final _remarkController = TextEditingController();
  final List<PurchaseProduct> _products = [];
  bool _isSubmitting = false;
  bool _isLoadingDraft = false;
  int? _draftId; // 非空表示从草稿加载

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraftIfNeeded());
  }

  Future<void> _loadDraftIfNeeded() async {
    // 从路由参数获取草稿ID
    final draftIdStr = GoRouterState.of(context).uri.queryParameters['draftId'];
    if (draftIdStr == null) return;
    final draftId = int.tryParse(draftIdStr);
    if (draftId == null) return;

    setState(() => _isLoadingDraft = true);
    try {
      final draft = await DraftApi().getDetail(draftId);
      if (draft == null || !mounted) return;

      final data = draft.parseData();
      // 加载供应商
      final vendorId = data['vendorID'] as int?;
      final vendorName = data['vendorName'] as String?;
      if (vendorId != null) {
        _selectedVendor = Vendor(id: vendorId, name: vendorName ?? '供应商');
      }
      // 加载仓库
      final warehouseId = data['warehouseID'] as int?;
      final warehouseName = data['warehouseName'] as String?;
      if (warehouseId != null) {
        _selectedWarehouse = WarehouseBase(
          id: warehouseId,
          name: warehouseName ?? '仓库',
          cateId: 0,
        );
      }
      // 加载备注
      _remarkController.text = data['remarks'] as String? ?? '';
      // 加载商品
      final productsData = data['products'] as List<dynamic>? ?? [];
      _products.clear();
      for (final p in productsData) {
        final pd = p as Map<String, dynamic>;
        _products.add(PurchaseProduct(
          productId: pd['productID'] as int? ?? pd['productId'] as int? ?? 0,
          productName: pd['productName'] as String? ?? '商品',
          thumbnail: pd['thumbnail'] as String?,
          quantity: pd['quantity'] as int? ?? 1,
          price: pd['price'] as int? ?? 0,
        ));
      }
      setState(() {
        _draftId = draftId;
        _isLoadingDraft = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDraft = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_products.isEmpty) {
      _showToast('请先添加商品');
      return;
    }
    final currentUser = ref.read(currentUserProvider).value;
    try {
      final draftApi = DraftApi();
      final data = <String, dynamic>{
        'vendorID': _selectedVendor?.id,
        'vendorName': _selectedVendor?.name,
        'warehouseID': _selectedWarehouse?.id,
        'warehouseName': _selectedWarehouse?.name,
        'remarks': _remarkController.text.trim(),
        'products': _products.map((p) => {
          'productID': p.productId,
          'productName': p.productName,
          'thumbnail': p.thumbnail,
          'quantity': p.quantity,
          'price': p.price,
        }).toList(),
      };
      if (_draftId != null) {
        await draftApi.update(id: _draftId!, data: data, remarks: _remarkController.text.trim());
        if (mounted) _showToast('草稿已更新');
      } else {
        final newId = await draftApi.save(
          type: DraftTypeStr.purchaseOrder.value,
          users: currentUser != null ? [currentUser.userIdent] : [],
          data: data,
          remarks: _remarkController.text.trim(),
        );
        if (mounted) {
          setState(() => _draftId = newId);
          _showToast('草稿已保存');
        }
      }
    } catch (e) {
      if (mounted) _showToast('保存草稿失败: $e');
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  int get _totalAmount =>
      _products.fold(0, (sum, p) => sum + (p.price * p.quantity));

  String get _totalAmountDisplay => '¥${(_totalAmount / 100).toStringAsFixed(2)}';

  Future<void> _submit() async {
    // 表单验证
    if (_selectedVendor == null) {
      _showToast('请选择供应商');
      return;
    }
    if (_selectedWarehouse == null) {
      _showToast('请选择入库仓库');
      return;
    }
    if (_products.isEmpty) {
      _showToast('请添加至少一种商品');
      return;
    }

    final invalidProduct = _products.where((p) => p.quantity <= 0).toList();
    if (invalidProduct.isNotEmpty) {
      _showToast('${invalidProduct.first.productName} 的数量为 0，请修改后重试');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final client = ApiClient();
      await client.post('/purchase-order/create', data: {
        'vendorID': _selectedVendor!.id,
        'warehouseID': _selectedWarehouse!.id,
        'remarks': _remarkController.text.trim(),
        'products': _products.map((p) => {
          'productID': p.productId,
          'quantity': p.quantity,
          'price': p.price,
        }).toList(),
      });

      if (mounted) {
        _showToast('采购订单创建成功');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showToast('创建失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  void _showVendorSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _VendorSheet(
        onSelected: (v) {
          setState(() => _selectedVendor = v);
        },
      ),
    );
  }

  void _showWarehouseSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _WarehouseSheet(
        onSelected: (w) {
          setState(() => _selectedWarehouse = w);
        },
      ),
    );
  }

  void _showRemarkInput() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _RemarkInputModal(
        controller: _remarkController,
        onConfirm: () {
          setState(() {});
        },
      ),
    );
  }

  void _addProduct() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _AddProductSheet(
        onAdd: (product) {
          setState(() {
            final existingIndex =
                _products.indexWhere((p) => p.productId == product.productId);
            if (existingIndex >= 0) {
              _products[existingIndex].quantity += product.quantity;
            } else {
              _products.add(product);
            }
          });
        },
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _products[index].quantity + delta;
      if (newQty > 0) {
        _products[index].quantity = newQty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_draftId != null ? '编辑采购订单' : '新建采购订单'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('草稿'),
          onPressed: () => _saveDraft(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const CupertinoActivityIndicator()
              : const Text('提交'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_isLoadingDraft)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 8),
                    Text('正在加载草稿...'),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 基础信息
                    _SectionHeader('采购信息'),
                    const SizedBox(height: AppSpacing.sm),
                    _FormCard(
                      children: [
                        _FormRow(
                          label: '供应商',
                          value: _selectedVendor?.name ?? '请选择',
                          valueColor: _selectedVendor == null
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showVendorSheet,
                          showArrow: true,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '入库仓库',
                          value: _selectedWarehouse?.name ?? '请选择',
                          valueColor: _selectedWarehouse == null
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showWarehouseSheet,
                          showArrow: true,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '备注',
                          value: _remarkController.text.isEmpty
                              ? '请输入'
                              : _remarkController.text,
                          valueColor: _remarkController.text.isEmpty
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showRemarkInput,
                          showArrow: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 添加商品按钮
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                      onPressed: _addProduct,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.plus_circle_fill,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('添加商品',
                              style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),

                    if (_products.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeader('商品明细'),
                          Text(
                            '合计: $_totalAmountDisplay',
                            style: AppText.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...List.generate(_products.length, (index) {
                        final product = _products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ProductCard(
                            product: product,
                            onDelete: () => _removeProduct(index),
                            onQuantityChanged: (delta) =>
                                _updateQuantity(index, delta),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // 底部栏
            if (_products.isNotEmpty)
              Container(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).padding.bottom + AppSpacing.md,
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
                        Text('合计金额',
                            style: AppText.caption.copyWith(
                                color: CupertinoColors.secondaryLabel)),
                        Text(
                          _totalAmountDisplay,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 10),
                      borderRadius: BorderRadius.circular(25),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white)
                          : const Text('提交订单'),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppText.label.copyWith(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showArrow;

  const _FormRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: AppText.body),
            ),
            Expanded(
              child: Text(
                value,
                style: AppText.body.copyWith(
                  color: valueColor ??
                      CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.lg),
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final PurchaseProduct product;
  final VoidCallback onDelete;
  final void Function(int delta) onQuantityChanged;

  const _ProductCard({
    required this.product,
    required this.onDelete,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: product.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(product.thumbnail!,
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.cube_box_fill,
                              color: AppColors.primary,
                            )),
                  )
                : Icon(CupertinoIcons.cube_box_fill,
                    color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '¥${(product.price / 100).toStringAsFixed(2)}',
                  style: AppText.caption
                      .copyWith(color: const Color(0xFFFF9500)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QuantityButton(
                      icon: CupertinoIcons.minus,
                      onTap: () => onQuantityChanged(-1),
                    ),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text(
                        '${product.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: CupertinoIcons.plus,
                      onTap: () => onQuantityChanged(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                CupertinoIcons.trash,
                color: CupertinoColors.destructiveRed,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

/// 供应商选择弹窗（真实API + 搜索）
class _VendorSheet extends StatefulWidget {
  final void Function(Vendor) onSelected;

  const _VendorSheet({required this.onSelected});

  @override
  State<_VendorSheet> createState() => _VendorSheetState();
}

class _VendorSheetState extends State<_VendorSheet> {
  final _searchController = TextEditingController();
  List<Vendor> _allVendors = [];
  List<Vendor> _filtered = [];
  bool _loading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() => _loading = true);
    try {
      final vendors = await VendorApi().list(limit: 500);
      if (mounted) {
        setState(() {
          _allVendors = vendors;
          _filtered = vendors;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String v) {
    _keyword = v.trim().toLowerCase();
    if (_keyword.isEmpty) {
      setState(() => _filtered = _allVendors);
    } else {
      setState(() {
        _filtered = _allVendors.where((vendor) {
          return vendor.name.toLowerCase().contains(_keyword) ||
              (vendor.spell?.toLowerCase().contains(_keyword) ?? false) ||
              (vendor.number?.toLowerCase().contains(_keyword) ?? false) ||
              (vendor.phone?.toLowerCase().contains(_keyword) ?? false);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择供应商',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  ),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '搜索供应商名称/拼音/编号',
                onChanged: _onSearch,
              ),
            ),
            // 列表
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            _keyword.isEmpty ? '暂无供应商数据' : '未找到匹配的供应商',
                            style: AppText.body.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final v = _filtered[index];
                            return CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                widget.onSelected(v);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: CupertinoColors.separator
                                          .resolveFrom(context),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.person_fill,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(v.name, style: AppText.body),
                                          if (v.number != null)
                                            Text(
                                              '编号: ${v.number}',
                                              style: AppText.caption.copyWith(
                                                color: CupertinoColors
                                                    .secondaryLabel,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 14,
                                      color: CupertinoColors.tertiaryLabel
                                          .resolveFrom(context),
                                    ),
                                  ],
                                ),
                              ),
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

/// 仓库选择弹窗（真实API + 两级分类导航）
class _WarehouseSheet extends StatefulWidget {
  final void Function(WarehouseBase) onSelected;

  const _WarehouseSheet({required this.onSelected});

  @override
  State<_WarehouseSheet> createState() => _WarehouseSheetState();
}

class _WarehouseSheetState extends State<_WarehouseSheet> {
  List<WarehouseBase> _allWarehouses = [];
  List<WarehouseCate> _allCates = [];
  WarehouseCate? _selectedCate;
  bool _loading = true;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await WarehouseApi().listBase();
      if (mounted) {
        setState(() {
          _allWarehouses = result.warehouses;
          _allCates = result.cates;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 一级分类：pid == 0 或链中不含其他分类的顶级分类
  List<WarehouseCate> get _topLevelCates {
    return _allCates.where((c) {
      // 找顶层分类：pid==0 或者其父分类不在列表中
      if (c.pid == 0) return true;
      final parent = _allCates.where((p) => p.id == c.pid).firstOrNull;
      return parent == null;
    }).toList();
  }

  /// 当前分类下的仓库（不含已选分类本身）
  List<WarehouseBase> get _visibleWarehouses {
    if (_selectedCate == null) {
      // 顶层：显示所有分类下的仓库，但按分类过滤
      return _filteredWarehouses;
    }
    // 子级：显示当前分类及其子分类下的仓库
    final cateIds = _collectDescendantCateIds(_selectedCate!.id);
    cateIds.add(_selectedCate!.id);
    return _filteredWarehouses
        .where((w) => cateIds.contains(w.cateId))
        .toList();
  }

  List<WarehouseBase> get _filteredWarehouses {
    if (_searchKeyword.isEmpty) return _allWarehouses;
    final kw = _searchKeyword.toLowerCase();
    return _allWarehouses.where((w) {
      return w.name.toLowerCase().contains(kw) ||
          (w.spell?.toLowerCase().contains(kw) ?? false) ||
          (w.number?.toLowerCase().contains(kw) ?? false);
    }).toList();
  }

  Set<int> _collectDescendantCateIds(int pid) {
    final result = <int>{};
    for (final c in _allCates.where((c) => c.pid == pid)) {
      result.add(c.id);
      result.addAll(_collectDescendantCateIds(c.id));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_selectedCate != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _selectedCate = null),
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        size: 20,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _selectedCate?.name ?? '选择仓库分类',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  ),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CupertinoSearchTextField(
                placeholder: '搜索仓库名称/编号/拼音',
                onChanged: (v) => setState(() => _searchKeyword = v),
              ),
            ),
            // 内容区
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _searchKeyword.isNotEmpty
                      ? _buildWarehouseList(_visibleWarehouses)
                      : (_selectedCate == null
                          ? _buildCategoryGrid(_topLevelCates)
                          : _buildWarehouseList(_visibleWarehouses)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<WarehouseCate> cates) {
    if (cates.isEmpty) {
      return Center(
        child: Text(
          '暂无分类',
          style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cates.length,
      itemBuilder: (context, index) {
        final cate = cates[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedCate = cate),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.folder_fill,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    cate.name,
                    style: AppText.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseList(List<WarehouseBase> warehouses) {
    if (warehouses.isEmpty) {
      return Center(
        child: Text(
          _searchKeyword.isNotEmpty ? '未找到匹配的仓库' : '该分类下暂无仓库',
          style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel),
        ),
      );
    }
    return ListView.builder(
      itemCount: warehouses.length,
      itemBuilder: (context, index) {
        final w = warehouses[index];
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            widget.onSelected(w);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.building_2_fill,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name, style: AppText.body),
                      if (w.number != null)
                        Text(
                          '编号: ${w.number}',
                          style: AppText.caption.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 备注输入弹窗
class _RemarkInputModal extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _RemarkInputModal({
    required this.controller,
    required this.onConfirm,
  });

  @override
  State<_RemarkInputModal> createState() => _RemarkInputModalState();
}

class _RemarkInputModalState extends State<_RemarkInputModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text('备注',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      widget.controller.text = _controller.text;
                      widget.onConfirm();
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: '请输入备注信息',
                maxLines: 4,
                maxLength: 500,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加商品弹窗
class _AddProductSheet extends StatefulWidget {
  final void Function(PurchaseProduct) onAdd;

  const _AddProductSheet({required this.onAdd});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _searchResults = [
          {'productId': 1, 'productName': '商品A - 标准版', 'price': 10000},
          {'productId': 2, 'productName': '商品B - 豪华版', 'price': 20000},
          {'productId': 3, 'productName': '商品C - 简约版', 'price': 8000},
        ].where((item) =>
            (item['productName'] as String).contains(query)).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final newProduct = PurchaseProduct(
      productId: product['productId'] as int,
      productName: product['productName'] as String,
      price: product['price'] as int? ?? 0,
      quantity: 1,
    );
    widget.onAdd(newProduct);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text('添加商品',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '搜索商品',
                onChanged: _search,
              ),
            ),
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
                                color: CupertinoColors.systemGrey3,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '搜索商品添加到采购清单',
                                style: AppText.body.copyWith(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            return CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _addProduct(product),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: CupertinoColors.separator
                                          .resolveFrom(context),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.cube_box_fill,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] as String,
                                            style: AppText.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '¥${((product['price'] as int?) ?? 0 / 100).toStringAsFixed(2)}',
                                            style: AppText.caption.copyWith(
                                                color: const Color(0xFFFF9500)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.plus_circle_fill,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
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

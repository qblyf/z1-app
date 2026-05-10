import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/invoice_api.dart';
import '../../api/member_api.dart';
import '../../models/invoice.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

/// 发票申请表单页
class InvoiceApplicationFormPage extends ConsumerStatefulWidget {
  /// 申请类型：with-order（有订单）/ no-order（无订单）
  final String applyType;

  /// 预填的订单号（可选）
  final String? orderNumber;

  const InvoiceApplicationFormPage({
    super.key,
    required this.applyType,
    this.orderNumber,
  });

  @override
  ConsumerState<InvoiceApplicationFormPage> createState() =>
      _InvoiceApplicationFormPageState();
}

class _InvoiceApplicationFormPageState
    extends ConsumerState<InvoiceApplicationFormPage> {
  final InvoiceApi _api = InvoiceApi();

  bool get isWithOrder => widget.applyType == 'with-order';

  // 表单状态
  InvoiceType? _invoiceType;
  UnitProperties? _unitProperties;
  InvoiceMethod? _invoiceMethod;
  int? _invoiceUsci; // 开票主体ID
  String? _invoiceUsciName; // 开票主体名称
  String? _invoiceHeader;
  String? _phone;
  String? _email;
  String? _taxID;
  String? _bankAccountNumber;
  String? _companyPhone;
  String? _openingBank;
  String? _companyAddress;
  String? _remarks;

  // 订单相关（有订单申请）
  List<String> _selectedOrderNumbers = [];
  InvoiceCheckResult? _checkResult;

  // 无订单商品
  final List<InvoiceNoOrderProduct> _products = [];

  // 系统设置
  double? _taxRate;

  // 加载状态
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 获取税率
    await _loadTaxRate();

    // 如果有预填订单号，自动填充
    if (widget.orderNumber != null) {
      _selectedOrderNumbers = [widget.orderNumber!];
      await _checkOrders();
    }
  }

  Future<void> _loadTaxRate() async {
    try {
      final result = await _api.getSysSetting(keys: ['invoicingTaxRate']);
      if (result != null && result['invoicingTaxRate'] != null) {
        setState(() {
          _taxRate = (result['invoicingTaxRate']['value'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> _checkOrders() async {
    if (_selectedOrderNumbers.isEmpty) return;

    setState(() {});
    try {
      final result = await _api.checkOrder(orderNumbers: _selectedOrderNumbers);
      setState(() {
        _checkResult = result;
      });
    } catch (e) {
      _showError('校验订单失败: $e');
    }
  }

  Future<void> _submit() async {
    // 基础校验
    if (_invoiceType == null) {
      _showError('请选择发票类型');
      return;
    }
    if (_unitProperties == null) {
      _showError('请选择单位性质');
      return;
    }
    if (_invoiceMethod == null) {
      _showError('请选择开票方式');
      return;
    }
    if (_invoiceUsci == null) {
      _showError('请选择开票主体');
      return;
    }
    if (_invoiceHeader == null || _invoiceHeader!.isEmpty) {
      _showError('请输入发票抬头');
      return;
    }
    if (_phone == null || _phone!.isEmpty) {
      _showError('请输入联系电话');
      return;
    }

    // 企业必填税号
    if (_unitProperties == UnitProperties.company) {
      if (_taxID == null || _taxID!.isEmpty) {
        _showError('请输入税号');
        return;
      }
      if (!_validateTaxID(_taxID!)) {
        _showError('请输入正确的税号');
        return;
      }
    }

    // 邮箱校验
    if (_email != null && _email!.isNotEmpty) {
      if (!_validateEmail(_email!)) {
        _showError('请输入正确的电子邮箱');
        return;
      }
    }

    // 数电票邮箱必填
    if (_invoiceType == InvoiceType.digitalElecSpecial ||
        _invoiceType == InvoiceType.digitalElecGeneral) {
      if (_email == null || _email!.isEmpty) {
        _showError('请输入电子邮箱');
        return;
      }
    }

    // 有订单申请校验
    if (isWithOrder && _selectedOrderNumbers.isEmpty) {
      _showError('请选择订单');
      return;
    }

    // 无订单申请校验
    if (!isWithOrder && _products.isEmpty) {
      _showError('请添加商品信息');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      bool success;
      if (isWithOrder) {
        success = await _api.applyWithOrder(
          invoiceHeader: _invoiceHeader!,
          phone: _phone!,
          unitProperties: _unitProperties!,
          invoiceMethod: _invoiceMethod!,
          invoiceType: _invoiceType!,
          invoiceUsci: _invoiceUsci!,
          email: _email,
          taxID: _taxID,
          companyAddress: _companyAddress,
          companyPhone: _companyPhone,
          openingBank: _openingBank,
          bankAccountNumber: _bankAccountNumber,
          orderNumbers: _selectedOrderNumbers,
          remarks: _remarks,
        );
      } else {
        success = await _api.applyNoOrder(
          invoiceHeader: _invoiceHeader!,
          phone: _phone!,
          unitProperties: _unitProperties!,
          invoiceMethod: _invoiceMethod!,
          invoiceType: _invoiceType!,
          invoiceUsci: _invoiceUsci!,
          email: _email,
          taxID: _taxID,
          companyAddress: _companyAddress,
          companyPhone: _companyPhone,
          openingBank: _openingBank,
          bankAccountNumber: _bankAccountNumber,
          remarks: _remarks,
          orderInfos: _products,
        );
      }

      setState(() => _isSubmitting = false);

      if (success) {
        _showSuccess('提交成功');
        if (mounted) context.pop();
      } else {
        _showError('提交失败');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('提交失败: $e');
    }
  }

  bool _validateTaxID(String taxID) {
    // 税号校验：15/18/20位数字或字母
    return RegExp(r'^[A-Z0-9]{15}$|^[A-Z0-9]{18}$|^[A-Z0-9]{20}$').hasMatch(taxID.toUpperCase());
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // 计算开票总金额
  int get _totalAmount {
    if (isWithOrder) {
      if (_checkResult == null) return 0;
      int total = 0;
      for (final info in _checkResult!.orderInfos) {
        for (final sku in info.productInfo) {
          total += sku.discountAmount;
        }
        for (final item in info.itemInfo) {
          total += item.discountAmount;
        }
        for (final s in info.serviceInfo) {
          total += s.discountAmount;
        }
      }
      return total;
    } else {
      return _products.fold(0, (sum, p) => sum + p.amount * p.quantity);
    }
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
        middle: Text(isWithOrder ? '有订单发票申请' : '无订单发票申请'),
        previousPageTitle: '返回',
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildSectionTitle('申请信息'),
                  _buildCard([
                    _buildInfoRow('申请人', _getCurrentUserName()),
                    _buildInfoRow('部门', _getCurrentDeptName()),
                    _buildInfoRow('申请日期', _formatDate(DateTime.now())),
                    _buildInfoRow('状态', '待提交', borderBottom: false),
                  ]),
                  const SizedBox(height: 16),

                  // 订单编号选择（有订单申请）
                  if (isWithOrder) ...[
                    _buildSectionTitle('订单信息'),
                    _buildCard([
                      _buildSelectRow(
                        '订单编号',
                        _selectedOrderNumbers.isEmpty
                            ? '请选择'
                            : '${_selectedOrderNumbers.length}个订单已选择',
                        isRequired: true,
                        onTap: _showOrderSelector,
                      ),
                      if (_selectedOrderNumbers.isNotEmpty)
                        _buildOrderList(),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // 发票类型、单位性质、开票方式、开票主体
                  _buildSectionTitle('发票信息'),
                  _buildCard([
                    _buildSelectRow(
                      '发票类型',
                      _invoiceType?.label ?? '请选择',
                      isRequired: true,
                      onTap: _showInvoiceTypePicker,
                    ),
                    _buildSelectRow(
                      '单位性质',
                      _unitProperties?.label ?? '请选择',
                      isRequired: true,
                      onTap: _showUnitPropertiesPicker,
                    ),
                    _buildSelectRow(
                      '开票方式',
                      _invoiceMethod?.label ?? '请选择',
                      isRequired: true,
                      onTap: _showInvoiceMethodPicker,
                    ),
                    _buildSelectRow(
                      '开票主体',
                      _invoiceUsciName ?? '请选择',
                      isRequired: true,
                      onTap: _showInvoiceUsciPicker,
                      borderBottom: false,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // 发票抬头、联系电话
                  _buildSectionTitle('发票抬头'),
                  _buildCard([
                    _buildInputRow(
                      '发票抬头',
                      _invoiceHeader,
                      placeholder: '请输入发票抬头',
                      isRequired: true,
                      onChanged: (v) => setState(() => _invoiceHeader = v),
                    ),
                    _buildInputRow(
                      '联系电话',
                      _phone,
                      placeholder: '请输入联系电话',
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => setState(() => _phone = v),
                      borderBottom: false,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // 邮箱（电子发票/数电票）
                  if (_invoiceType == InvoiceType.elecSpecial ||
                      _invoiceType == InvoiceType.elecGeneral ||
                      _invoiceType == InvoiceType.digitalElecSpecial ||
                      _invoiceType == InvoiceType.digitalElecGeneral) ...[
                    _buildCard([
                      _buildInputRow(
                        '电子邮箱',
                        _email,
                        placeholder: '请输入电子邮箱',
                        isRequired: _invoiceType == InvoiceType.digitalElecSpecial ||
                            _invoiceType == InvoiceType.digitalElecGeneral,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => setState(() => _email = v),
                        borderBottom: false,
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // 企业信息
                  if (_unitProperties == UnitProperties.company) ...[
                    _buildSectionTitle('企业信息'),
                    _buildCard([
                      _buildInputRow(
                        '税号',
                        _taxID,
                        placeholder: '请输入税号',
                        isRequired: true,
                        onChanged: (v) => setState(() => _taxID = v),
                      ),
                      _buildInputRow(
                        '银行账号',
                        _bankAccountNumber,
                        placeholder: '请输入银行账号（选填）',
                        onChanged: (v) => setState(() => _bankAccountNumber = v),
                      ),
                      _buildInputRow(
                        '公司电话',
                        _companyPhone,
                        placeholder: '请输入公司电话（选填）',
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => setState(() => _companyPhone = v),
                      ),
                      _buildInputRow(
                        '开户银行',
                        _openingBank,
                        placeholder: '请输入开户银行（选填）',
                        onChanged: (v) => setState(() => _openingBank = v),
                      ),
                      _buildInputRow(
                        '公司地址',
                        _companyAddress,
                        placeholder: '请输入公司地址（选填）',
                        onChanged: (v) => setState(() => _companyAddress = v),
                        borderBottom: false,
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // 无订单商品管理
                  if (!isWithOrder) ...[
                    _buildSectionTitle('商品信息'),
                    _buildCard([
                      if (_products.isEmpty)
                        _buildEmptyProducts()
                      else
                        ..._products.asMap().entries.map((e) =>
                            _buildProductItem(e.key, e.value)),
                      _buildAddProductButton(),
                    ], padding: const EdgeInsets.all(AppSpacing.md)),
                    const SizedBox(height: 16),
                  ],

                  // 开票信息
                  _buildSectionTitle('开票信息'),
                  _buildCard([
                    _buildInfoRow(
                      '开票金额',
                      '¥${(_totalAmount / 100).toStringAsFixed(2)}',
                      valueColor: const Color(0xFFFF9500),
                      fontWeight: FontWeight.bold,
                    ),
                    _buildInputRow(
                      '备注',
                      _remarks,
                      placeholder: '请输入备注（选填）',
                      onChanged: (v) => setState(() => _remarks = v),
                      borderBottom: false,
                    ),
                  ]),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight fontWeight = FontWeight.normal,
    bool borderBottom = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: borderBottom
            ? const Border(
                bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.body.copyWith(
                color: valueColor,
                fontWeight: fontWeight,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectRow(
    String label,
    String value, {
    bool isRequired = false,
    bool borderBottom = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: borderBottom
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
                )
              : null,
        ),
        child: Row(
          children: [
            Text(label, style: AppText.body),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Color(0xFFFF3B30)),
              ),
            const Spacer(),
            Text(
              value,
              style: AppText.body.copyWith(
                color: value.startsWith('请') || value.isEmpty
                    ? AppColors.textTertiary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    String? value, {
    String placeholder = '',
    bool isRequired = false,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
    bool borderBottom = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: borderBottom
            ? const Border(
                bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(color: Color(0xFFFF3B30), fontSize: 12),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: TextEditingController(text: value),
              placeholder: placeholder,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              decoration: const BoxDecoration(),
              padding: EdgeInsets.zero,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: _selectedOrderNumbers.map((orderNumber) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    orderNumber,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrderNumbers.remove(orderNumber);
                    });
                    if (_selectedOrderNumbers.isNotEmpty) {
                      _checkOrders();
                    } else {
                      setState(() => _checkResult = null);
                    }
                  },
                  child: const Text(
                    '删除',
                    style: TextStyle(
                      color: Color(0xFF0A84FF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            CupertinoIcons.cube_box,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            '暂无商品，点击下方按钮添加',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(int index, InvoiceNoOrderProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () => _editProduct(index),
                child: const Text(
                  '编辑',
                  style: TextStyle(color: Color(0xFF0A84FF)),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() => _products.removeAt(index));
                },
                child: const Text(
                  '删除',
                  style: TextStyle(color: Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '数量: ${product.quantity}  单价: ¥${product.amountYuan.toStringAsFixed(2)}  合计: ¥${(product.amountYuan * product.quantity).toStringAsFixed(2)}',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return GestureDetector(
      onTap: _showAddProductDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.plus_circle_fill,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '添加商品',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: AppShadows.tabBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 金额信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开票余额', style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(
                    _checkResult != null
                        ? '¥${(_checkResult!.monthlyInvoicingAmountYuan).toStringAsFixed(2)}'
                        : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开票余量', style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(
                    _checkResult != null
                        ? '${_checkResult!.monthlyInvoicingQuantity}'
                        : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('适用税率', style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(
                    _taxRate != null ? '${_taxRate!.toStringAsFixed(1)}%' : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('开票金额', style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(
                    '¥${(_totalAmount / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 提交按钮
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('提交申请'),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 选择器方法 ==========

  void _showInvoiceTypePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _SelectSheet<InvoiceType>(
        title: '选择发票类型',
        options: InvoiceType.values,
        labels: InvoiceType.values.map((e) => e.label).toList(),
        selected: _invoiceType,
        onSelect: (type) {
          setState(() {
            _invoiceType = type;
            // 纸质发票清除邮箱
            if (type == InvoiceType.paperSpecial || type == InvoiceType.paperGeneral) {
              _email = null;
            }
          });
        },
      ),
    );
  }

  void _showUnitPropertiesPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _SelectSheet<UnitProperties>(
        title: '选择单位性质',
        options: UnitProperties.values,
        labels: UnitProperties.values.map((e) => e.label).toList(),
        selected: _unitProperties,
        onSelect: (unit) => setState(() => _unitProperties = unit),
      ),
    );
  }

  void _showInvoiceMethodPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _SelectSheet<InvoiceMethod>(
        title: '选择开票方式',
        options: InvoiceMethod.values,
        labels: InvoiceMethod.values.map((e) => e.label).toList(),
        selected: _invoiceMethod,
        onSelect: (method) => setState(() => _invoiceMethod = method),
      ),
    );
  }

  void _showInvoiceUsciPicker() {
    // TODO: 实际应该从API获取开票主体列表
    // 这里先用模拟数据演示
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _SelectSheet<int>(
        title: '选择开票主体',
        options: const [1, 2, 3],
        labels: const ['主体1', '主体2', '主体3'],
        selected: _invoiceUsci,
        onSelect: (id) {
          setState(() {
            _invoiceUsci = id;
            _invoiceUsciName = '主体$id';
          });
        },
      ),
    );
  }

  void _showOrderSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _InvoiceOrderSelectorSheet(
        selectedOrderNumbers: _selectedOrderNumbers,
        onConfirm: (orderNumbers) {
          setState(() {
            _selectedOrderNumbers = orderNumbers;
          });
          if (orderNumbers.isNotEmpty) {
            _checkOrders();
          } else {
            setState(() => _checkResult = null);
          }
        },
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('添加商品'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: '商品名称 *',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: quantityController,
              placeholder: '数量 *',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: priceController,
              placeholder: '单价(元) *',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('添加'),
            onPressed: () {
              final name = nameController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (name.isEmpty || quantity <= 0 || price <= 0) {
                _showError('请填写完整的商品信息');
                return;
              }

              setState(() {
                _products.add(InvoiceNoOrderProduct(
                  name: name,
                  quantity: quantity,
                  amount: (price * 100).toInt(),
                ));
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editProduct(int index) {
    final product = _products[index];
    final nameController = TextEditingController(text: product.name);
    final quantityController =
        TextEditingController(text: product.quantity.toString());
    final priceController =
        TextEditingController(text: product.amountYuan.toString());

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('编辑商品'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: '商品名称 *',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: quantityController,
              placeholder: '数量 *',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: priceController,
              placeholder: '单价(元) *',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('保存'),
            onPressed: () {
              final name = nameController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (name.isEmpty || quantity <= 0 || price <= 0) {
                _showError('请填写完整的商品信息');
                return;
              }

              setState(() {
                _products[index] = product.copyWith(
                  name: name,
                  quantity: quantity,
                  amount: (price * 100).toInt(),
                );
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ========== 辅助方法 ==========

  String _getCurrentUserName() {
    final user = ref.read(currentUserProvider).value;
    return user?.realName ?? '未知';
  }

  String _getCurrentDeptName() {
    // 从 currentUser 获取部门名称
    final user = ref.read(currentUserProvider).value;
    return user?.deptName ?? '未知';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 发票订单选择器（按手机号查询）
/// 对应 PWA: SelectOrderByPhone
class _InvoiceOrderSelectorSheet extends StatefulWidget {
  final List<String> selectedOrderNumbers;
  final ValueChanged<List<String>> onConfirm;

  const _InvoiceOrderSelectorSheet({
    required this.selectedOrderNumbers,
    required this.onConfirm,
  });

  @override
  State<_InvoiceOrderSelectorSheet> createState() => _InvoiceOrderSelectorSheetState();
}

class _InvoiceOrderSelectorSheetState extends State<_InvoiceOrderSelectorSheet> {
  final InvoiceApi _invoiceApi = InvoiceApi();
  final MemberApi _memberApi = MemberApi();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;
  List<_OrderItemData> _orders = [];
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedOrderNumbers);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String v) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(v.trim());
  }

  Future<void> _searchByPhone(String phone) async {
    final trimmed = phone.trim();
    if (!_isValidPhone(trimmed)) {
      setState(() => _errorMsg = '请输入正确的手机号');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _orders = [];
    });

    try {
      // 1. 搜索会员
      final members = await _memberApi.getList(mobilePhone: trimmed);
      if (members.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMsg = '未找到该手机号的会员';
        });
        return;
      }
      final member = members.first;

      // 2. 获取可开票订单
      final orders = await _invoiceApi.getOrderInfoByMember(member.userIdent);

      // 3. 转换为内部数据格式
      final items = orders.map((o) {
        String productName = '未知商品';
        if (o.serviceInfo.isNotEmpty) {
          productName = o.serviceInfo.first.name ?? '未知服务';
        } else if (o.productInfo.isNotEmpty) {
          productName = o.productInfo.first.name ?? '未知商品';
        } else if (o.itemInfo.isNotEmpty) {
          productName = o.itemInfo.first.name ?? '未知商品';
        }

        return _OrderItemData(
          orderNumber: o.orderInfo.orderNumber,
          genre: o.orderInfo.genre,
          mallOrderNumber: o.mallOrderNumber,
          productName: productName,
          amount: o.totalAmount,
          createdAt: o.orderInfo.createdAt,
          sellerIdent: o.orderInfo.sellerIdent,
        );
      }).toList();

      setState(() {
        _orders = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = '获取订单失败: $e';
      });
    }
  }

  void _toggle(String orderNumber) {
    setState(() {
      if (_selected.contains(orderNumber)) {
        _selected.remove(orderNumber);
      } else {
        _selected.add(orderNumber);
      }
    });
  }

  void _confirm() async {
    if (_selected.isEmpty) {
      _showToast('请选择订单');
      return;
    }

    // 调用后端校验
    setState(() => _isLoading = true);
    try {
      await _invoiceApi.checkOrder(orderNumbers: _selected.toList());
      if (mounted) {
        Navigator.pop(context);
        widget.onConfirm(_selected.toList());
      }
    } catch (e) {
      if (mounted) {
        _showToast('校验失败: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '选择订单',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      size: 24, color: Color(0xFF0575FF)),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.divider),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    controller: _phoneController,
                    placeholder: '输入手机号搜索订单',
                    keyboardType: TextInputType.phone,
                    onSubmitted: _searchByPhone,
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () => _searchByPhone(_phoneController.text),
                  child: const Text('搜索', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),

          // 错误信息
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13),
              ),
            ),

          // 加载中
          if (_isLoading)
            const Expanded(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_orders.isEmpty && _errorMsg == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.search,
                        size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      '输入手机号搜索订单',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _orders.length,
                itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
              ),
            ),

          // 确认按钮
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Column(
              children: [
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '已选 ${_selected.length} 个订单',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(22),
                    onPressed: _isLoading ? null : _confirm,
                    child: const Text('确认', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(_OrderItemData item) {
    final isSelected = _selected.contains(item.orderNumber);
    final isStore = item.genre == '店内';

    return GestureDetector(
      onTap: () => _toggle(item.orderNumber),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF0054E9), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 订单类型 + 订单号
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isStore
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isStore ? '零售单号' : '网销单号',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isStore
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.orderNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 选中状态
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0054E9)
                        : CupertinoColors.white,
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0xFFB9B9B9)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          size: 14,
                          color: CupertinoColors.white,
                        )
                      : null,
                ),
              ],
            ),

            // 商城单号（网销单）
            if (!isStore && item.mallOrderNumber != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 80),
                  const Text(
                    '商城单号',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.mallOrderNumber!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),
            // 商品名称
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    '商品名称',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            // 实付金额
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    '实付金额',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
                Text(
                  '¥${(item.amount / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            // 创建日期
            Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    '创建日期',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int unix) {
    if (unix == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// 内部订单数据
class _OrderItemData {
  final String orderNumber;
  final String genre;
  final String? mallOrderNumber;
  final String productName;
  final int amount;
  final int createdAt;
  final int? sellerIdent;

  const _OrderItemData({
    required this.orderNumber,
    required this.genre,
    this.mallOrderNumber,
    required this.productName,
    required this.amount,
    required this.createdAt,
    this.sellerIdent,
  });
}

/// 通用选择弹窗
class _SelectSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final List<String> labels;
  final T? selected;
  final ValueChanged<T> onSelect;

  const _SelectSheet({
    required this.title,
    required this.options,
    required this.labels,
    this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 60),
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (_, i) {
                final isSelected = selected == options[i];
                return GestureDetector(
                  onTap: () {
                    onSelect(options[i]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
                      ),
                      color: isSelected ? const Color(0xFFE3F2FD) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(labels[i])),
                        if (isSelected)
                          const Icon(
                            CupertinoIcons.checkmark,
                            color: Color(0xFF0A84FF),
                            size: 20,
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
    );
  }
}

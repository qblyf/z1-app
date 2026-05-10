import 'package:flutter/cupertino.dart';

/// 发票状态
enum InvoiceStatus {
  noInvoice('no-invoice', '未开票', Color(0xFF8E8E93)),
  toBeInvoiced('to-be-invoiced', '待开票', Color(0xFFFF9500)),
  invoiced('invoiced', '已开票', Color(0xFF30D158)),
  deprecated('deprecated', '已废弃', Color(0xFF8E8E93)),
  reverse('reverse', '红冲', Color(0xFFFF3B30)),
  reversed('reversed', '被红冲', Color(0xFFFF6B6B)),
  cancel('cancel', '取消开票', Color(0xFF8E8E93));

  final String value;
  final String label;
  final Color color;

  const InvoiceStatus(this.value, this.label, this.color);

  static InvoiceStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 发票类型
enum InvoiceType {
  paperGeneral('paper-general', '纸质普票'),
  elecGeneral('elec-general', '电子普票'),
  paperSpecial('paper-special', '纸质专票'),
  elecSpecial('elec-special', '电子专票'),
  digitalElecSpecial('digital-elec-special', '数电票专票'),
  digitalElecGeneral('digital-elec-general', '数电票普票');

  final String value;
  final String label;

  const InvoiceType(this.value, this.label);

  /// 是否需要邮箱
  bool get needsEmail {
    return this == elecSpecial ||
        this == elecGeneral ||
        this == digitalElecSpecial ||
        this == digitalElecGeneral;
  }

  /// 是否需要税号（企业）
  bool get needsTaxId {
    return true; // 企业都需要
  }

  static InvoiceType? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 单位性质
enum UnitProperties {
  personal('personal', '个人'),
  company('company', '企业');

  final String value;
  final String label;

  const UnitProperties(this.value, this.label);

  static UnitProperties? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 开票方式
enum InvoiceMethod {
  self('self', '自开'),
  other('other', '代开');

  final String value;
  final String label;

  const InvoiceMethod(this.value, this.label);

  static InvoiceMethod? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 红字蓝字
enum RedBlue {
  red('red', '红字'),
  blue('blue', '蓝字');

  final String value;
  final String label;

  const RedBlue(this.value, this.label);

  static RedBlue? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 无订单商品
class InvoiceNoOrderItem {
  final String name;
  final int quantity;
  final int amount; // 分
  final List<String> attachment;

  const InvoiceNoOrderItem({
    required this.name,
    required this.quantity,
    required this.amount,
    required this.attachment,
  });

  factory InvoiceNoOrderItem.fromJson(Map<String, dynamic> json) {
    return InvoiceNoOrderItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      attachment: (json['attachment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  double get amountYuan => amount / 100.0;
}

/// 订单中的标品商品
class InvoiceSkuItem {
  final int skuId;
  final String name;
  final int quantity;
  final int amount; // 分

  const InvoiceSkuItem({
    required this.skuId,
    required this.name,
    required this.quantity,
    required this.amount,
  });

  factory InvoiceSkuItem.fromJson(Map<String, dynamic> json) {
    return InvoiceSkuItem(
      skuId: json['skuID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }

  double get amountYuan => amount / 100.0;
}

/// 订单中的非标商品
class InvoiceItem {
  final int skuId;
  final String name;
  final int quantity;
  final int amount; // 分

  const InvoiceItem({
    required this.skuId,
    required this.name,
    required this.quantity,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      skuId: json['skuID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }

  double get amountYuan => amount / 100.0;
}

/// 订单信息
class InvoiceOrderInfo {
  final String orderNumber;
  final List<InvoiceSkuItem> skus;
  final List<InvoiceItem> items;
  final List<InvoiceSkuItem> services;
  final List<InvoiceNoOrderItem> noOrder;

  const InvoiceOrderInfo({
    required this.orderNumber,
    required this.skus,
    required this.items,
    required this.services,
    required this.noOrder,
  });

  factory InvoiceOrderInfo.fromJson(Map<String, dynamic> json) {
    return InvoiceOrderInfo(
      orderNumber: json['orderNumber'] as String? ?? '',
      skus: (json['skus'] as List<dynamic>?)
              ?.map((e) => InvoiceSkuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => InvoiceSkuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      noOrder: (json['noOrder'] as List<dynamic>?)
              ?.map((e) => InvoiceNoOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 计算总金额
  int get totalAmount {
    int total = 0;
    for (final sku in skus) {
      total += sku.amount;
    }
    for (final item in items) {
      total += item.amount;
    }
    for (final s in services) {
      total += s.amount;
    }
    for (final n in noOrder) {
      total += n.amount * n.quantity;
    }
    return total;
  }

  double get totalAmountYuan => totalAmount / 100.0;
}

/// 发票备注
class InvoiceRemark {
  final int createdBy;
  final int createdAt;
  final String content;

  const InvoiceRemark({
    required this.createdBy,
    required this.createdAt,
    required this.content,
  });

  factory InvoiceRemark.fromJson(Map<String, dynamic> json) {
    return InvoiceRemark(
      createdBy: json['createdBy'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      content: json['content'] as String? ?? '',
    );
  }

  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 发票
class Invoice {
  // === 列表页基础字段 ===
  final int invoiceID;
  final String? invoiceNumber;
  final InvoiceStatus status;
  final InvoiceType type;
  final UnitProperties unitProperties;
  final String? unitName;
  final String? taxNumber;
  final String? bankName;
  final String? bankAccount;
  final String? addressPhone;
  final int amount; // 分
  final int taxAmount; // 分
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final String? remarks;
  final String? orderNumbers;

  // === 详情页扩展字段 ===
  final int applicant; // 申请人 ident
  final int applyTime; // 申请时间
  final int department; // 申请部门
  final int? invoiceMaker; // 开票人
  final String invoiceHeader; // 发票抬头
  final String phone; // 联系电话
  final InvoiceMethod invoiceMethod; // 开票方式
  final int invoiceUsci; // 开票主体
  final String? email; // 邮箱
  final String? taxID; // 税号
  final String? companyAddress; // 公司地址
  final String? companyPhone; // 公司电话
  final String? openingBank; // 开户银行
  final String? bankAccountNumber; // 银行账号
  final List<String>? orderNumbersList; // 订单号列表
  final List<InvoiceOrderInfo> orderInfo; // 订单信息
  final int? totalDiscountAmount; // 订单实付总金额（分）
  final int invoiceAmount; // 订单开票金额（分）
  final List<InvoiceRemark> remarksList; // 备注列表
  final RedBlue redBlue; // 红字蓝字
  final List<String>? attachment; // 附件
  final int? lessAmount; // 少开金额（分）
  final int taxRate; // 适用税率
  final int? invoiceTime; // 开票日期

  const Invoice({
    required this.invoiceID,
    this.invoiceNumber,
    required this.status,
    required this.type,
    required this.unitProperties,
    this.unitName,
    this.taxNumber,
    this.bankName,
    this.bankAccount,
    this.addressPhone,
    required this.amount,
    required this.taxAmount,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.remarks,
    this.orderNumbers,
    this.applicant = 0,
    this.applyTime = 0,
    this.department = 0,
    this.invoiceMaker,
    this.invoiceHeader = '',
    this.phone = '',
    this.invoiceMethod = InvoiceMethod.self,
    this.invoiceUsci = 0,
    this.email,
    this.taxID,
    this.companyAddress,
    this.companyPhone,
    this.openingBank,
    this.bankAccountNumber,
    this.orderNumbersList,
    this.orderInfo = const [],
    this.totalDiscountAmount,
    this.invoiceAmount = 0,
    this.remarksList = const [],
    this.redBlue = RedBlue.blue,
    this.attachment,
    this.lessAmount,
    this.taxRate = 0,
    this.invoiceTime,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceID: json['id'] as int? ?? json['invoiceID'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String?,
      status: InvoiceStatus.fromValue(json['status'] as String?) ?? InvoiceStatus.noInvoice,
      type: InvoiceType.fromValue(json['invoiceType'] as String? ?? json['type'] as String?) ?? InvoiceType.paperGeneral,
      unitProperties: UnitProperties.fromValue(json['unitProperties'] as String?) ?? UnitProperties.company,
      unitName: json['invoiceHeader'] as String? ?? json['unitName'] as String?,
      taxNumber: json['taxID'] as String? ?? json['taxNumber'] as String?,
      bankName: json['openingBank'] as String? ?? json['bankName'] as String?,
      bankAccount: json['bankAccountNumber'] as String? ?? json['bankAccount'] as String?,
      addressPhone: json['companyPhone'] as String? ?? json['addressPhone'] as String?,
      amount: json['amount'] as int? ?? 0,
      taxAmount: json['taxAmount'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? json['applyTime'] as int? ?? 0,
      remarks: json['remarks'] as String?,
      orderNumbers: (json['orderNumbers'] is List)
          ? (json['orderNumbers'] as List).join(',')
          : json['orderNumbers'] as String?,

      // 扩展字段
      applicant: json['applicant'] as int? ?? 0,
      applyTime: json['applyTime'] as int? ?? 0,
      department: json['department'] as int? ?? 0,
      invoiceMaker: json['invoiceMaker'] as int?,
      invoiceHeader: json['invoiceHeader'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      invoiceMethod: InvoiceMethod.fromValue(json['invoiceMethod'] as String?) ?? InvoiceMethod.self,
      invoiceUsci: json['invoiceUsci'] as int? ?? 0,
      email: json['email'] as String?,
      taxID: json['taxID'] as String?,
      companyAddress: json['companyAddress'] as String?,
      companyPhone: json['companyPhone'] as String?,
      openingBank: json['openingBank'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      orderNumbersList: (json['orderNumbers'] is List)
          ? (json['orderNumbers'] as List).map((e) => e.toString()).toList()
          : null,
      orderInfo: (json['orderInfo'] as List<dynamic>?)
              ?.map((e) => InvoiceOrderInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDiscountAmount: json['totalDiscountAmount'] as int?,
      invoiceAmount: json['invoiceAmount'] as int? ?? 0,
      remarksList: (json['remarks'] is List)
          ? (json['remarks'] as List)
              .map((e) => InvoiceRemark.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      redBlue: RedBlue.fromValue(json['redBlue'] as String?) ?? RedBlue.blue,
      attachment: (json['attachment'] as List<dynamic>?)?.map((e) => e as String).toList(),
      lessAmount: json['lessAmount'] as int?,
      taxRate: json['taxRate'] as int? ?? 0,
      invoiceTime: json['invoiceTime'] as int?,
    );
  }

  // 兼容列表页字段
  double get amountYuan => amount / 100.0;
  double get taxAmountYuan => taxAmount / 100.0;
  double get invoiceAmountYuan => invoiceAmount / 100.0;
  double get lessAmountYuan => (lessAmount ?? 0) / 100.0;

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String get formattedApplyTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(applyTime * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String get formattedInvoiceTime {
    if (invoiceTime == null || invoiceTime == 0) return '--';
    final dt = DateTime.fromMillisecondsSinceEpoch(invoiceTime! * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// ============================================================
/// 发票申请相关模型
/// ============================================================

/// 发票校验结果（有订单）
class InvoiceCheckResult {
  final int monthlyInvoicingAmount; // 月度开票余额（分）
  final int monthlyInvoicingQuantity; // 月度开票余量
  final List<InvoiceCheckOrderInfo> orderInfos; // 订单信息列表

  const InvoiceCheckResult({
    required this.monthlyInvoicingAmount,
    required this.monthlyInvoicingQuantity,
    required this.orderInfos,
  });

  factory InvoiceCheckResult.fromJson(Map<String, dynamic> json) {
    return InvoiceCheckResult(
      monthlyInvoicingAmount: json['monthlyInvoicingAmount'] as int? ?? 0,
      monthlyInvoicingQuantity: json['monthlyInvoicingQuantity'] as int? ?? 0,
      orderInfos: (json['orderInfos'] as List<dynamic>?)
              ?.map((e) => InvoiceCheckOrderInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get monthlyInvoicingAmountYuan => monthlyInvoicingAmount / 100.0;
}

/// 发票校验结果（无订单）
class InvoiceNoOrderCheckResult {
  final int monthlyInvoicingAmount; // 月度开票余额（分）
  final int monthlyInvoicingQuantity; // 月度开票余量

  const InvoiceNoOrderCheckResult({
    required this.monthlyInvoicingAmount,
    required this.monthlyInvoicingQuantity,
  });

  factory InvoiceNoOrderCheckResult.fromJson(Map<String, dynamic> json) {
    return InvoiceNoOrderCheckResult(
      monthlyInvoicingAmount: json['monthlyInvoicingAmount'] as int? ?? 0,
      monthlyInvoicingQuantity: json['monthlyInvoicingQuantity'] as int? ?? 0,
    );
  }

  double get monthlyInvoicingAmountYuan => monthlyInvoicingAmount / 100.0;
}

/// 无订单商品信息（用于申请表单）
class InvoiceNoOrderProduct {
  final String name;
  final int quantity;
  final int amount; // 分
  final List<String> attachment;

  const InvoiceNoOrderProduct({
    required this.name,
    required this.quantity,
    required this.amount,
    this.attachment = const [],
  });

  factory InvoiceNoOrderProduct.fromJson(Map<String, dynamic> json) {
    return InvoiceNoOrderProduct(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      attachment: (json['attachment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'amount': amount,
      'attachment': attachment,
    };
  }

  double get amountYuan => amount / 100.0;

  InvoiceNoOrderProduct copyWith({
    String? name,
    int? quantity,
    int? amount,
    List<String>? attachment,
  }) {
    return InvoiceNoOrderProduct(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      attachment: attachment ?? this.attachment,
    );
  }
}

/// 可开票订单信息（申请表单用）
class InvoiceCheckOrderInfo {
  final InvoiceOrderInfoDetail orderInfo;
  final String? mallOrderNumber; // 商城单号
  final List<InvoiceSkuProduct> productInfo; // 标品商品
  final List<InvoiceSkuProduct> itemInfo; // 非标商品
  final List<InvoiceSkuProduct> serviceInfo; // 服务

  const InvoiceCheckOrderInfo({
    required this.orderInfo,
    this.mallOrderNumber,
    this.productInfo = const [],
    this.itemInfo = const [],
    this.serviceInfo = const [],
  });

  factory InvoiceCheckOrderInfo.fromJson(Map<String, dynamic> json) {
    return InvoiceCheckOrderInfo(
      orderInfo: InvoiceOrderInfoDetail.fromJson(
          json['orderInfo'] as Map<String, dynamic>? ?? {}),
      mallOrderNumber: json['mallOrderNumber'] as String?,
      productInfo: (json['productInfo'] as List<dynamic>?)
              ?.map((e) => InvoiceSkuProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itemInfo: (json['itemInfo'] as List<dynamic>?)
              ?.map((e) => InvoiceSkuProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      serviceInfo: (json['serviceInfo'] as List<dynamic>?)
              ?.map((e) => InvoiceSkuProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 计算订单总金额
  int get totalAmount {
    int total = 0;
    for (final p in productInfo) {
      total += p.discountAmount;
    }
    for (final i in itemInfo) {
      total += i.discountAmount;
    }
    for (final s in serviceInfo) {
      total += s.discountAmount;
    }
    return total;
  }

  double get totalAmountYuan => totalAmount / 100.0;
}

/// 订单基本信息
class InvoiceOrderInfoDetail {
  final String genre; // 销售类型：店内/网销
  final String orderNumber; // 订单号
  final int discountAmount; // 实付金额（分）
  final int createdAt; // 创建时间
  final int? sellerIdent; // 营业员ident

  const InvoiceOrderInfoDetail({
    required this.genre,
    required this.orderNumber,
    required this.discountAmount,
    required this.createdAt,
    this.sellerIdent,
  });

  factory InvoiceOrderInfoDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceOrderInfoDetail(
      genre: json['genre'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      discountAmount: json['discountAmount'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      sellerIdent: json['sellerIdent'] as int?,
    );
  }

  double get discountAmountYuan => discountAmount / 100.0;

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool get isStore => genre == '店内';
}

/// 订单商品（标品/非标/服务）
class InvoiceSkuProduct {
  final int productID;
  final int? serviceID;
  final String? name;
  final int quantity;
  final int discountAmount; // 折后金额（分）
  final String orderNumber;

  const InvoiceSkuProduct({
    required this.productID,
    this.serviceID,
    this.name,
    required this.quantity,
    required this.discountAmount,
    required this.orderNumber,
  });

  factory InvoiceSkuProduct.fromJson(Map<String, dynamic> json) {
    return InvoiceSkuProduct(
      productID: json['productID'] as int? ?? 0,
      serviceID: json['serviceID'] as int?,
      name: json['name'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      discountAmount: json['discountAmount'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? '',
    );
  }

  double get discountAmountYuan => discountAmount / 100.0;
}

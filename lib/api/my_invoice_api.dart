import 'package:flutter/cupertino.dart';
import 'api_client.dart';

/// 我的发票 API（个人员工视角）
/// 对应后端 GET /invoice/my-list, /invoice/my-count, /invoice/detail
class MyInvoiceApi {
  final ApiClient _client = ApiClient();

  /// 我的发票列表
  /// GET /invoice/my-list
  Future<List<MyInvoice>> list({int? limit, int? offset}) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final res = await _client.get('/invoice/my-list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => MyInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 我的发票总数
  /// GET /invoice/my-count
  Future<int> count() async {
    final res = await _client.get('/invoice/my-count');
    return res.data['res'] as int? ?? 0;
  }

  /// 发票详情
  /// GET /invoice/detail?invoiceIDs=N
  Future<MyInvoiceDetail?> detail(int invoiceId) async {
    final res = await _client.get(
      '/invoice/detail',
      queryParameters: {'invoiceIDs': invoiceId.toString()},
    );
    final data = res.data['res'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return MyInvoiceDetail.fromJson(data.first as Map<String, dynamic>);
  }
}

/// 我的发票列表项
class MyInvoice {
  final int id;
  final String? invoiceNumber;
  final String invoiceHeader;
  final String invoiceType;
  final String status;
  final int invoiceAmount;
  final int applyTime;
  final String? email;
  final String? taxID;
  final String? openingBank;
  final String? bankAccountNumber;
  final String? companyPhone;
  final String? companyAddress;

  const MyInvoice({
    required this.id,
    this.invoiceNumber,
    required this.invoiceHeader,
    required this.invoiceType,
    required this.status,
    required this.invoiceAmount,
    required this.applyTime,
    this.email,
    this.taxID,
    this.openingBank,
    this.bankAccountNumber,
    this.companyPhone,
    this.companyAddress,
  });

  factory MyInvoice.fromJson(Map<String, dynamic> json) {
    return MyInvoice(
      id: json['id'] as int? ?? 0,
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceHeader: json['invoiceHeader'] as String? ?? '',
      invoiceType: json['invoiceType'] as String? ?? 'paper-general',
      status: json['status'] as String? ?? 'to-be-invoiced',
      invoiceAmount: json['invoiceAmount'] as int? ?? 0,
      applyTime: json['applyTime'] as int? ?? 0,
      email: json['email'] as String?,
      taxID: json['taxID'] as String?,
      openingBank: json['openingBank'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      companyPhone: json['companyPhone'] as String?,
      companyAddress: json['companyAddress'] as String?,
    );
  }

  String get formattedAmount => '¥${(invoiceAmount / 100).toStringAsFixed(2)}';

  String get formattedApplyTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(applyTime * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get invoiceTypeLabel => _invoiceTypeLabels[invoiceType] ?? '普通发票';
  String get statusLabel => _statusLabels[status] ?? status;

  static const Map<String, String> _invoiceTypeLabels = {
    'paper-general': '纸质普票',
    'elec-general': '电子普票',
    'paper-special': '纸质专票',
    'elec-special': '电子专票',
    'digital-elec-special': '数电票专用发票',
    'digital-elec-general': '数电票普通发票',
  };

  static const Map<String, String> _statusLabels = {
    'no-invoice': '未开票',
    'to-be-invoiced': '待开票',
    'invoiced': '已开票',
    'deprecated': '已废弃',
    'reverse': '红冲',
    'reversed': '被红冲',
    'cancel': '取消开票',
  };

  Color get statusColor {
    switch (status) {
      case 'to-be-invoiced':
        return const Color(0xFF007AFF);
      case 'invoiced':
        return const Color(0xFF34C759);
      case 'deprecated':
      case 'reverse':
      case 'reversed':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF007AFF);
    }
  }
}

/// 我的发票详情
class MyInvoiceDetail {
  final int id;
  final int applicant;
  final String? applicantName;
  final int department;
  final String? departmentName;
  final int applyTime;
  final String status;
  final String invoiceHeader;
  final String phone;
  final String unitProperties;
  final String invoiceMethod;
  final String invoiceType;
  final int invoiceUsci;
  final String? invoiceUsciName;
  final String? email;
  final String? taxID;
  final String? companyAddress;
  final String? companyPhone;
  final String? openingBank;
  final String? bankAccountNumber;
  final List<String>? orderNumbers;
  final List<MyInvoiceOrderInfo>? orderInfo;
  final int invoiceAmount;
  final List<MyInvoiceRemark>? remarks;
  final String? invoiceNumber;
  final int? invoiceTime;
  final String? redBlue;
  final List<String>? attachment;
  final int? lessAmount;

  const MyInvoiceDetail({
    required this.id,
    required this.applicant,
    this.applicantName,
    required this.department,
    this.departmentName,
    required this.applyTime,
    required this.status,
    required this.invoiceHeader,
    required this.phone,
    required this.unitProperties,
    required this.invoiceMethod,
    required this.invoiceType,
    required this.invoiceUsci,
    this.invoiceUsciName,
    this.email,
    this.taxID,
    this.companyAddress,
    this.companyPhone,
    this.openingBank,
    this.bankAccountNumber,
    this.orderNumbers,
    this.orderInfo,
    required this.invoiceAmount,
    this.remarks,
    this.invoiceNumber,
    this.invoiceTime,
    this.redBlue,
    this.attachment,
    this.lessAmount,
  });

  factory MyInvoiceDetail.fromJson(Map<String, dynamic> json) {
    return MyInvoiceDetail(
      id: json['id'] as int? ?? 0,
      applicant: json['applicant'] as int? ?? 0,
      applicantName: json['applicantName'] as String?,
      department: json['department'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      applyTime: json['applyTime'] as int? ?? 0,
      status: json['status'] as String? ?? 'to-be-invoiced',
      invoiceHeader: json['invoiceHeader'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      unitProperties: json['unitProperties'] as String? ?? 'company',
      invoiceMethod: json['invoiceMethod'] as String? ?? 'self',
      invoiceType: json['invoiceType'] as String? ?? 'paper-general',
      invoiceUsci: json['invoiceUsci'] as int? ?? 0,
      invoiceUsciName: json['invoiceUsciName'] as String?,
      email: json['email'] as String?,
      taxID: json['taxID'] as String?,
      companyAddress: json['companyAddress'] as String?,
      companyPhone: json['companyPhone'] as String?,
      openingBank: json['openingBank'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      orderNumbers: (json['orderNumbers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      orderInfo: (json['orderInfo'] as List<dynamic>?)
          ?.map((e) => MyInvoiceOrderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      invoiceAmount: json['invoiceAmount'] as int? ?? 0,
      remarks: (json['remarks'] as List<dynamic>?)
          ?.map((e) => MyInvoiceRemark.fromJson(e as Map<String, dynamic>))
          .toList(),
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceTime: json['invoiceTime'] as int?,
      redBlue: json['redBlue'] as String?,
      attachment: (json['attachment'] as List<dynamic>?)?.map((e) => e as String).toList(),
      lessAmount: json['lessAmount'] as int?,
    );
  }

  String get formattedApplyTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(applyTime * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedInvoiceAmount => '¥${(invoiceAmount / 100).toStringAsFixed(2)}';

  String get statusLabel => _statusLabels[status] ?? status;

  String get invoiceTypeLabel {
    return const {
      'paper-general': '纸质普票',
      'elec-general': '电子普票',
      'paper-special': '纸质专票',
      'elec-special': '电子专票',
      'digital-elec-special': '数电票专用发票',
      'digital-elec-general': '数电票普通发票',
    }[invoiceType] ?? '普通发票';
  }

  String get unitPropertiesLabel =>
      unitProperties == 'personal' ? '个人' : '企业';

  String get invoiceMethodLabel =>
      invoiceMethod == 'self' ? '自开' : '代开';

  static const Map<String, String> _statusLabels = {
    'no-invoice': '未开票',
    'to-be-invoiced': '待开票',
    'invoiced': '已开票',
    'deprecated': '已废弃',
    'reverse': '红冲',
    'reversed': '被红冲',
    'cancel': '取消开票',
  };
}

/// 发票订单信息
class MyInvoiceOrderInfo {
  final String orderNumber;
  final List<MyInvoiceSku>? skus;
  final List<MyInvoiceSku>? items;
  final List<MyInvoiceSku>? services;
  final List<MyInvoiceNoOrder>? noOrder;

  const MyInvoiceOrderInfo({
    required this.orderNumber,
    this.skus,
    this.items,
    this.services,
    this.noOrder,
  });

  factory MyInvoiceOrderInfo.fromJson(Map<String, dynamic> json) {
    return MyInvoiceOrderInfo(
      orderNumber: json['orderNumber'] as String? ?? '',
      skus: (json['skus'] as List<dynamic>?)
          ?.map((e) => MyInvoiceSku.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MyInvoiceSku.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => MyInvoiceSku.fromJson(e as Map<String, dynamic>))
          .toList(),
      noOrder: (json['noOrder'] as List<dynamic>?)
          ?.map((e) => MyInvoiceNoOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MyInvoiceSku {
  final int skuID;
  final String name;
  final int quantity;
  final int amount;

  const MyInvoiceSku({
    required this.skuID,
    required this.name,
    required this.quantity,
    required this.amount,
  });

  factory MyInvoiceSku.fromJson(Map<String, dynamic> json) {
    return MyInvoiceSku(
      skuID: json['skuID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }

  String get formattedAmount => '¥${(amount / 100).toStringAsFixed(2)}';
}

class MyInvoiceNoOrder {
  final String name;
  final int quantity;
  final int amount;
  final List<String>? attachment;

  const MyInvoiceNoOrder({
    required this.name,
    required this.quantity,
    required this.amount,
    this.attachment,
  });

  factory MyInvoiceNoOrder.fromJson(Map<String, dynamic> json) {
    return MyInvoiceNoOrder(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      attachment: (json['attachment'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  String get formattedAmount => '¥${(amount / 100).toStringAsFixed(2)}';
}

class MyInvoiceRemark {
  final int createdBy;
  final String? createdByName;
  final int createdAt;
  final String content;

  const MyInvoiceRemark({
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.content,
  });

  factory MyInvoiceRemark.fromJson(Map<String, dynamic> json) {
    return MyInvoiceRemark(
      createdBy: json['createdBy'] as int? ?? 0,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      content: json['content'] as String? ?? '',
    );
  }

  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/cupertino.dart';
import 'package:z1_app/api/api_client.dart';

/// 支付记录附件 API
/// 对应后端 /payment-detail/*
class PaymentDetailApi {
  final ApiClient _client = ApiClient();

  /// 获取支付记录附件列表
  /// GET /payment-detail/attach-list
  Future<List<PaymentAttachRecord>> getAttachList({
    List<String>? orderStatus,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? paymentTypeIDs,
    List<String>? mallOrderNumbers,
    String? phone,
    List<int>? sellerIdents,
    List<int>? departmentIDs,
    List<String>? attachState,
    int limit = 10,
    int offset = 0,
    String orderBy = 'created_at',
    String sort = 'DESC',
  }) async {
    final params = <String, dynamic>{
      if (orderStatus != null && orderStatus.isNotEmpty)
        'orderStatus': orderStatus,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (paymentTypeIDs != null && paymentTypeIDs.isNotEmpty)
        'paymentTypeIDs': paymentTypeIDs,
      if (mallOrderNumbers != null && mallOrderNumbers.isNotEmpty)
        'mallOrderNumbers': mallOrderNumbers,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (sellerIdents != null && sellerIdents.isNotEmpty)
        'sellerIdents': sellerIdents,
      if (departmentIDs != null && departmentIDs.isNotEmpty)
        'departmentIDs': departmentIDs,
      if (attachState != null && attachState.isNotEmpty)
        'attachState': attachState,
      'offset': offset,
      'limit': limit,
      'orderBy': orderBy,
      'sort': sort,
    };

    final response = await _client.get(
      '/payment-detail/attach-list',
      queryParameters: params,
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => PaymentAttachRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取支付记录附件列表总数
  /// GET /payment-detail/attach-count
  Future<int> getAttachCount({
    List<String>? orderStatus,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? paymentTypeIDs,
    List<String>? mallOrderNumbers,
    String? phone,
    List<int>? sellerIdents,
    List<int>? departmentIDs,
    List<String>? attachState,
  }) async {
    final params = <String, dynamic>{
      if (orderStatus != null && orderStatus.isNotEmpty)
        'orderStatus': orderStatus,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (paymentTypeIDs != null && paymentTypeIDs.isNotEmpty)
        'paymentTypeIDs': paymentTypeIDs,
      if (mallOrderNumbers != null && mallOrderNumbers.isNotEmpty)
        'mallOrderNumbers': mallOrderNumbers,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (sellerIdents != null && sellerIdents.isNotEmpty)
        'sellerIdents': sellerIdents,
      if (departmentIDs != null && departmentIDs.isNotEmpty)
        'departmentIDs': departmentIDs,
      if (attachState != null && attachState.isNotEmpty)
        'attachState': attachState,
    };

    final response = await _client.get(
      '/payment-detail/attach-count',
      queryParameters: params,
    );
    return response.data['res'] as int? ?? 0;
  }

  /// 根据编号获取支付详情
  /// GET /payment/detail/number?number=xxx
  Future<PaymentDetailInfo> getDetailByNumber(String paymentDetailNumber) async {
    final response = await _client.get(
      '/payment/detail/number',
      queryParameters: {'number': paymentDetailNumber},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    if (data.isEmpty) throw Exception('支付记录不存在');
    return PaymentDetailInfo.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 修改支付记录附件状态（审核通过/驳回）
  /// POST /payment-detail/attach-state-update
  Future<bool> updateAttachState({
    required List<String> paymentDetailNumbers,
    required String attachState,
    String? remarks,
  }) async {
    final response = await _client.post(
      '/payment-detail/attach-state-update',
      data: {
        'paymentDetailNumber': paymentDetailNumbers,
        'attachState': attachState,
        if (remarks != null) 'remarks': remarks,
      },
    );
    return response.data['res'] == true;
  }

  /// 获取支付方式列表
  /// GET /payment-type/list
  Future<List<PaymentTypeInfo>> getPaymentTypeList({List<int>? paymentTypeIDs}) async {
    final params = <String, dynamic>{
      if (paymentTypeIDs != null && paymentTypeIDs.isNotEmpty)
        'paymentTypeIDs': paymentTypeIDs,
      'offset': 0,
      'limit': 100,
    };
    final response = await _client.get(
      '/payment-type/list',
      queryParameters: params,
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => PaymentTypeInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 支付记录附件列表项
class PaymentAttachRecord {
  final String paymentDetailNumber;
  final String mallOrderNumber;
  final String? phone;
  final int paymentTypeID;
  final String? attachState;
  final int? createdAt;

  PaymentAttachRecord({
    required this.paymentDetailNumber,
    required this.mallOrderNumber,
    this.phone,
    required this.paymentTypeID,
    this.attachState,
    this.createdAt,
  });

  factory PaymentAttachRecord.fromJson(Map<String, dynamic> json) {
    return PaymentAttachRecord(
      paymentDetailNumber: json['paymentDetailNumber'] as String? ?? '',
      mallOrderNumber: json['mallOrderNumber'] as String? ?? '',
      phone: json['phone'] as String?,
      paymentTypeID: json['paymentTypeID'] as int? ?? 0,
      attachState: json['attachState'] as String?,
      createdAt: json['createdAt'] as int?,
    );
  }

  /// 附件状态文本
  String get attachStateLabel {
    switch (attachState) {
      case 'wait':
        return '待上传';
      case 'not_required':
        return '不需要审核';
      case 'pending':
        return '待审核';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已驳回';
      default:
        return '未知';
    }
  }

  Color get attachStateColor {
    switch (attachState) {
      case 'wait':
        return const Color(0xFFFF9500);
      case 'not_required':
        return const Color(0xFF8E8E93);
      case 'pending':
        return const Color(0xFFBF5AF2);
      case 'approved':
        return const Color(0xFF30D158);
      case 'rejected':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}

/// 支付详情信息
class PaymentDetailInfo {
  final int paymentDetailID;
  final String paymentDetailNumber;
  final String orderNumber;
  final int paymentTypeID;
  final int amount;
  final String status;
  final String? platformNumber;
  final String? remarks;
  final int? fees;
  final int? createdBy;
  final int? createdAt;
  final PaymentDetailAssociated? associated;
  final List<String>? images;
  final List<PaymentAttachment>? attachments;
  final int? departmentID;
  final String? posClientNumber;
  final String? attachState;

  PaymentDetailInfo({
    required this.paymentDetailID,
    required this.paymentDetailNumber,
    required this.orderNumber,
    required this.paymentTypeID,
    required this.amount,
    required this.status,
    this.platformNumber,
    this.remarks,
    this.fees,
    this.createdBy,
    this.createdAt,
    this.associated,
    this.images,
    this.attachments,
    this.departmentID,
    this.posClientNumber,
    this.attachState,
  });

  factory PaymentDetailInfo.fromJson(Map<String, dynamic> json) {
    return PaymentDetailInfo(
      paymentDetailID: json['paymentDetailID'] as int? ?? 0,
      paymentDetailNumber: json['paymentDetailNumber'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      paymentTypeID: json['paymentTypeID'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      platformNumber: json['platformNumber'] as String?,
      remarks: json['remarks'] as String?,
      fees: json['fees'] as int?,
      createdBy: json['createdBy'] as int?,
      createdAt: json['createdAt'] as int?,
      associated: json['associated'] != null
          ? PaymentDetailAssociated.fromJson(json['associated'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => PaymentAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      departmentID: json['departmentID'] as int?,
      posClientNumber: json['posClientNumber'] as String?,
      attachState: json['attachState'] as String?,
    );
  }

  /// 附件状态文本
  String get attachStateLabel {
    switch (attachState) {
      case 'wait':
        return '待上传';
      case 'not_required':
        return '不需要审核';
      case 'pending':
        return '待审核';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已驳回';
      default:
        return '未知';
    }
  }

  Color get attachStateColor {
    switch (attachState) {
      case 'wait':
        return const Color(0xFFFF9500);
      case 'not_required':
        return const Color(0xFF8E8E93);
      case 'pending':
        return const Color(0xFFBF5AF2);
      case 'approved':
        return const Color(0xFF30D158);
      case 'rejected':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}

/// 支付关联信息
class PaymentDetailAssociated {
  final String? gmall;
  final String? payNumber;
  final int? cashierDailyReport;
  final String? preOrder;
  final String? flashOrder;
  final int? createdAt;
  final String? pointsRedeemOrder;

  PaymentDetailAssociated({
    this.gmall,
    this.payNumber,
    this.cashierDailyReport,
    this.preOrder,
    this.flashOrder,
    this.createdAt,
    this.pointsRedeemOrder,
  });

  factory PaymentDetailAssociated.fromJson(Map<String, dynamic> json) {
    return PaymentDetailAssociated(
      gmall: json['gmall'] as String?,
      payNumber: json['payNumber'] as String?,
      cashierDailyReport: json['cashierDailyReport'] as int?,
      preOrder: json['preOrder'] as String?,
      flashOrder: json['flashOrder'] as String?,
      createdAt: json['createdAt'] as int?,
      pointsRedeemOrder: json['pointsRedeemOrder'] as String?,
    );
  }
}

/// 支付附件
class PaymentAttachment {
  final String id;
  final List<String> value;

  PaymentAttachment({required this.id, required this.value});

  factory PaymentAttachment.fromJson(Map<String, dynamic> json) {
    return PaymentAttachment(
      id: json['id'] as String? ?? '',
      value: (json['value'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// 支付方式信息
class PaymentTypeInfo {
  final int id;
  final String name;
  final String spell;
  final int rate;
  final String? state;
  final String? remarks;
  final int? createdAt;
  final int? updatedAt;
  final int? cateID;
  final int? maxFees;
  final int? account;
  final int? advanceAccount;
  final int? rateAccount;
  final int? platform;
  final bool? isExemption;
  final bool? isRemarks;
  final bool? isAttachAudit;

  PaymentTypeInfo({
    required this.id,
    required this.name,
    required this.spell,
    required this.rate,
    this.state,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.cateID,
    this.maxFees,
    this.account,
    this.advanceAccount,
    this.rateAccount,
    this.platform,
    this.isExemption,
    this.isRemarks,
    this.isAttachAudit,
  });

  factory PaymentTypeInfo.fromJson(Map<String, dynamic> json) {
    return PaymentTypeInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      spell: json['spell'] as String? ?? '',
      rate: json['rate'] as int? ?? 0,
      state: json['state'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt'] as int?,
      cateID: json['cateID'] as int?,
      maxFees: json['maxFees'] as int?,
      account: json['account'] as int?,
      advanceAccount: json['advanceAccount'] as int?,
      rateAccount: json['rateAccount'] as int?,
      platform: json['platform'] as int?,
      isExemption: json['isExemption'] as bool?,
      isRemarks: json['isRemarks'] as bool?,
      isAttachAudit: json['isAttachAudit'] as bool?,
    );
  }
}

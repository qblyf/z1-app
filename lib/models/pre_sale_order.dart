import 'package:equatable/equatable.dart';

/// 预售订单状态
enum PreSaleOrderStatus {
  unpaid('unpaid', '未支付'),
  paid('paid', '已支付'),
  completed('completed', '已完成'),
  applyRefund('apply-refund', '申请退款'),
  refunded('refunded', '已退款'),
  canceled('canceled', '已取消');

  const PreSaleOrderStatus(this.value, this.label);
  final String value;
  final String label;

  static PreSaleOrderStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 预售订单支付信息
class PreSaleOrderPayment extends Equatable {
  final String platform;
  final String content;

  const PreSaleOrderPayment({
    required this.platform,
    required this.content,
  });

  factory PreSaleOrderPayment.fromJson(Map<String, dynamic> json) {
    return PreSaleOrderPayment(
      platform: json['platform'] as String? ?? 'wx',
      content: json['content'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [platform, content];
}

/// 预售订单模型
class PreSaleOrder extends Equatable {
  final int id;
  /// 订单编号
  final String number;
  /// 预订人
  final int customer;
  /// 预订部门
  final int? department;
  /// 预订活动ID
  final int activity;
  /// 预售活动中的商品ID
  final int activityProduct;
  /// 预定金额（分）
  final int amount;
  /// 膨胀金额（分）
  final int expandAmount;
  /// 预订的商品（转商城订单的前提）
  final int? preSaleProduct;
  /// 捆绑销售的商品
  final List<int> products;
  /// 捆绑销售的服务
  final List<int> services;
  /// 商城订单号
  final String? mallOrderNumber;
  /// 状态
  final String status;
  /// 支付信息
  final PreSaleOrderPayment? payment;
  /// 备注
  final String? remarks;
  /// 职员备注
  final String? emplRemarks;
  /// 支付时间
  final int? payAt;
  /// 转订单时间
  final int? toOrderAt;
  /// 创建时间
  final int createdAt;
  /// 创建人
  final int createdBy;
  /// 更新时间
  final int updatedAt;
  /// 更新人
  final int updatedBy;
  /// 退款原因
  final String? refundReason;
  /// 分享人
  final int? sharer;
  /// 是否锁货
  final bool? isLockSku;
  /// 描述信息（活动名称等）
  final String? describe;

  const PreSaleOrder({
    required this.id,
    required this.number,
    required this.customer,
    this.department,
    required this.activity,
    required this.activityProduct,
    required this.amount,
    required this.expandAmount,
    this.preSaleProduct,
    this.products = const [],
    this.services = const [],
    this.mallOrderNumber,
    required this.status,
    this.payment,
    this.remarks,
    this.emplRemarks,
    this.payAt,
    this.toOrderAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.refundReason,
    this.sharer,
    this.isLockSku,
    this.describe,
  });

  factory PreSaleOrder.fromJson(Map<String, dynamic> json) {
    return PreSaleOrder(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      customer: json['customer'] as int? ?? 0,
      department: json['department'] as int?,
      activity: json['activity'] as int? ?? 0,
      activityProduct: json['activityProduct'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      expandAmount: json['expandAmount'] as int? ?? 0,
      preSaleProduct: json['preSaleProduct'] as int?,
      products: (json['products'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      services: (json['services'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      mallOrderNumber: json['mallOrderNumber'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      payment: json['payment'] != null
          ? PreSaleOrderPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      remarks: json['remarks'] as String?,
      emplRemarks: json['emplRemarks'] as String?,
      payAt: json['payAt'] as int?,
      toOrderAt: json['toOrderAt'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      refundReason: json['refundReason'] as String?,
      sharer: json['sharer'] as int?,
      isLockSku: json['isLockSku'] as bool?,
      describe: json['describe'] as String?,
    );
  }

  /// 状态枚举对象
  PreSaleOrderStatus? get statusEnum => PreSaleOrderStatus.fromValue(status);

  /// 状态显示文本
  String get statusLabel => statusEnum?.label ?? status;

  /// 格式化金额（分转元）
  String get amountYuan => (amount / 100).toStringAsFixed(2);

  /// 膨胀后金额
  String get totalAmountYuan => ((amount + expandAmount) / 100).toStringAsFixed(2);

  /// 是否已支付
  bool get isPaid =>
      status != PreSaleOrderStatus.unpaid.value &&
      status != PreSaleOrderStatus.canceled.value;

  /// 是否已处理（已支付且有商城单号）
  bool get isProcessed =>
      status == PreSaleOrderStatus.paid.value && mallOrderNumber != null;

  /// 是否可以转购买（已支付但无商城单）
  bool get canBuy =>
      status == PreSaleOrderStatus.paid.value && mallOrderNumber == null;

  @override
  List<Object?> get props => [
        id,
        number,
        customer,
        department,
        activity,
        activityProduct,
        amount,
        expandAmount,
        preSaleProduct,
        products,
        services,
        mallOrderNumber,
        status,
        payment,
        remarks,
        emplRemarks,
        payAt,
        toOrderAt,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        refundReason,
        sharer,
        isLockSku,
        describe,
      ];
}

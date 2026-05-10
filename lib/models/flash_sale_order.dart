import 'package:equatable/equatable.dart';

/// 秒杀订单状态
enum FlashSaleOrderStatus {
  unpaid('unpaid', '未支付'),
  completed('completed', '已完成'),
  canceled('canceled', '已取消'),
  applyRefund('apply-refund', '申请退款'),
  refunded('refunded', '已退款');

  const FlashSaleOrderStatus(this.value, this.label);
  final String value;
  final String label;

  static FlashSaleOrderStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 秒杀订单支付信息
class FlashSaleOrderPayment extends Equatable {
  final String platform;
  final String content;

  const FlashSaleOrderPayment({
    required this.platform,
    required this.content,
  });

  factory FlashSaleOrderPayment.fromJson(Map<String, dynamic> json) {
    return FlashSaleOrderPayment(
      platform: json['platform'] as String? ?? 'wx',
      content: json['content'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [platform, content];
}

/// 秒杀订单模型
class FlashSaleOrder extends Equatable {
  final int id;
  /// 订单编号
  final String number;
  /// 活动ID
  final int activity;
  /// 秒杀活动商品ID
  final int activityProduct;
  /// skuID
  final int skuId;
  /// 顾客标识符
  final int customer;
  /// 配送方式
  final String? transport;
  /// 自提部门或邮寄发货部门
  final int department;
  /// 金额（分）
  final int amount;
  /// 生成的商城订单号
  final String? mallOrder;
  /// 状态
  final String status;
  /// 备注
  final String? remarks;
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
  /// 支付信息
  final FlashSaleOrderPayment? payment;
  /// 退款原因
  final String? refundReason;
  /// 分享人
  final int? sharer;

  const FlashSaleOrder({
    required this.id,
    required this.number,
    required this.activity,
    required this.activityProduct,
    required this.skuId,
    required this.customer,
    this.transport,
    required this.department,
    required this.amount,
    this.mallOrder,
    required this.status,
    this.remarks,
    this.payAt,
    this.toOrderAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.payment,
    this.refundReason,
    this.sharer,
  });

  factory FlashSaleOrder.fromJson(Map<String, dynamic> json) {
    return FlashSaleOrder(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      activity: json['activity'] as int? ?? 0,
      activityProduct: json['activityProduct'] as int? ?? 0,
      skuId: json['skuID'] as int? ?? 0,
      customer: json['customer'] as int? ?? 0,
      transport: json['transport'] as String?,
      department: json['department'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      mallOrder: json['mallOrder'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      remarks: json['remarks'] as String?,
      payAt: json['payAt'] as int?,
      toOrderAt: json['toOrderAt'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      payment: json['payment'] != null
          ? FlashSaleOrderPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      refundReason: json['refundReason'] as String?,
      sharer: json['sharer'] as int?,
    );
  }

  /// 状态枚举对象
  FlashSaleOrderStatus? get statusEnum => FlashSaleOrderStatus.fromValue(status);

  /// 状态显示文本
  String get statusLabel => statusEnum?.label ?? status;

  /// 格式化金额（分转元）
  String get amountYuan => (amount / 100).toStringAsFixed(2);

  /// 是否已支付（除未支付和已取消外都是已支付）
  bool get isPaid =>
      status != FlashSaleOrderStatus.unpaid.value &&
      status != FlashSaleOrderStatus.canceled.value;

  /// 是否可以处理（已完成但未转商城单）
  bool get canProcess =>
      status == FlashSaleOrderStatus.completed.value && mallOrder == null;

  /// 是否可以退款（申请退款状态）
  bool get canRefund =>
      status == FlashSaleOrderStatus.applyRefund.value;

  @override
  List<Object?> get props => [
        id,
        number,
        activity,
        activityProduct,
        skuId,
        customer,
        transport,
        department,
        amount,
        mallOrder,
        status,
        remarks,
        payAt,
        toOrderAt,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        payment,
        refundReason,
        sharer,
      ];
}

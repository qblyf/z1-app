/// 积分兑换订单状态
enum PointsRedeemOrderStatus {
  unpaid('unpaid', '未支付'),
  paid('paid', '已支付'),
  completed('completed', '已完成'),
  expired('expired', '已过期'),
  applyForRefund('apply-for-refund', '申请退款'),
  refunded('refunded', '已退款');

  const PointsRedeemOrderStatus(this.value, this.label);
  final String value;
  final String label;

  static PointsRedeemOrderStatus? fromValue(String? v) {
    if (v == null) return null;
    return PointsRedeemOrderStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => PointsRedeemOrderStatus.unpaid,
    );
  }
}

/// 配送方式
enum RedeemTransportType {
  selfPickup('selfPickup', '自提'),
  delivery('delivery', '配送');

  const RedeemTransportType(this.value, this.label);
  final String value;
  final String label;

  static RedeemTransportType? fromValue(String? v) {
    if (v == null) return null;
    return RedeemTransportType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => RedeemTransportType.selfPickup,
    );
  }
}

/// 积分兑换订单
class PointsRedeemOrder {
  final int id;
  final String number;
  final int productItemId;
  final int? skuId;
  final int? serviceId;
  final int customer;
  final int points;
  final int? payAmountCents;
  final RedeemTransportType transport;
  final int? postAmountCents;
  final int? departmentId;
  final String? mallOrderNumber;
  final int? completeAt;
  final List<PointsRedeemRemark> remarks;
  final PointsRedeemOrderStatus status;
  final int createdBy;
  final int createdAt;
  final int updatedBy;
  final int updatedAt;

  const PointsRedeemOrder({
    required this.id,
    required this.number,
    required this.productItemId,
    this.skuId,
    this.serviceId,
    required this.customer,
    required this.points,
    this.payAmountCents,
    required this.transport,
    this.postAmountCents,
    this.departmentId,
    this.mallOrderNumber,
    this.completeAt,
    required this.remarks,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  factory PointsRedeemOrder.fromJson(Map<String, dynamic> json) {
    return PointsRedeemOrder(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      productItemId: json['productItem'] as int? ?? 0,
      skuId: json['sku'] as int?,
      serviceId: json['service'] as int?,
      customer: json['customer'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      payAmountCents: json['payAmount'] as int?,
      transport: RedeemTransportType.fromValue(json['transport'] as String?) ?? RedeemTransportType.selfPickup,
      postAmountCents: json['postAmount'] as int?,
      departmentId: json['department'] as int?,
      mallOrderNumber: json['mallOrderNumber'] as String?,
      completeAt: json['completeAt'] as int?,
      remarks: (json['remarks'] as List?)
              ?.map((e) => PointsRedeemRemark.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: PointsRedeemOrderStatus.fromValue(json['status'] as String?) ?? PointsRedeemOrderStatus.unpaid,
      createdBy: json['createdBy'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }
}

/// 订单备注
class PointsRedeemRemark {
  final int employee;
  final String remarks;
  final int createdAt;

  const PointsRedeemRemark({
    required this.employee,
    required this.remarks,
    required this.createdAt,
  });

  factory PointsRedeemRemark.fromJson(Map<String, dynamic> json) {
    return PointsRedeemRemark(
      employee: json['employee'] as int? ?? 0,
      remarks: json['remarks'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }
}

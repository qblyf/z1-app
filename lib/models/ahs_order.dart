/// 爱回收(AHS)回收单状态
enum AhsOrderStatus {
  /// 待处理
  pending(0),
  /// 已取消
  cancelled(1),
  /// 已完成
  completed(2),
  /// 验机中
  checking(3),
  /// 已上架
  listed(4),
  /// 已售出
  sold(5);

  const AhsOrderStatus(this.value);
  final int value;

  static AhsOrderStatus? fromValue(dynamic value) {
    if (value == null) return null;
    for (final s in AhsOrderStatus.values) {
      if (s.value == value) return s;
    }
    return null;
  }

  String get label {
    switch (this) {
      case AhsOrderStatus.pending:
        return '待处理';
      case AhsOrderStatus.cancelled:
        return '已取消';
      case AhsOrderStatus.completed:
        return '已完成';
      case AhsOrderStatus.checking:
        return '验机中';
      case AhsOrderStatus.listed:
        return '已上架';
      case AhsOrderStatus.sold:
        return '已售出';
    }
  }
}

/// 爱回收(AHS)回收单详情
class AhsOrder {
  final String? orderNumber;
  final int? userIdent;
  final AhsOrderStatus? status;
  final int? emplIdent;
  final int? createdAt;
  final int? departmentId;
  final String? skuName;
  final List<AhsSkuSpec>? skuSpec;
  final String? serial;
  final int? finalPrice;
  final List<String>? imeis;

  AhsOrder({
    this.orderNumber,
    this.userIdent,
    this.status,
    this.emplIdent,
    this.createdAt,
    this.departmentId,
    this.skuName,
    this.skuSpec,
    this.serial,
    this.finalPrice,
    this.imeis,
  });

  factory AhsOrder.fromJson(Map<String, dynamic> json) {
    return AhsOrder(
      orderNumber: json['number'] ?? json['orderNumber'],
      userIdent: json['userIdent'] ?? json['user_ident'],
      status: AhsOrderStatus.fromValue(json['status']),
      emplIdent: json['emplIdent'] ?? json['empl_ident'],
      createdAt: json['createdAt'] ?? json['created_at'],
      departmentId: json['departmentID'] ?? json['department_id'],
      skuName: json['skuName'] ?? json['sku_name'],
      skuSpec: (json['skuSpec'] as List?)
          ?.map((e) => AhsSkuSpec.fromJson(e))
          .toList(),
      serial: json['serial'],
      finalPrice: json['finalPrice'] ?? json['final_price'],
      imeis: (json['imeis'] as List?)?.cast<String>(),
    );
  }
}

/// AHS 商品规格
class AhsSkuSpec {
  final String? specId;
  final String? specName;
  final String? valueId;
  final String? valueName;

  AhsSkuSpec({
    this.specId,
    this.specName,
    this.valueId,
    this.valueName,
  });

  factory AhsSkuSpec.fromJson(Map<String, dynamic> json) {
    return AhsSkuSpec(
      specId: json['specId'],
      specName: json['specName'],
      valueId: json['valueId'],
      valueName: json['valueName'],
    );
  }
}

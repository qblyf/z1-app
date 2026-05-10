/// 标准价格调整单

/// 调价单状态
enum PriceAdjustmentState {
  normal(1, '已审核', 0xFF30D158),
  undetermined(2, '待审核', 0xFFFF9500),
  draft(3, '草稿', 0xFF8E8E93),
  reject(4, '已拒绝', 0xFFFF3B30);

  const PriceAdjustmentState(this.value, this.label, this.colorValue);
  final int value;
  final String label;
  final int colorValue;

  static PriceAdjustmentState? fromValue(int? v) {
    if (v == null) return null;
    return PriceAdjustmentState.values.firstWhere(
      (e) => e.value == v,
      orElse: () => PriceAdjustmentState.draft,
    );
  }
}

/// 调价单类型
enum PriceAdjustmentType {
  self(1, '自主调价'),
  advice(2, '供应商调价');

  const PriceAdjustmentType(this.value, this.label);
  final int value;
  final String label;

  static PriceAdjustmentType? fromValue(int? v) {
    if (v == null) return null;
    return PriceAdjustmentType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => PriceAdjustmentType.self,
    );
  }
}

/// 调整项
class AdjustmentInfo {
  final int? stock;
  final int costPrice;
  final int? productId;
  final int? nonGoodsId;
  final int? beforeCostPrice;
  final int? limitPrice;
  final int? productPrice;

  AdjustmentInfo({
    this.stock,
    required this.costPrice,
    this.productId,
    this.nonGoodsId,
    this.beforeCostPrice,
    this.limitPrice,
    this.productPrice,
  });

  factory AdjustmentInfo.fromJson(Map<String, dynamic> json) {
    return AdjustmentInfo(
      stock: json['stock'] as int?,
      costPrice: json['costPrice'] as int? ?? 0,
      productId: json['productID'] as int?,
      nonGoodsId: json['nonGoodsID'] as int?,
      beforeCostPrice: json['beforeCostPrice'] as int?,
      limitPrice: json['limitPrice'] as int?,
      productPrice: json['productPrice'] as int?,
    );
  }
}

/// 调价单
class PriceAdjustment {
  final int priceAdjustmentId;
  final String number;
  final List<AdjustmentInfo>? adjustmentInfo;
  final int? departmentId;
  final PriceAdjustmentState status;
  final PriceAdjustmentType type;
  final int? createdByIdent;
  final int? createdAt;
  final int? updatedByIdent;
  final int? updatedAt;
  final List<int>? allowedAuditors;
  final int? auditorIdent;
  final int? auditorAt;
  final String? docRemarks;
  final String? remarks;

  PriceAdjustment({
    required this.priceAdjustmentId,
    required this.number,
    this.adjustmentInfo,
    this.departmentId,
    required this.status,
    required this.type,
    this.createdByIdent,
    this.createdAt,
    this.updatedByIdent,
    this.updatedAt,
    this.allowedAuditors,
    this.auditorIdent,
    this.auditorAt,
    this.docRemarks,
    this.remarks,
  });

  factory PriceAdjustment.fromJson(Map<String, dynamic> json) {
    return PriceAdjustment(
      priceAdjustmentId: json['priceAdjustmentID'] as int,
      number: json['number'] as String? ?? '',
      adjustmentInfo: (json['adjustmentInfo'] as List?)
          ?.map((e) => AdjustmentInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      departmentId: json['departmentID'] as int?,
      status: PriceAdjustmentState.fromValue(json['status'] as int?) ?? PriceAdjustmentState.draft,
      type: PriceAdjustmentType.fromValue(json['type'] as int?) ?? PriceAdjustmentType.self,
      createdByIdent: json['createdByIdent'] as int?,
      createdAt: json['createdAt'] as int?,
      updatedByIdent: json['updatedByIdent'] as int?,
      updatedAt: json['updatedAt'] as int?,
      allowedAuditors: (json['allowedAuditors'] as List?)?.cast<int>(),
      auditorIdent: json['auditorIdent'] as int?,
      auditorAt: json['auditorAt'] as int?,
      docRemarks: json['docRemarks'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  /// 计算调价损失合计（分）
  int get totalLossCents {
    if (adjustmentInfo == null) return 0;
    return adjustmentInfo!.where((e) => e.beforeCostPrice != null).fold(0, (sum, e) {
      final diff = e.beforeCostPrice! - e.costPrice;
      final stock = e.stock ?? 0;
      return sum + diff * stock;
    });
  }

  /// 商品数量
  int get itemCount => adjustmentInfo?.length ?? 0;
}

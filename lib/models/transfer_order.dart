/// 调拨单状态
enum TransferOrderStatus {
  draft(1, '草稿', 0xFF8E8E93),
  pending(2, '待审核', 0xFFFF9500),
  rejected(3, '已拒绝', 0xFFFF3B30),
  approved(4, '已审核', 0xFF30D158),
  completed(5, '已完成', 0xFF5E5CE6),
  cancelled(6, '已取消', 0xFF8E8E93);

  final int value;
  final String label;
  final int colorValue;

  const TransferOrderStatus(this.value, this.label, this.colorValue);

  static TransferOrderStatus fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 调拨单类型
enum TransferOrderType {
  standard(1, '标准商品调拨'),
  nonStandard(2, '非标准商品调拨');

  final int value;
  final String label;

  const TransferOrderType(this.value, this.label);

  static TransferOrderType fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return standard;
  }
}

/// 调拨单
class TransferOrder {
  final int transferOrderID;
  final String? transferOrderNumber;
  final int fromDepartmentID;
  final String? fromDepartmentName;
  final int toDepartmentID;
  final String? toDepartmentName;
  final int warehouseID;
  final String? warehouseName;
  final TransferOrderStatus status;
  final TransferOrderType type;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int? auditedAt;
  final String? auditedByName;
  final String? remarks;
  final List<TransferOrderProduct> products;
  final int? instanceID;

  const TransferOrder({
    required this.transferOrderID,
    this.transferOrderNumber,
    required this.fromDepartmentID,
    this.fromDepartmentName,
    required this.toDepartmentID,
    this.toDepartmentName,
    required this.warehouseID,
    this.warehouseName,
    required this.status,
    required this.type,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.auditedAt,
    this.auditedByName,
    this.remarks,
    required this.products,
    this.instanceID,
  });

  factory TransferOrder.fromJson(Map<String, dynamic> json) {
    return TransferOrder(
      transferOrderID: json['transferOrderID'] as int? ?? 0,
      transferOrderNumber: json['transferOrderNumber'] as String?,
      fromDepartmentID: json['fromDepartmentID'] as int? ?? 0,
      fromDepartmentName: json['fromDepartmentName'] as String?,
      toDepartmentID: json['toDepartmentID'] as int? ?? 0,
      toDepartmentName: json['toDepartmentName'] as String?,
      warehouseID: json['warehouseID'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      status: TransferOrderStatus.fromValue(json['status'] as int? ?? 2),
      type: TransferOrderType.fromValue(json['type'] as int? ?? 1),
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      auditedAt: json['auditedAt'] as int?,
      auditedByName: json['auditedByName'] as String?,
      remarks: json['remarks'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => TransferOrderProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      instanceID: json['instanceID'] as int?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int get totalQuantity => products.fold(0, (sum, p) => sum + p.quantity);
}

/// 调拨单商品
class TransferOrderProduct {
  final int productID;
  final int skuID;
  final String? skuName;
  final String? productName;
  final String? thumbnail;
  final int quantity;

  const TransferOrderProduct({
    required this.productID,
    required this.skuID,
    this.skuName,
    this.productName,
    this.thumbnail,
    required this.quantity,
  });

  factory TransferOrderProduct.fromJson(Map<String, dynamic> json) {
    return TransferOrderProduct(
      productID: json['productID'] as int? ?? 0,
      skuID: json['skuID'] as int? ?? 0,
      skuName: json['skuName'] as String?,
      productName: json['productName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  String get displayName => skuName ?? productName ?? '';
}

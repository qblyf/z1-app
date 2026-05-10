/// 采购订单状态
enum PurchaseOrderStatus {
  draft(1, '草稿', 0xFF8E8E93),
  pending(2, '待审核', 0xFFFF9500),
  rejected(3, '已拒绝', 0xFFFF3B30),
  approved(4, '已审核', 0xFF30D158),
  finished(5, '已结束', 0xFF5E5CE6),
  closed(6, '已关闭', 0xFF8E8E93),
  cancelled(7, '已取消', 0xFF8E8E93);

  final int value;
  final String label;
  final int colorValue;

  const PurchaseOrderStatus(this.value, this.label, this.colorValue);

  static PurchaseOrderStatus fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 采购订单类型
enum PurchaseOrderType {
  standard(1, '标准商品采购'),
  nonStandard(2, '非标准商品采购');

  final int value;
  final String label;

  const PurchaseOrderType(this.value, this.label);

  static PurchaseOrderType fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return standard;
  }
}

/// 采购订单（简化）
class PurchaseOrder {
  final int purchaseOrderID;
  final String? purchaseOrderNumber;
  final int warehouseID;
  final String? warehouseName;
  final int vendorID;
  final String? vendorName;
  final int departmentID;
  final String? departmentName;
  final PurchaseOrderStatus status;
  final PurchaseOrderType type;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int? auditedAt;
  final String? auditedByName;
  final String? remarks;
  final List<PurchaseOrderProduct> products;
  final int? instanceID;
  final List<String>? invoiceAttachment;
  final String? source;
  final String? externalOrderNumber;

  const PurchaseOrder({
    required this.purchaseOrderID,
    this.purchaseOrderNumber,
    required this.warehouseID,
    this.warehouseName,
    required this.vendorID,
    this.vendorName,
    required this.departmentID,
    this.departmentName,
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
    this.invoiceAttachment,
    this.source,
    this.externalOrderNumber,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      purchaseOrderID: json['purchaseOrderID'] as int? ?? 0,
      purchaseOrderNumber: json['purchaseOrderNumber'] as String?,
      warehouseID: json['warehouseID'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      vendorID: json['vendorID'] as int? ?? 0,
      vendorName: json['vendorName'] as String?,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      status: PurchaseOrderStatus.fromValue(json['status'] as int? ?? 2),
      type: PurchaseOrderType.fromValue(json['type'] as int? ?? 1),
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      auditedAt: json['auditedAt'] as int?,
      auditedByName: json['auditedByName'] as String?,
      remarks: json['remarks'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => PurchaseOrderProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      instanceID: json['instanceID'] as int?,
      invoiceAttachment: (json['invoiceAttachment'] as List<dynamic>?)?.cast<String>(),
      source: json['source'] as String?,
      externalOrderNumber: json['externalOrderNumber'] as String?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 总金额（分 → 元）
  double get totalAmountYuan {
    return products.fold<int>(0, (sum, p) => sum + (p.price * p.quantity)) / 100.0;
  }
}

/// 采购订单商品
class PurchaseOrderProduct {
  final int productID;
  final int skuID;
  final String? skuName;
  final String? productName;
  final String? thumbnail;
  final int price; // 分
  final int quantity;
  final int? warehouseID;
  final String? warehouseName;

  const PurchaseOrderProduct({
    required this.productID,
    required this.skuID,
    this.skuName,
    this.productName,
    this.thumbnail,
    required this.price,
    required this.quantity,
    this.warehouseID,
    this.warehouseName,
  });

  factory PurchaseOrderProduct.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderProduct(
      productID: json['productID'] as int? ?? 0,
      skuID: json['skuID'] as int? ?? 0,
      skuName: json['skuName'] as String?,
      productName: json['productName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      price: json['price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      warehouseID: json['warehouseID'] as int?,
      warehouseName: json['warehouseName'] as String?,
    );
  }

  String get displayName => skuName ?? productName ?? '';

  double get priceYuan => price / 100.0;

  double get subtotalYuan => (price * quantity) / 100.0;
}

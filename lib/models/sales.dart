import 'package:flutter/cupertino.dart';

/// 销售类型
enum SalesType {
  sale(1, '销售'),
  refunds(2, '退货'),
  change(3, '换货');

  final int value;
  final String label;

  const SalesType(this.value, this.label);

  static SalesType fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return sale;
  }
}

/// 销售模式
enum SalesMode {
  inStore(1, '店内零售'),
  online(2, '网络零售'),
  wholesale(3, '批发'),
  repair(4, '维修');

  final int value;
  final String label;

  const SalesMode(this.value, this.label);

  static SalesMode fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return inStore;
  }
}

/// 销售单状态
enum SalesStatus {
  pending(1, '待处理', Color(0xFFFF9500)),
  processing(2, '处理中', Color(0xFF0A84FF)),
  completed(3, '已完成', Color(0xFF30D158)),
  cancelled(4, '已取消', Color(0xFF8E8E93));

  final int value;
  final String label;
  final Color color;

  const SalesStatus(this.value, this.label, this.color);

  static SalesStatus fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 销售单
class SalesOrder {
  final int orderID;
  final String? orderNumber;
  final int departmentID;
  final String? departmentName;
  final SalesType type;
  final SalesMode mode;
  final SalesStatus status;
  final int totalAmount; // 分
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final String? memberName;
  final String? remarks;
  final List<SalesProduct> products;

  const SalesOrder({
    required this.orderID,
    this.orderNumber,
    required this.departmentID,
    this.departmentName,
    required this.type,
    required this.mode,
    required this.status,
    required this.totalAmount,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.memberName,
    this.remarks,
    required this.products,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      orderID: json['orderID'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String?,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      type: SalesType.fromValue(json['type'] as int? ?? 1),
      mode: SalesMode.fromValue(json['mode'] as int? ?? 1),
      status: SalesStatus.fromValue(json['status'] as int? ?? 1),
      totalAmount: json['totalAmount'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      memberName: json['memberName'] as String?,
      remarks: json['remarks'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => SalesProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get totalAmountYuan => totalAmount / 100.0;

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 销售商品
class SalesProduct {
  final int productID;
  final int skuID;
  final String? skuName;
  final String? productName;
  final String? thumbnail;
  final int quantity;
  final int price; // 分
  final int? discount; // 分

  const SalesProduct({
    required this.productID,
    required this.skuID,
    this.skuName,
    this.productName,
    this.thumbnail,
    required this.quantity,
    required this.price,
    this.discount,
  });

  factory SalesProduct.fromJson(Map<String, dynamic> json) {
    return SalesProduct(
      productID: json['productID'] as int? ?? 0,
      skuID: json['skuID'] as int? ?? 0,
      skuName: json['skuName'] as String?,
      productName: json['productName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      discount: json['discount'] as int?,
    );
  }

  String get displayName => skuName ?? productName ?? '';
  double get priceYuan => price / 100.0;
  double get subtotalYuan => (price * quantity) / 100.0;
}

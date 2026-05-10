import 'package:flutter/cupertino.dart';

/// 报货单状态
enum GoodsRequestStatus {
  normal('normal', '正常', Color(0xFF30D158)),
  deprecated('deprecated', '已废弃', Color(0xFFFF3B30));

  final String value;
  final String label;
  final Color color;

  const GoodsRequestStatus(this.value, this.label, this.color);

  static GoodsRequestStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 报货单
class GoodsRequest {
  final int goodsRequestID;
  final int departmentID;
  final String? departmentName;
  final int skuID;
  final String? skuName;
  final String? productName;
  final String? thumbnail;
  final int quantity;
  final String? remarks;
  final GoodsRequestStatus status;
  final int assignedQuantity;
  final String? deprecatedRemarks;
  final List<RelatedOrder> relatedOrders;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int updatedAt;
  // 额外字段
  final int? currStock;
  final int? totalStock;
  final int? currTotalCost;

  const GoodsRequest({
    required this.goodsRequestID,
    required this.departmentID,
    this.departmentName,
    required this.skuID,
    this.skuName,
    this.productName,
    this.thumbnail,
    required this.quantity,
    this.remarks,
    required this.status,
    this.assignedQuantity = 0,
    this.deprecatedRemarks,
    this.relatedOrders = const [],
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.currStock,
    this.totalStock,
    this.currTotalCost,
  });

  factory GoodsRequest.fromJson(Map<String, dynamic> json) {
    return GoodsRequest(
      goodsRequestID: json['goodsRequestID'] as int? ?? 0,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      skuID: json['skuID'] as int? ?? 0,
      skuName: json['skuName'] as String?,
      productName: json['productName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      remarks: json['remarks'] as String?,
      status: GoodsRequestStatus.fromValue(json['status'] as String?) ?? GoodsRequestStatus.normal,
      assignedQuantity: json['assignedQuantity'] as int? ?? 0,
      deprecatedRemarks: json['deprecatedRemarks'] as String?,
      relatedOrders: (json['relatedOrders'] as List<dynamic>?)
              ?.map((e) => RelatedOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      currStock: json['currStock'] as int?,
      totalStock: json['totalStock'] as int?,
      currTotalCost: json['currTotalCost'] as int?,
    );
  }

  String get displayName => skuName ?? productName ?? '';

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  double get totalCostYuan => (currTotalCost ?? 0) / 100.0;
}

/// 关联调拨单
class RelatedOrder {
  final int transferID;
  final String? transferNumber;
  final int quantity;

  const RelatedOrder({
    required this.transferID,
    this.transferNumber,
    required this.quantity,
  });

  factory RelatedOrder.fromJson(Map<String, dynamic> json) {
    return RelatedOrder(
      transferID: json['transferID'] as int? ?? 0,
      transferNumber: json['transferNumber'] as String?,
      quantity: json['quantity'] as int? ?? 0,
    );
  }
}

import 'package:flutter/cupertino.dart';

/// 差异调整单状态
enum PriceDifferenceStatus {
  audited(1, '已审核', Color(0xFF30D158)),
  unaudited(2, '未审核', Color(0xFFFF9500)),
  pendingSubmit(21, '待提交', Color(0xFF8E8E93)),
  rejected(3, '已驳回', Color(0xFFFF3B30));

  final int value;
  final String label;
  final Color color;

  const PriceDifferenceStatus(this.value, this.label, this.color);

  static PriceDifferenceStatus fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return unaudited;
  }
}

/// 差异调整单商品明细
class DifferenceItem {
  final int productID;
  final String? productName;
  final String? skuName;
  final String? thumbnail;
  final int? stock;
  final int? costPrice; // 分
  final int? beforeCostPrice; // 分
  final int? rebatePrice; // 分

  const DifferenceItem({
    required this.productID,
    this.productName,
    this.skuName,
    this.thumbnail,
    this.stock,
    this.costPrice,
    this.beforeCostPrice,
    this.rebatePrice,
  });

  factory DifferenceItem.fromJson(Map<String, dynamic> json) {
    return DifferenceItem(
      productID: json['productID'] as int? ?? 0,
      productName: json['productName'] as String?,
      skuName: json['skuName'] as String?,
      thumbnail: json['thumbnail'] as String?,
      stock: json['stock'] as int?,
      costPrice: json['costPrice'] as int?,
      beforeCostPrice: json['beforeCostPrice'] as int?,
      rebatePrice: json['rebatePrice'] as int?,
    );
  }

  String get displayName => skuName ?? productName ?? '';

  double get costPriceYuan => (costPrice ?? 0) / 100.0;
  double get beforeCostPriceYuan => (beforeCostPrice ?? 0) / 100.0;
  double get rebatePriceYuan => (rebatePrice ?? 0) / 100.0;

  /// 价格变动
  double get priceChange => costPriceYuan - beforeCostPriceYuan;
}

/// 差异调整单
class PriceDifference {
  final int priceDifferenceID;
  final String number;
  final int vendorID;
  final String? vendorName;
  final int departmentID;
  final String? departmentName;
  final PriceDifferenceStatus status;
  final List<DifferenceItem> items;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int? auditAt;
  final String? auditByName;
  final String? remarks;
  final String? docRemarks;

  const PriceDifference({
    required this.priceDifferenceID,
    required this.number,
    required this.vendorID,
    this.vendorName,
    required this.departmentID,
    this.departmentName,
    required this.status,
    required this.items,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.auditAt,
    this.auditByName,
    this.remarks,
    this.docRemarks,
  });

  factory PriceDifference.fromJson(Map<String, dynamic> json) {
    return PriceDifference(
      priceDifferenceID: json['priceDifferenceID'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      vendorID: json['vendorID'] as int? ?? 0,
      vendorName: json['vendorName'] as String?,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      status: PriceDifferenceStatus.fromValue(json['status'] as int? ?? 2),
      items: (json['differenceInfo'] as List<dynamic>?)
              ?.map((e) => DifferenceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      auditAt: json['auditAt'] as int?,
      auditByName: json['auditByName'] as String?,
      remarks: json['remarks'] as String?,
      docRemarks: json['docRemarks'] as String?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

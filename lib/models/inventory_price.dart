/// 库存价格查询模型

/// 库存价格条目
class StockPriceItem {
  final int skuId;
  final String skuName;
  final int warehouseId;
  final String? warehouseName;
  final int stock;
  final int? costPrice;
  final int? limitPrice;
  final int? listPrice;

  StockPriceItem({
    required this.skuId,
    required this.skuName,
    required this.warehouseId,
    this.warehouseName,
    required this.stock,
    this.costPrice,
    this.limitPrice,
    this.listPrice,
  });

  factory StockPriceItem.fromJson(Map<String, dynamic> json) {
    return StockPriceItem(
      skuId: json['skuID'] as int? ?? 0,
      skuName: json['skuName'] as String? ?? '',
      warehouseId: json['warehouseID'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      stock: json['stock'] as int? ?? 0,
      costPrice: json['costPrice'] as int?,
      limitPrice: json['limitPrice'] as int?,
      listPrice: json['listPrice'] as int?,
    );
  }

  String get costPriceDisplay => costPrice != null ? '¥${(costPrice! / 100).toStringAsFixed(2)}' : '-';
  String get limitPriceDisplay => limitPrice != null ? '¥${(limitPrice! / 100).toStringAsFixed(2)}' : '-';
  String get listPriceDisplay => listPrice != null ? '¥${(listPrice! / 100).toStringAsFixed(2)}' : '-';
}

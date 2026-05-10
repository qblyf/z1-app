/// 整单备货 - 调拨清单中的调拨商品
/// 对应 PWA TransferProduct 类型
class TransferProductStocking {
  final int productId;
  final List<StockingGoods>? goodsList;
  final int? quantity;
  final int? estimateQuantity;
  final int preTransferQuantity;

  TransferProductStocking({
    required this.productId,
    this.goodsList,
    this.quantity,
    this.estimateQuantity,
    required this.preTransferQuantity,
  });

  factory TransferProductStocking.fromJson(Map<String, dynamic> json) {
    final hasGoodsList = json.containsKey('goodsList') && json['goodsList'] != null;
    return TransferProductStocking(
      productId: json['productID'] as int? ?? 0,
      goodsList: hasGoodsList
          ? (json['goodsList'] as List<dynamic>)
              .map((e) => StockingGoods.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      quantity: json['quantity'] as int?,
      estimateQuantity: json['estimateQuantity'] as int?,
      preTransferQuantity: json['preTransferQuantity'] as int? ??
          (hasGoodsList
              ? (json['goodsList'] as List<dynamic>).length
              : (json['quantity'] as int? ?? 0)),
    );
  }

  Map<String, dynamic> toJson() {
    if (goodsList != null) {
      return {
        'productID': productId,
        'goodsList': goodsList!.map((e) => e.toJson()).toList(),
        if (estimateQuantity != null) 'estimateQuantity': estimateQuantity,
        'preTransferQuantity': preTransferQuantity,
      };
    } else {
      return {
        'productID': productId,
        'quantity': quantity ?? 0,
        if (estimateQuantity != null) 'estimateQuantity': estimateQuantity,
        'preTransferQuantity': preTransferQuantity,
      };
    }
  }

  /// 克隆并更新商品列表
  TransferProductStocking copyWith({
    List<StockingGoods>? goodsList,
    int? quantity,
  }) {
    return TransferProductStocking(
      productId: productId,
      goodsList: goodsList ?? this.goodsList,
      quantity: quantity ?? this.quantity,
      estimateQuantity: estimateQuantity,
      preTransferQuantity: preTransferQuantity,
    );
  }
}

/// 备货商品（带序列号）
class StockingGoods {
  final int id;
  final String serial;

  StockingGoods({required this.id, required this.serial});

  factory StockingGoods.fromJson(Map<String, dynamic> json) {
    return StockingGoods(
      id: json['id'] as int? ?? 0,
      serial: json['serial'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'serial': serial};
}

/// 整单备货 - 草稿数据
class TransferStockingDraft {
  final int? inWarehouseId;
  final int outWarehouseId;
  final String remarks;
  final List<TransferProductStocking> transferProducts;
  final int createdBy;

  TransferStockingDraft({
    this.inWarehouseId,
    required this.outWarehouseId,
    required this.remarks,
    required this.transferProducts,
    required this.createdBy,
  });

  factory TransferStockingDraft.fromJson(Map<String, dynamic> json) {
    final products = json['transferProducts'] as List<dynamic>? ?? [];
    return TransferStockingDraft(
      inWarehouseId: json['inWarehouseID'] as int?,
      outWarehouseId: json['outWarehouseID'] as int? ?? 0,
      remarks: json['remarks'] as String? ?? '',
      transferProducts: products
          .map((e) => TransferProductStocking.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdBy: json['createdBy'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (inWarehouseId != null) 'inWarehouseID': inWarehouseId,
    'outWarehouseID': outWarehouseId,
    'remarks': remarks,
    'transferProducts': transferProducts.map((e) => e.toJson()).toList(),
    'createdBy': createdBy,
  };
}

/// 备货记录项（扫描添加的货品）
class StockingItem {
  final int productId;
  final int? goodsId;
  final int? qty;
  final int createdBy;
  final int createdAt;
  final String remarks;

  StockingItem({
    required this.productId,
    this.goodsId,
    this.qty,
    required this.createdBy,
    required this.createdAt,
    required this.remarks,
  });

  /// 从搜索结果创建
  factory StockingItem.fromSearchResult({
    required int productId,
    int? goodsId,
    int? qty,
    required int createdBy,
    required String serial,
  }) {
    return StockingItem(
      productId: productId,
      goodsId: goodsId,
      qty: qty,
      createdBy: createdBy,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      remarks: serial,
    );
  }
}

/// 将备货记录转换为调拨商品格式
List<TransferProductStocking> convertStockingItemsToTransferProducts(
  List<StockingItem> items,
  List<TransferProductStocking> preProducts,
) {
  if (items.isEmpty) return [];

  // 按创建时间倒序
  final sorted = List<StockingItem>.from(items)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final Map<int, TransferProductStocking> result = {};

  for (final item in sorted) {
    if (result.containsKey(item.productId)) {
      final existing = result[item.productId]!;
      if (item.goodsId != null) {
        final goods = StockingGoods(id: item.goodsId!, serial: item.remarks.trim());
        if (existing.goodsList != null) {
          result[item.productId] = existing.copyWith(
            goodsList: [...existing.goodsList!, goods],
          );
        } else {
          result[item.productId] = existing.copyWith(
            goodsList: [goods],
          );
        }
      } else if (item.qty != null) {
        result[item.productId] = existing.copyWith(
          quantity: (existing.quantity ?? 0) + 1,
        );
      }
    } else {
      // 查找预调拨数量
      final preProduct = preProducts.where((p) => p.productId == item.productId).firstOrNull;
      final preQty = preProduct?.preTransferQuantity ?? 0;

      if (item.goodsId != null) {
        final goods = StockingGoods(id: item.goodsId!, serial: item.remarks.trim());
        result[item.productId] = TransferProductStocking(
          productId: item.productId,
          goodsList: [goods],
          preTransferQuantity: preQty,
        );
      } else if (item.qty != null) {
        result[item.productId] = TransferProductStocking(
          productId: item.productId,
          quantity: item.qty!,
          preTransferQuantity: preQty,
        );
      }
    }
  }

  return result.values.toList();
}

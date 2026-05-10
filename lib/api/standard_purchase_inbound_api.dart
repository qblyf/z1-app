import 'api_client.dart';

/// 标品采购入库 API
/// 对应后端 /purchase/* 系列接口
class StandardPurchaseInboundApi {
  final ApiClient _client = ApiClient();

  /// 采购入库单列表
  /// 后端 GET /purchase/list，返回 { code, list: [...] }
  Future<List<PurchaseInbound>> list({
    List<int>? warehouseIDs,
    List<int>? cateIDs,
    List<int>? spuIDs,
    List<int>? productsIDs,
    List<int>? vendorIDs,
    List<int>? creatorIDs,
    List<String>? numbers,
    List<String>? purchaseOrderNumbers,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final queryParams = <String, dynamic>{};
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs;
    }
    if (cateIDs != null && cateIDs.isNotEmpty) {
      queryParams['cateIDs'] = cateIDs;
    }
    if (spuIDs != null && spuIDs.isNotEmpty) {
      queryParams['spuIDs'] = spuIDs;
    }
    if (productsIDs != null && productsIDs.isNotEmpty) {
      queryParams['productsIDs'] = productsIDs;
    }
    if (vendorIDs != null && vendorIDs.isNotEmpty) {
      queryParams['vendorIDs'] = vendorIDs;
    }
    if (creatorIDs != null && creatorIDs.isNotEmpty) {
      queryParams['creatorIDs'] = creatorIDs;
    }
    if (numbers != null && numbers.isNotEmpty) {
      queryParams['numbers'] = numbers;
    }
    if (purchaseOrderNumbers != null && purchaseOrderNumbers.isNotEmpty) {
      queryParams['purchaseOrderNumbers'] = purchaseOrderNumbers;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (orderBy != null) queryParams['orderBy'] = orderBy;

    final res = await _client.get('/purchase/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => PurchaseInbound.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 采购入库单列表总数
  /// 后端 GET /purchase/count，返回 { code, res: { count, totalCount, totalCent } }
  Future<PurchaseInboundCount> count({
    List<int>? warehouseIDs,
    List<int>? cateIDs,
    List<int>? spuIDs,
    List<int>? productsIDs,
    List<int>? vendorIDs,
    List<int>? creatorIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{};
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs;
    }
    if (cateIDs != null && cateIDs.isNotEmpty) {
      queryParams['cateIDs'] = cateIDs;
    }
    if (spuIDs != null && spuIDs.isNotEmpty) {
      queryParams['spuIDs'] = spuIDs;
    }
    if (productsIDs != null && productsIDs.isNotEmpty) {
      queryParams['productsIDs'] = productsIDs;
    }
    if (vendorIDs != null && vendorIDs.isNotEmpty) {
      queryParams['vendorIDs'] = vendorIDs;
    }
    if (creatorIDs != null && creatorIDs.isNotEmpty) {
      queryParams['creatorIDs'] = creatorIDs;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/purchase/count', queryParameters: queryParams);
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return const PurchaseInboundCount();
    return PurchaseInboundCount.fromJson(data);
  }

  /// 采购入库单详情
  /// 后端 GET /purchase/detail?id=N
  Future<PurchaseInboundDetail?> detail(int purchaseId) async {
    final res = await _client.get(
      '/purchase/detail',
      queryParameters: {'id': purchaseId},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return PurchaseInboundDetail.fromJson(data);
  }

  /// 根据采购订单新增采购入库单
  /// 后端 POST /purchase/add
  Future<int?> addFromPurchaseOrder({
    required int purchaseOrderID,
    required int warehouseID,
    required int vendorID,
    required List<Map<String, dynamic>> products,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'purchaseOrderID': purchaseOrderID,
      'warehouseID': warehouseID,
      'vendorID': vendorID,
      'products': products,
      'isChangeCostPrice': 0,
    };
    if (remarks != null) body['remarks'] = remarks;

    final res = await _client.post('/purchase/add', data: body);
    final id = res.data['id'];
    return id is int ? id : null;
  }

  /// 手动新增采购入库单（同时生成采购订单）
  /// 后端 POST /purchase/add/audited
  Future<int?> addAudited({
    required int warehouseID,
    required int vendorID,
    required List<Map<String, dynamic>> products,
    String? remarks,
    int? expectedAt,
  }) async {
    final body = <String, dynamic>{
      'warehouseID': warehouseID,
      'vendorID': vendorID,
      'products': products,
      'isChangeCostPrice': 0,
    };
    if (remarks != null) body['remarks'] = remarks;
    if (expectedAt != null) body['expectedAt'] = expectedAt;

    final res = await _client.post('/purchase/add/audited', data: body);
    final data = res.data['id'] as Map<String, dynamic>?;
    return data?['purchaseID'] as int?;
  }

  /// 采购入库
  /// 后端 POST /purchase/into-warehouse
  Future<bool> intoWarehouse(int purchaseId) async {
    final res = await _client.post(
      '/purchase/into-warehouse',
      data: {'purchaseID': purchaseId},
    );
    return res.data['rowCount'] == 1;
  }
}

/// 采购入库单列表项
class PurchaseInbound {
  final int purchaseID;
  final String? number;
  final String? purchaseOrderNumber;
  final int? warehouseID;
  final String? warehouseName;
  final int? vendorID;
  final String? vendorName;
  final int creatorIdent;
  final String? creatorName;
  final int createdAt;
  final int state;
  final String? stateName;
  final List<PurchaseInboundProduct> products;
  final String? remarks;

  const PurchaseInbound({
    required this.purchaseID,
    this.number,
    this.purchaseOrderNumber,
    this.warehouseID,
    this.warehouseName,
    this.vendorID,
    this.vendorName,
    required this.creatorIdent,
    this.creatorName,
    required this.createdAt,
    required this.state,
    this.stateName,
    required this.products,
    this.remarks,
  });

  factory PurchaseInbound.fromJson(Map<String, dynamic> json) {
    return PurchaseInbound(
      purchaseID: json['purchaseID'] as int? ?? 0,
      number: json['number'] as String?,
      purchaseOrderNumber: json['purchaseOrderNumber'] as String?,
      warehouseID: json['warehouseID'] as int?,
      warehouseName: json['warehouseName'] as String?,
      vendorID: json['vendorID'] as int?,
      vendorName: json['vendorName'] as String?,
      creatorIdent: json['creatorIdent'] as int? ?? json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      state: json['state'] as int? ?? 1,
      stateName: json['stateName'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => PurchaseInboundProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      remarks: json['remarks'] as String?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 采购总数量
  int get totalQuantity {
    int total = 0;
    for (final p in products) {
      if (p.count != null) {
        total += p.count!;
      }
      if (p.serial != null) {
        total += p.serial!.length;
      }
    }
    return total;
  }

  /// 采购总金额（分）
  int get totalAmount {
    int total = 0;
    for (final p in products) {
      final qty = (p.count ?? 0) + (p.serial?.length ?? 0);
      if (p.cent != null) {
        total += qty * p.cent!;
      }
    }
    return total;
  }

  String get formattedAmount {
    final yuan = totalAmount / 100;
    return '¥${yuan.toStringAsFixed(2)}';
  }
}

/// 采购入库单商品
class PurchaseInboundProduct {
  final int product;
  final String? productName;
  final int? cent; // 采购单价（分）
  final int? count;
  final List<ProductSerial>? serial;
  final int? costPrice;

  const PurchaseInboundProduct({
    required this.product,
    this.productName,
    this.cent,
    this.count,
    this.serial,
    this.costPrice,
  });

  factory PurchaseInboundProduct.fromJson(Map<String, dynamic> json) {
    return PurchaseInboundProduct(
      product: json['product'] as int? ?? 0,
      productName: json['productName'] as String?,
      cent: json['cent'] as int?,
      count: json['count'] as int?,
      serial: (json['serial'] as List<dynamic>?)
          ?.map((e) => ProductSerial.fromJson(e as Map<String, dynamic>))
          .toList(),
      costPrice: json['costPrice'] as int?,
    );
  }

  int get quantity => (count ?? 0) + (serial?.length ?? 0);
}

/// 商品序列号信息
class ProductSerial {
  final String? serial;
  final String? meid;
  final String? sn2;

  const ProductSerial({this.serial, this.meid, this.sn2});

  factory ProductSerial.fromJson(Map<String, dynamic> json) {
    return ProductSerial(
      serial: json['serial'] as String?,
      meid: json['meid'] as String?,
      sn2: json['sn2'] as String?,
    );
  }
}

/// 采购入库单详情
class PurchaseInboundDetail {
  final int purchaseID;
  final String? number;
  final String? purchaseOrderNumber;
  final int? warehouseID;
  final String? warehouseName;
  final int? vendorID;
  final String? vendorName;
  final int creatorIdent;
  final String? creatorName;
  final int createdAt;
  final int state;
  final String? stateName;
  final List<PurchaseInboundProduct> products;
  final String? remarks;
  final int? purchaseOrderID;

  const PurchaseInboundDetail({
    required this.purchaseID,
    this.number,
    this.purchaseOrderNumber,
    this.warehouseID,
    this.warehouseName,
    this.vendorID,
    this.vendorName,
    required this.creatorIdent,
    this.creatorName,
    required this.createdAt,
    required this.state,
    this.stateName,
    required this.products,
    this.remarks,
    this.purchaseOrderID,
  });

  factory PurchaseInboundDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseInboundDetail(
      purchaseID: json['purchaseID'] as int? ?? 0,
      number: json['number'] as String?,
      purchaseOrderNumber: json['purchaseOrderNumber'] as String?,
      warehouseID: json['warehouseID'] as int?,
      warehouseName: json['warehouseName'] as String?,
      vendorID: json['vendorID'] as int?,
      vendorName: json['vendorName'] as String?,
      creatorIdent: json['creatorIdent'] as int? ?? json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      state: json['state'] as int? ?? 1,
      stateName: json['stateName'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => PurchaseInboundProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      remarks: json['remarks'] as String?,
      purchaseOrderID: json['purchaseOrderID'] as int?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int get totalQuantity {
    int total = 0;
    for (final p in products) {
      if (p.count != null) total += p.count!;
      if (p.serial != null) total += p.serial!.length;
    }
    return total;
  }

  int get totalAmount {
    int total = 0;
    for (final p in products) {
      final qty = (p.count ?? 0) + (p.serial?.length ?? 0);
      if (p.cent != null) total += qty * p.cent!;
    }
    return total;
  }

  /// 预估调价损失（分）
  int get totalUnitPriceLoss {
    int total = 0;
    for (final p in products) {
      if (p.cent != null && p.costPrice != null) {
        total += (p.cent! - p.costPrice!) * ((p.count ?? 0) + (p.serial?.length ?? 0));
      }
    }
    return total;
  }

  String get formattedAmount => '¥${(totalAmount / 100).toStringAsFixed(2)}';
  String get formattedLoss => '¥${(totalUnitPriceLoss / 100).toStringAsFixed(2)}';
}

/// 采购入库单计数结果
class PurchaseInboundCount {
  final int count;
  final int totalCount;
  final int totalCent;

  const PurchaseInboundCount({
    this.count = 0,
    this.totalCount = 0,
    this.totalCent = 0,
  });

  factory PurchaseInboundCount.fromJson(Map<String, dynamic> json) {
    return PurchaseInboundCount(
      count: json['count'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      totalCent: json['totalCent'] as int? ?? 0,
    );
  }

  String get formattedTotalAmount => '¥${(totalCent / 100).toStringAsFixed(2)}';
}

/// 采购入库单状态
enum PurchaseInboundState {
  normal(1, '正常'),
  draft(2, '草稿'),
  undetermined(3, '待审核');

  final int value;
  final String label;
  const PurchaseInboundState(this.value, this.label);

  static PurchaseInboundState fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return normal;
  }
}

import 'package:z1_app/api/api_client.dart';

/// 商品序列号搜索 API
/// 对应后端 /serial/goods/search
class GoodsApi {
  final ApiClient _client = ApiClient();

  /// 根据串号模糊搜索获取标品和非标的货品信息
  /// GET /serial/goods/search?serial=xxx
  Future<List<SerialSearchResult>> searchBySerial(String serial) async {
    final response = await _client.get(
      '/serial/goods/search',
      queryParameters: {'serial': serial},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => SerialSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取货品信息（标品）
  /// POST /goods/detail
  Future<GoodsInfo> getGoodsDetail(List<int> goodsIds) async {
    final response = await _client.post(
      '/goods/detail',
      data: {'goodsIDs': goodsIds},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    if (data.isEmpty) throw Exception('货品不存在');
    return GoodsInfo.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 获取非标准货品信息
  /// POST /item/detail
  Future<NonStandardItemInfo> getNonStandardItemDetail(List<int> itemIds) async {
    final response = await _client.post(
      '/item/detail',
      data: {'ids': itemIds},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    if (data.isEmpty) throw Exception('非标货品不存在');
    return NonStandardItemInfo.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 串号流转追踪
  /// GET /serial/trace?serial=xxx
  Future<List<SerialTraceRecord>> traceSerial(String serial) async {
    final response = await _client.get(
      '/serial/trace',
      queryParameters: {'serial': serial},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => SerialTraceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 货品流转追踪
  /// GET /goods/trace?goodsId=xxx
  Future<List<SerialTraceRecord>> traceGoods(int goodsId) async {
    final response = await _client.get(
      '/goods/trace',
      queryParameters: {'goodsId': goodsId},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => SerialTraceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 序列号搜索结果
class SerialSearchResult {
  final int? goodsId;
  final int? purchaseCent; // 采购金额（分）
  final String serial;
  final String? meid;
  final String? sn2;
  final int? skuCostCent; // SKU成本价（分）
  final List<NonStandardItem> items;

  SerialSearchResult({
    this.goodsId,
    this.purchaseCent,
    required this.serial,
    this.meid,
    this.sn2,
    this.skuCostCent,
    this.items = const [],
  });

  factory SerialSearchResult.fromJson(Map<String, dynamic> json) {
    return SerialSearchResult(
      goodsId: json['goodsID'] as int?,
      purchaseCent: json['purchaseCent'] as int?,
      serial: json['serial'] as String? ?? '',
      meid: json['meid'] as String?,
      sn2: json['sn2'] as String?,
      skuCostCent: json['skuCostCent'] as int?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => NonStandardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 非标准货品
class NonStandardItem {
  final int itemId;
  final int? costCent; // 成本价（分）
  final int? purchaseCent; // 采购价（分）

  NonStandardItem({
    required this.itemId,
    this.costCent,
    this.purchaseCent,
  });

  factory NonStandardItem.fromJson(Map<String, dynamic> json) {
    return NonStandardItem(
      itemId: json['itemID'] as int? ?? 0,
      costCent: json['costCent'] as int?,
      purchaseCent: json['purchaseCent'] as int?,
    );
  }
}

/// 标品货品信息
class GoodsInfo {
  final int id;
  final int product;
  final String? serial;
  final int? state;
  final int? vendor;
  final int? warehouse;
  final int? createdAt;
  final String? meid;
  final String? sn2;

  GoodsInfo({
    required this.id,
    required this.product,
    this.serial,
    this.state,
    this.vendor,
    this.warehouse,
    this.createdAt,
    this.meid,
    this.sn2,
  });

  factory GoodsInfo.fromJson(Map<String, dynamic> json) {
    return GoodsInfo(
      id: json['id'] as int? ?? 0,
      product: json['product'] as int? ?? 0,
      serial: json['serial'] as String?,
      state: json['state'] as int?,
      vendor: json['vendor'] as int?,
      warehouse: json['warehouse'] as int?,
      createdAt: json['created_at'] as int?,
      meid: json['meid'] as String?,
      sn2: json['sn2'] as String?,
    );
  }
}

/// 非标准货品信息
class NonStandardItemInfo {
  final int id;
  final int productId;
  final String? uniqueSn;
  final String? sn;
  final int? warehouseId;
  final int? createdAt;
  final int? status;
  final int? costPrice; // 成本价（分）
  final String? meid;
  final String? sn2;

  NonStandardItemInfo({
    required this.id,
    required this.productId,
    this.uniqueSn,
    this.sn,
    this.warehouseId,
    this.createdAt,
    this.status,
    this.costPrice,
    this.meid,
    this.sn2,
  });

  factory NonStandardItemInfo.fromJson(Map<String, dynamic> json) {
    return NonStandardItemInfo(
      id: json['id'] as int? ?? 0,
      productId: json['productID'] as int? ?? 0,
      uniqueSn: json['uniqueSN'] as String?,
      sn: json['sn'] as String?,
      warehouseId: json['warehouseID'] as int?,
      createdAt: json['createdAt'] as int?,
      status: json['status'] as int?,
      costPrice: json['costPrice'] as int?,
      meid: json['meid'] as String?,
      sn2: json['sn2'] as String?,
    );
  }
}

/// 串号流转追踪记录
class SerialTraceRecord {
  final int type;
  final int id;
  final String? number;
  final int? inWarehouse;
  final int? outWarehouse;
  final int? vendor;
  final int? userIdent;
  final int? createdAt;
  final int? updatedAt;
  final int? orderState;
  final int? productState;

  SerialTraceRecord({
    required this.type,
    required this.id,
    this.number,
    this.inWarehouse,
    this.outWarehouse,
    this.vendor,
    this.userIdent,
    this.createdAt,
    this.updatedAt,
    this.orderState,
    this.productState,
  });

  factory SerialTraceRecord.fromJson(Map<String, dynamic> json) {
    return SerialTraceRecord(
      type: json['type'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      number: json['number'] as String?,
      inWarehouse: json['inWarehouse'] as int?,
      outWarehouse: json['outWarehouse'] as int?,
      vendor: json['vendor'] as int?,
      userIdent: json['userIdent'] as int?,
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt'] as int?,
      orderState: json['orderstate'] as int?,
      productState: json['productstate'] as int?,
    );
  }
}

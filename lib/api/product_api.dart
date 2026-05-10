import 'package:z1_app/api/api_client.dart';
import '../models/product.dart';

/// 商品 API 服务
class ProductApi {
  final ApiClient _client = ApiClient();

  /// 获取商品列表
  Future<List<Product>> getList({
    int? categoryId,
    int? brandId,
    String? keyword,
    int? minPrice,
    int? maxPrice,
    bool? isOnSale,
    String? orderBy,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (categoryId != null) 'categoryId': categoryId,
      if (brandId != null) 'brandId': brandId,
      if (keyword != null) 'keyword': keyword,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (isOnSale != null) 'isOnSale': isOnSale ? 1 : 0,
      if (orderBy != null) 'orderBy': orderBy,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get('/product/list-base', queryParameters: queryParams);

    final data = response.data;
    final list = data['list'] ?? data['res'];

    if (list is List) {
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取商品详情
  Future<Product> getDetail(int productId) async {
    final response = await _client.get(
      '/product',
      queryParameters: {'ids': productId.toString()},
    );

    final data = response.data;
    return Product.fromJson(data['res'] as Map<String, dynamic>);
  }

  /// 获取商品 SKU 列表
  Future<List<ProductSku>> getSkuList(int productId) async {
    final response = await _client.get(
      '/sku/select-base',
      queryParameters: {'productId': productId},
    );

    final data = response.data;
    final list = data['list'] ?? data['res'];

    if (list is List) {
      return list.map((e) => ProductSku.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取商品分类列表
  Future<List<Map<String, dynamic>>> getCategories({int? parentId}) async {
    final queryParams = <String, dynamic>{
      if (parentId != null) 'parentId': parentId,
    };

    final response = await _client.get('/category/list', queryParameters: queryParams);

    final data = response.data;
    final list = data['list'] ?? data['res'];

    if (list is List) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// 搜索商品
  Future<List<Product>> search({
    required String keyword,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'keyword': keyword,
      if (categoryId != null) 'categoryId': categoryId,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get('/product/list-base', queryParameters: queryParams);

    final data = response.data;
    final list = data['list'] ?? data['res'];

    if (list is List) {
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取商品库存
  Future<Map<String, int>> getStock(int productId, {List<int>? skuIds}) async {
    final body = <String, dynamic>{
      'productId': productId,
      if (skuIds != null) 'skuIds': skuIds,
    };

    final response = await _client.post('/product/stock', data: body);

    final data = response.data;
    final stock = data['stock'] as Map<String, dynamic>?;

    if (stock != null) {
      return stock.map((k, v) => MapEntry(k, v as int));
    }
    return {};
  }

  /// 获取商品价格
  Future<List<Map<String, dynamic>>> getPrice(int productId, {List<int>? skuIds}) async {
    final body = <String, dynamic>{
      'productId': productId,
      if (skuIds != null) 'skuIds': skuIds,
    };

    final response = await _client.post('/product-price/list', data: body);

    final data = response.data;
    final list = data['list'] ?? data['res'];

    if (list is List) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// 获取商城商品SPU详情（含SKU列表）
  /// 后端 GET /product/sku-by-spu?spuID=...
  Future<MallProductInfo> getMallProduct(int spuId) async {
    final response = await _client.get(
      '/product/sku-by-spu',
      queryParameters: {'spuID': spuId},
    );
    return MallProductInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// 根据关键词搜索SPU商品
  /// 后端 GET /product/search?keyword=...
  Future<List<SpuSearchResult>> searchSpu({required String keyword, int limit = 20}) async {
    final response = await _client.get(
      '/product/search',
      queryParameters: {'keyword': keyword, 'limit': limit},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => SpuSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取商品SKU详情
  /// 后端 POST /sku/detail
  Future<SkuDetailInfo> getSkuDetail(int skuId) async {
    final response = await _client.post(
      '/sku/detail',
      data: {'ids': [skuId]},
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    if (data.isEmpty) throw Exception('SKU not found');
    return SkuDetailInfo.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 获取商品库存统计（按仓库）
  /// 后端 POST /stock-stats
  Future<List<SkuStockInfo>> getStockStats({required List<int> productIds, List<int>? warehouseIds}) async {
    final body = <String, dynamic>{
      'productIDs': productIds,
      if (warehouseIds != null && warehouseIds.isNotEmpty) 'warehouseIDs': warehouseIds,
    };
    final response = await _client.post('/stock-stats', data: body);
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => SkuStockInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取部门仓库SKU统计（锁货/可售）
  /// 后端 POST /product-warehouse/statistics-department-stock
  Future<List<DeptStockInfo>> getDepartmentStock({
    required List<int> skuIds,
    required List<int> warehouseIds,
  }) async {
    final body = <String, dynamic>{
      'skuIDs': skuIds,
      'warehouseIDs': warehouseIds,
      'isSaleStock': false,
    };
    final response = await _client.post('/product-warehouse/statistics-department-stock', data: body);
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => DeptStockInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 商城商品SPU信息（报价单用）
class MallProductInfo {
  final MallSpuInfo spu;
  final List<MallServiceCate>? services;
  final MallServiceItem? defaultService;
  final List<MallSkuInfo> skus;
  final List<MallRecommend> recommend;

  MallProductInfo({
    required this.spu,
    this.services,
    this.defaultService,
    required this.skus,
    required this.recommend,
  });

  factory MallProductInfo.fromJson(Map<String, dynamic> json) {
    return MallProductInfo(
      spu: MallSpuInfo.fromJson(json['spu'] as Map<String, dynamic>),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => MallServiceCate.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultService: json['defaultService'] != null
          ? MallServiceItem.fromJson(json['defaultService'] as Map<String, dynamic>)
          : null,
      skus: (json['skus'] as List<dynamic>?)
              ?.map((e) => MallSkuInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommend: (json['recommend'] as List<dynamic>?)
              ?.map((e) => MallRecommend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MallSpuInfo {
  final String name;
  final String? desc;
  final String? video;
  final List<String> images;
  final List<int>? skuIDs;
  final bool isCoin;
  final String? policyDesc;

  MallSpuInfo({
    required this.name,
    this.desc,
    this.video,
    this.images = const [],
    this.skuIDs,
    this.isCoin = false,
    this.policyDesc,
  });

  factory MallSpuInfo.fromJson(Map<String, dynamic> json) {
    return MallSpuInfo(
      name: json['name'] as String? ?? '',
      desc: json['desc'] as String?,
      video: json['video'] as String?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      skuIDs: (json['skuIDs'] as List<dynamic>?)?.map((e) => e as int).toList(),
      isCoin: json['isCoin'] as bool? ?? false,
      policyDesc: json['policyDesc'] as String?,
    );
  }
}

class MallServiceCate {
  final int cateID;
  final String cateName;
  final String? cateRmark;
  final String? cateIcon;
  final List<MallServiceItem> service;

  MallServiceCate({
    required this.cateID,
    required this.cateName,
    this.cateRmark,
    this.cateIcon,
    required this.service,
  });

  factory MallServiceCate.fromJson(Map<String, dynamic> json) {
    return MallServiceCate(
      cateID: json['cateID'] as int? ?? 0,
      cateName: json['cateName'] as String? ?? '',
      cateRmark: json['cateRmark'] as String?,
      cateIcon: json['cateIcon'] as String?,
      service: (json['service'] as List<dynamic>?)
              ?.map((e) => MallServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MallServiceItem {
  final int id;
  final String shortName;
  final int price;
  final String? remark;
  final String? activityDescription;

  MallServiceItem({
    required this.id,
    required this.shortName,
    required this.price,
    this.remark,
    this.activityDescription,
  });

  factory MallServiceItem.fromJson(Map<String, dynamic> json) {
    return MallServiceItem(
      id: json['id'] as int? ?? 0,
      shortName: json['shortName'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      remark: json['remark'] as String?,
      activityDescription: json['activityDescription'] as String?,
    );
  }
}

class MallSkuInfo {
  final int id;
  final String name;
  final int? price;
  final String? thumbnail;
  final int? listPrice;
  final int stock;
  final int virtualStock;
  final bool isAllowance;

  MallSkuInfo({
    required this.id,
    required this.name,
    this.price,
    this.thumbnail,
    this.listPrice,
    this.stock = 0,
    this.virtualStock = 0,
    this.isAllowance = false,
  });

  factory MallSkuInfo.fromJson(Map<String, dynamic> json) {
    return MallSkuInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: json['price'] as int?,
      thumbnail: json['thumbnail'] as String?,
      listPrice: json['listPrice'] as int?,
      stock: json['stock'] as int? ?? 0,
      virtualStock: json['virtualStock'] as int? ?? 0,
      isAllowance: json['isAllowance'] as bool? ?? false,
    );
  }
}

class MallRecommend {
  final int id;
  final List<String>? mainImage;
  final String shortName;

  MallRecommend({
    required this.id,
    this.mainImage,
    required this.shortName,
  });

  factory MallRecommend.fromJson(Map<String, dynamic> json) {
    return MallRecommend(
      id: json['id'] as int? ?? 0,
      mainImage: (json['mainImage'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      shortName: json['shortName'] as String? ?? '',
    );
  }
}

/// SPU搜索结果
class SpuSearchResult {
  final int id;
  final String name;
  final String? shortName;
  final String? mainImage;

  SpuSearchResult({
    required this.id,
    required this.name,
    this.shortName,
    this.mainImage,
  });

  factory SpuSearchResult.fromJson(Map<String, dynamic> json) {
    return SpuSearchResult(
      id: json['id'] as int? ?? json['spuId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      mainImage: (json['mainImage'] as List<dynamic>?)?.firstOrNull?.toString(),
    );
  }
}

/// SKU详情（最低售价等）
class SkuDetailInfo {
  final int id;
  final int? limitPrice;

  SkuDetailInfo({required this.id, this.limitPrice});

  factory SkuDetailInfo.fromJson(Map<String, dynamic> json) {
    return SkuDetailInfo(
      id: json['id'] as int? ?? 0,
      limitPrice: json['limitPrice'] as int?,
    );
  }
}

/// SKU库存信息
class SkuStockInfo {
  final int productID;
  final int warehouseID;
  final int totalStock;
  final int totalCost;

  SkuStockInfo({
    required this.productID,
    required this.warehouseID,
    required this.totalStock,
    required this.totalCost,
  });

  factory SkuStockInfo.fromJson(Map<String, dynamic> json) {
    return SkuStockInfo(
      productID: json['productID'] as int? ?? 0,
      warehouseID: json['warehouseID'] as int? ?? 0,
      totalStock: json['totalStock'] as int? ?? 0,
      totalCost: json['totalCost'] as int? ?? 0,
    );
  }
}

/// 部门仓库库存统计（锁货/可售）
class DeptStockInfo {
  final int skuID;
  final int warehouseID;
  final int lockStock;
  final int saleStock;

  DeptStockInfo({
    required this.skuID,
    required this.warehouseID,
    required this.lockStock,
    required this.saleStock,
  });

  factory DeptStockInfo.fromJson(Map<String, dynamic> json) {
    return DeptStockInfo(
      skuID: json['skuID'] as int? ?? 0,
      warehouseID: json['warehouseID'] as int? ?? 0,
      lockStock: json['lockStock'] as int? ?? 0,
      saleStock: json['saleStock'] as int? ?? 0,
    );
  }
}

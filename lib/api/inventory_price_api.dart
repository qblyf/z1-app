import '../models/inventory_price.dart';
import 'api_client.dart';

final inventoryPriceApi = InventoryPriceApi();

class InventoryPriceApi {
  final ApiClient _client = ApiClient();

  /// 库存价格列表
  /// 后端 GET /product-warehouse/price-statistics
  Future<List<StockPriceItem>> list({
    List<int>? warehouseIds,
    List<int>? skuIds,
    bool includeNoStock = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (warehouseIds != null && warehouseIds.isNotEmpty) 'warehouseIDs': warehouseIds.join(','),
      if (skuIds != null && skuIds.isNotEmpty) 'skuIDs': skuIds.join(','),
      'isGetNoStockSku': includeNoStock,
      'limit': limit,
      'offset': offset,
    };
    // 后端 GET /product-warehouse/price-statistics
    // 返回 { code, res: [...] }
    final res = await _client.get('/product-warehouse/price-statistics', queryParameters: queryParams);
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => StockPriceItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 库存价格总数
  /// 后端 GET /product-warehouse/price-statistics-count
  Future<int> count({
    List<int>? warehouseIds,
    List<int>? skuIds,
    bool includeNoStock = false,
  }) async {
    final queryParams = <String, dynamic>{
      if (warehouseIds != null && warehouseIds.isNotEmpty) 'warehouseIDs': warehouseIds.join(','),
      if (skuIds != null && skuIds.isNotEmpty) 'skuIDs': skuIds.join(','),
      'isGetNoStockSku': includeNoStock,
    };
    // 后端 GET /product-warehouse/price-statistics-count
    // 返回 { code, res: N }
    final res = await _client.get('/product-warehouse/price-statistics-count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }
}

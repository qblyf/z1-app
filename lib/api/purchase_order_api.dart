import 'api_client.dart';
import '../models/purchase_order.dart';

/// 采购订单 API
/// 后端路径: /purchase/*
class PurchaseOrderApi {
  final ApiClient _client = ApiClient();

  /// 查询采购订单列表
  /// 后端 GET /purchase/list，返回 { code, list: [...] }
  Future<List<PurchaseOrder>> list({
    List<int>? vendorIDs,
    List<int>? warehouseIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minUpdateAt,
    int? maxUpdateAt,
    List<int>? statusValues,
    List<int>? typeValues,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (vendorIDs != null && vendorIDs.isNotEmpty) {
      queryParams['vendorIDs'] = vendorIDs;
    }
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (minUpdateAt != null) queryParams['minUpdateAt'] = minUpdateAt;
    if (maxUpdateAt != null) queryParams['maxUpdateAt'] = maxUpdateAt;
    if (statusValues != null && statusValues.isNotEmpty) {
      queryParams['statusValues'] = statusValues;
    }
    if (typeValues != null && typeValues.isNotEmpty) {
      queryParams['typeValues'] = typeValues;
    }

    // 后端 GET /purchase/list，返回 { code, list: [...] }
    final res = await _client.get('/purchase/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取采购订单详情
  /// 后端 GET /purchase/detail，返回 { code, res: { ... } }
  Future<PurchaseOrder?> detail(int orderID) async {
    final res = await _client.get(
      '/purchase/detail',
      queryParameters: {'id': orderID},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return PurchaseOrder.fromJson(data);
  }

  /// 获取采购订单数量
  /// 后端 GET /purchase/count，返回 { code, res: N }
  Future<int> count({
    List<int>? vendorIDs,
    List<int>? warehouseIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? statusValues,
  }) async {
    final queryParams = <String, dynamic>{};
    if (vendorIDs != null && vendorIDs.isNotEmpty) {
      queryParams['vendorIDs'] = vendorIDs;
    }
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (statusValues != null && statusValues.isNotEmpty) {
      queryParams['statusValues'] = statusValues;
    }

    // 后端 GET /purchase/count，返回 { code, res: N }
    final res = await _client.get('/purchase/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 取消采购订单
  /// 后端 POST /purchase/cancel
  Future<bool> cancel(int orderID, {String? remarks}) async {
    final body = <String, dynamic>{
      'purchaseOrderID': orderID,
    };
    if (remarks != null) body['remarks'] = remarks;
    final res = await _client.post('/purchase/cancel', data: body);
    return res.data['code'] == 10000;
  }

  /// 审核通过采购订单
  /// 后端 POST /purchase-order/unaudit-to-audit，返回 { code, res: { rowCount } }
  Future<bool> audit(int orderID) async {
    final res = await _client.post(
      '/purchase-order/unaudit-to-audit',
      data: {'id': orderID},
    );
    final r = res.data['res'];
    return (r is Map) ? ((r['rowCount'] as int? ?? 0) > 0) : false;
  }

  /// 驳回采购订单
  /// 后端 POST /purchase-order/unaudit-to-reject，返回 { code, res: { rowCount } }
  Future<bool> reject(int orderID, {String? reason}) async {
    final body = <String, dynamic>{
      'id': orderID,
    };
    if (reason != null && reason.isNotEmpty) body['remarks'] = reason;
    final res = await _client.post(
      '/purchase-order/unaudit-to-reject',
      data: body,
    );
    final r = res.data['res'];
    return (r is Map) ? ((r['rowCount'] as int? ?? 0) > 0) : false;
  }
}

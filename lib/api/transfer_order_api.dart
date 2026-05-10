import 'api_client.dart';
import '../models/transfer_order.dart';

/// 调拨单 API
/// 后端路径: /transfer/*
class TransferOrderApi {
  final ApiClient _client = ApiClient();

  /// 查询调拨单列表
  /// 后端 GET /transfer/list，返回 { code, list: [...] }
  Future<List<TransferOrder>> list({
    List<int>? fromDepartmentIDs,
    List<int>? toDepartmentIDs,
    List<int>? warehouseIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? statusValues,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (fromDepartmentIDs != null && fromDepartmentIDs.isNotEmpty) {
      queryParams['fromDepartmentIDs'] = fromDepartmentIDs;
    }
    if (toDepartmentIDs != null && toDepartmentIDs.isNotEmpty) {
      queryParams['toDepartmentIDs'] = toDepartmentIDs;
    }
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (statusValues != null && statusValues.isNotEmpty) {
      queryParams['statusValues'] = statusValues;
    }

    // 后端 GET /transfer/list，返回 { code, list: [...] }
    final res = await _client.get('/transfer/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => TransferOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取调拨单详情
  /// 后端 GET /transfer/detail，返回 { code, res: { ... } }
  Future<TransferOrder?> detail(int orderID) async {
    final res = await _client.get(
      '/transfer/detail',
      queryParameters: {'id': orderID},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return TransferOrder.fromJson(data);
  }

  /// 获取调拨单数量
  /// 后端 GET /transfer/count，返回 { code, res: N }
  Future<int> count({
    List<int>? fromDepartmentIDs,
    List<int>? toDepartmentIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? statusValues,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fromDepartmentIDs != null && fromDepartmentIDs.isNotEmpty) {
      queryParams['fromDepartmentIDs'] = fromDepartmentIDs;
    }
    if (toDepartmentIDs != null && toDepartmentIDs.isNotEmpty) {
      queryParams['toDepartmentIDs'] = toDepartmentIDs;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (statusValues != null && statusValues.isNotEmpty) {
      queryParams['statusValues'] = statusValues;
    }

    // 后端 GET /transfer/count，返回 { code, res: N }
    final res = await _client.get('/transfer/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 审核通过调拨单
  /// 后端 POST /transfer/confirm，返回 { code, res: true }
  Future<bool> audit(int transferID, {int? inWarehouseID}) async {
    final body = <String, dynamic>{
      'transferID': transferID,
    };
    if (inWarehouseID != null) body['inWarehouseID'] = inWarehouseID;
    final res = await _client.post('/transfer/confirm', data: body);
    return res.data['res'] == true;
  }

  /// 拒绝调拨单
  /// 后端 POST /item/transfer-order/reject，返回 { code, res: true }
  Future<bool> reject(int transferID, {String? reason}) async {
    final body = <String, dynamic>{
      'transferID': transferID,
    };
    if (reason != null && reason.isNotEmpty) body['remarks'] = reason;
    final res = await _client.post('/item/transfer-order/reject', data: body);
    return res.data['res'] == true;
  }

  /// 创建调拨单（快速调拨/面对面调拨）
  /// 后端 POST /transfer/add，返回调拨单ID
  Future<int?> addFast({
    required int outWarehouseId,
    required List<Map<String, dynamic>> goodsInfo,
    String? remarks,
    int status = 1,
  }) async {
    final body = <String, dynamic>{
      'outWarehouseID': outWarehouseId,
      'goodsInfo': goodsInfo,
      'status': status,
    };
    if (remarks != null) body['remarks'] = remarks;

    final res = await _client.post('/transfer/add', data: body);
    final id = res.data['res'];
    return id is int ? id : null;
  }
}

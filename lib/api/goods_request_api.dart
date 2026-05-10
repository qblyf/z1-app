import 'api_client.dart';
import '../models/goods_request.dart';

/// 报货单 API
/// 后端路径: /goods-request/*
class GoodsRequestApi {
  final ApiClient _client = ApiClient();

  /// 查询报货单列表
  /// 后端 GET /goods-request/list，返回 { code, list: [...] }
  Future<List<GoodsRequest>> list({
    List<int>? departmentIDs,
    List<int>? skuIDs,
    String? status,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'orderBy': [
        {'key': 'createdAt', 'sort': 'desc'}
      ],
    };
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }
    if (skuIDs != null && skuIDs.isNotEmpty) {
      queryParams['skuIDs'] = skuIDs;
    }
    if (status != null) queryParams['status'] = status;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    // 后端 GET /goods-request/list，返回 { code, list: [...] }
    final res = await _client.get('/goods-request/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => GoodsRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取报货单数量
  /// 后端 GET /goods-request/count，返回 { code, res: N }
  Future<int> count({
    List<int>? departmentIDs,
    String? status,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{};
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }
    if (status != null) queryParams['status'] = status;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    // 后端 GET /goods-request/count
    final res = await _client.get('/goods-request/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 创建报货单
  Future<List<int>> add({
    required int departmentID,
    required List<Map<String, dynamic>> goodsrequestInfo,
  }) async {
    final res = await _client.post('/goods-request/add', data: {
      'departmentID': departmentID,
      'goodsrequestInfo': goodsrequestInfo,
    });
    final data = res.data['res'];
    if (data is List) return data.cast<int>();
    return [];
  }

  /// 废弃报货单
  Future<bool> deprecate({
    required List<int> goodsRequestIDs,
    required String deprecatedRemarks,
  }) async {
    final res = await _client.post('/goods-request/deprecate', data: {
      'goodsRequestIDs': goodsRequestIDs,
      'deprecatedRemarks': deprecatedRemarks,
    });
    return res.data['code'] == 10000;
  }
}

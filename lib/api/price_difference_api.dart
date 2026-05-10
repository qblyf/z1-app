import 'api_client.dart';
import '../models/price_difference.dart';

/// 差异调整单 API
/// 后端路径: /price-difference/*
class PriceDifferenceApi {
  final ApiClient _client = ApiClient();

  /// 查询差异调整单列表
  /// 后端 GET /price-difference/list，返回 { code, list: [...] }
  Future<List<PriceDifference>> list({
    List<int>? departmentIDs,
    List<int>? statusValues,
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
    if (statusValues != null && statusValues.isNotEmpty) {
      queryParams['statusValues'] = statusValues;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    // 后端 GET /price-difference/list，返回 { code, list: [...] }
    final res = await _client.get('/price-difference/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => PriceDifference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取差异调整单详情
  /// 后端 GET /price-difference/details，返回 { code, list: [...] }
  Future<PriceDifference?> detail(int id) async {
    final res = await _client.get(
      '/price-difference/details',
      queryParameters: {'priceDifferenceIDs': id.toString()},
    );
    final data = res.data['list'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return PriceDifference.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 获取差异调整单数量
  /// 后端 GET /price-difference/count，返回 { code, count: N }
  Future<int> count({
    List<int>? departmentIDs,
    List<int>? statusValues,
  }) async {
    final queryParams = <String, dynamic>{};
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }
    if (statusValues != null && statusValues.isNotEmpty) {
      queryParams['statusValues'] = statusValues;
    }
    // 后端 GET /price-difference/count，返回 { code, count: N }
    final res = await _client.get('/price-difference/count', queryParameters: queryParams);
    return res.data['count'] as int? ?? 0;
  }

  /// 审核
  Future<bool> audit(int id) async {
    final res = await _client.post('/price-difference/audit', data: {
      'priceDifferenceID': id,
    });
    return res.data['code'] == 10000;
  }
}

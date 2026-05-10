import 'api_client.dart';
import '../models/sales.dart';

/// 销售查询 API
/// 后端: /order/* 系列接口
class SalesApi {
  final ApiClient _client = ApiClient();

  /// 查询销售单列表
  /// 后端 GET /order/list，返回 { code, res: { res: [...] } }
  Future<List<SalesOrder>> list({
    List<int>? departmentIDs,
    List<int>? typeValues,
    List<int>? statusValues,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      body['departmentIDs'] = departmentIDs;
    }
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    if (minCreatedAt != null) body['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) body['maxCreatedAt'] = maxCreatedAt;

    // 后端 GET /order/list，返回 { code, res: { res: [...] } }
    final res = await _client.get('/order/list', queryParameters: body);
    final data = res.data;
    // 后端返回 { code, res: { res: [...] } }，需取嵌套的 res
    final orderRes = (data['res'] as Map<String, dynamic>?)?['res'] as List<dynamic>?;
    if (orderRes == null) return [];
    return orderRes
        .map((e) => SalesOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取销售单详情
  Future<SalesOrder?> detail(int orderID) async {
    final res = await _client.get(
      '/order/list',
      queryParameters: {'ids': orderID.toString()},
    );
    final data = res.data;
    // { code, res: { res: [...] } }
    final orderRes = (data['res'] as Map<String, dynamic>?)?['res'] as List<dynamic>?;
    if (orderRes == null || orderRes.isEmpty) return null;
    return SalesOrder.fromJson(orderRes[0] as Map<String, dynamic>);
  }

  /// 获取销售单数量
  /// 后端 GET /order/count，返回 { code, res: { res: N } }
  Future<int> count({
    List<int>? departmentIDs,
    List<int>? statusValues,
  }) async {
    final body = <String, dynamic>{};
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      body['departmentIDs'] = departmentIDs;
    }
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    // 后端 GET /order/count
    final res = await _client.get('/order/count', queryParameters: body);
    final data = res.data;
    // { code, res: { res: N } }
    final orderRes = (data['res'] as Map<String, dynamic>?)?['res'];
    return orderRes as int? ?? 0;
  }
}

import '../models/price_adjustment.dart';
import 'api_client.dart';

final priceAdjustmentApi = PriceAdjustmentApi();

class PriceAdjustmentApi {
  final ApiClient _client = ApiClient();

  /// 调价单列表
  /// 后端 GET /price-adjustment/list，返回 { code, res: [...] }
  Future<List<PriceAdjustment>> list({
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? spuIds,
    List<int>? spuCateIds,
    List<int>? productIds,
    String? number,
    List<int>? status,
    List<int>? types,
    List<int>? departmentIds,
    String? remarks,
    List<int>? createdByIdents,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (spuIds != null && spuIds.isNotEmpty) 'spuIDs': spuIds.join(','),
      if (spuCateIds != null && spuCateIds.isNotEmpty) 'spuCateIDs': spuCateIds.join(','),
      if (productIds != null && productIds.isNotEmpty) 'productIDs': productIds.join(','),
      if (number != null && number.isNotEmpty) 'numbers': number,
      if (status != null && status.isNotEmpty) 'status': status.join(','),
      if (types != null && types.isNotEmpty) 'types': types.join(','),
      if (departmentIds != null && departmentIds.isNotEmpty) 'departmentIDs': departmentIds.join(','),
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      if (createdByIdents != null && createdByIdents.isNotEmpty) 'createdByIdent': createdByIdents.join(','),
      'limit': limit,
      'offset': offset,
    };
    // 后端 GET /price-adjustment/list，返回 { code, res: [...] }
    final res = await _client.get('/price-adjustment/list', queryParameters: queryParams);
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => PriceAdjustment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 调价单总数
  /// 后端 GET /price-adjustment/count，返回 { code, res: N }
  Future<int> count({
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? spuIds,
    List<int>? spuCateIds,
    List<int>? productIds,
    String? number,
    List<int>? status,
    List<int>? types,
    List<int>? departmentIds,
    String? remarks,
    List<int>? createdByIdents,
  }) async {
    final queryParams = <String, dynamic>{
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (spuIds != null && spuIds.isNotEmpty) 'spuIDs': spuIds.join(','),
      if (spuCateIds != null && spuCateIds.isNotEmpty) 'spuCateIDs': spuCateIds.join(','),
      if (productIds != null && productIds.isNotEmpty) 'productIDs': productIds.join(','),
      if (number != null && number.isNotEmpty) 'numbers': number,
      if (status != null && status.isNotEmpty) 'status': status.join(','),
      if (types != null && types.isNotEmpty) 'types': types.join(','),
      if (departmentIds != null && departmentIds.isNotEmpty) 'departmentIDs': departmentIds.join(','),
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      if (createdByIdents != null && createdByIdents.isNotEmpty) 'createdByIdent': createdByIdents.join(','),
    };
    final res = await _client.get('/price-adjustment/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 调价单详情
  /// 后端 GET /price-adjustment/detail?priceAdjustmentIDs=X
  /// 返回 { code, list: [...] }
  Future<PriceAdjustment> detail(int priceAdjustmentId) async {
    // 后端 GET /price-adjustment/detail 返回 { code, list: [...] }
    final res = await _client.get(
      '/price-adjustment/detail',
      queryParameters: {'priceAdjustmentIDs': priceAdjustmentId.toString()},
    );
    final list = (res.data['list'] as List?) ?? [];
    if (list.isEmpty) throw Exception('调价单不存在');
    return PriceAdjustment.fromJson(list[0] as Map<String, dynamic>);
  }

  /// 审核调价单
  Future<bool> audit(int priceAdjustmentId) async {
    final body = <String, dynamic>{'priceAdjustmentID': priceAdjustmentId};
    final res = await _client.post('/price-adjustment/audit', data: body);
    return (res.data['rowCount'] as int? ?? 0) == 1;
  }

  /// 驳回调价单
  Future<bool> reject(int priceAdjustmentId) async {
    final body = <String, dynamic>{'priceAdjustmentID': priceAdjustmentId};
    final res = await _client.post('/price-adjustment/reject-audit', data: body);
    return (res.data['rowCount'] as int? ?? 0) == 1;
  }
}

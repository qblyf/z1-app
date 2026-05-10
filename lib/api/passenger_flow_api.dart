import 'api_client.dart';
import '../models/passenger_flow.dart';

/// 门店客流 API
/// 后端路径: /store-passenger-flow/*
class PassengerFlowApi {
  final ApiClient _client = ApiClient();

  /// 查询客流统计列表
  Future<List<PassengerFlow>> list({
    List<int>? storeIDs,
    int? minDate,
    int? maxDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (storeIDs != null && storeIDs.isNotEmpty) body['storeIDs'] = storeIDs;
    if (minDate != null) body['minDate'] = minDate;
    if (maxDate != null) body['maxDate'] = maxDate;

    final res = await _client.get(
      '/store-passenger-flow/list',
      queryParameters: body,
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => PassengerFlow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取客流统计数量
  Future<int> count({
    List<int>? storeIDs,
    int? minDate,
    int? maxDate,
  }) async {
    final body = <String, dynamic>{};
    if (storeIDs != null && storeIDs.isNotEmpty) body['storeIDs'] = storeIDs;
    if (minDate != null) body['minDate'] = minDate;
    if (maxDate != null) body['maxDate'] = maxDate;

    final res = await _client.get('/store-passenger-flow/count', queryParameters: body);
    return res.data['res'] as int? ?? 0;
  }
}

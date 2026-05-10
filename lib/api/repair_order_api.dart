import 'api_client.dart';
import '../models/repair_order.dart';

class RepairOrderApi {
  final _client = ApiClient();

  /// 维修单列表
  Future<List<RepairOrder>> list({
    int? departmentID,
    RepairState? state,
    String? repairType,
    int limit = 20,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (departmentID != null) body['departmentID'] = departmentID;
    if (state != null) body['repairState'] = state.value;
    if (repairType != null) body['repairType'] = repairType;

    final res = await _client.get(
      '/order-repair/list',
      queryParameters: body,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => RepairOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 维修单数量
  Future<int> count({int? departmentID, RepairState? state, String? repairType}) async {
    final body = <String, dynamic>{};
    if (departmentID != null) body['departmentID'] = departmentID;
    if (state != null) body['repairState'] = state.value;
    if (repairType != null) body['repairType'] = repairType;

    final res = await _client.get('/order-repair/count', queryParameters: body);
    return (res.data['res'] as int?) ?? 0;
  }

  /// 维修单详情
  Future<RepairOrder?> detail(int id) async {
    final res = await _client.get('/order-repair/detail', queryParameters: {'id': id});
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return RepairOrder.fromJson(data);
  }
}

import 'api_client.dart';
import '../models/zform.dart';

/// ZForm（电子表单）API
/// 对接 z1-mid 后端
class ZFormApi {
  final _client = ApiClient();

  /// 获取表格表单详情（含字段定义）
  /// GET /table-form/detail?tableID=X
  Future<ZForm> getFormDetail(int tableId) async {
    final response = await _client.get(
      '/table-form/detail',
      queryParameters: {'tableID': tableId},
    );
    final res = response.data['res'];
    if (res is Map<String, dynamic>) {
      return ZForm.fromJson(res);
    }
    throw Exception('未找到表单详情');
  }

  /// 获取当前用户提交的表单记录列表
  /// GET /table-rows/list-by-user?tableID=X
  Future<List<ZFormRecord>> getSubmittedRecords(int tableId) async {
    final response = await _client.get(
      '/table-rows/list-by-user',
      queryParameters: {'tableID': tableId},
    );
    final list = response.data['res'] as List<dynamic>? ?? [];
    return list.map((e) => ZFormRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 新增表单记录
  /// POST /table-rows/add，body: { tableID, fields: [{ columnID, value }] }
  Future<bool> addRecord(int tableId, List<Map<String, dynamic>> fields) async {
    final response = await _client.post(
      '/table-rows/add',
      data: {
        'tableID': tableId,
        'fields': fields,
      },
    );
    return response.data['code'] == 10000 || response.data['code'] == 0;
  }

  /// 编辑表单记录
  /// POST /table-rows/edit，body: { id, fields: [{ columnID, value }] }
  Future<bool> editRecord(int recordId, List<Map<String, dynamic>> fields) async {
    final response = await _client.post(
      '/table-rows/edit',
      data: {
        'id': recordId,
        'fields': fields,
      },
    );
    return response.data['code'] == 10000 || response.data['code'] == 0;
  }

  /// 获取表单记录详情
  /// GET /table-rows/detail?id=X
  Future<ZFormRecord?> getRecordDetail(int recordId) async {
    final response = await _client.get(
      '/table-rows/detail',
      queryParameters: {'id': recordId},
    );
    final res = response.data['res'];
    if (res is Map<String, dynamic>) {
      return ZFormRecord.fromJson(res);
    }
    return null;
  }
}

import 'api_client.dart';
import '../models/display_case.dart';

/// 展台展位 API
/// 对应后端 display-case 系列接口
class DisplayCaseApi {
  final ApiClient _client = ApiClient();

  // ================================================================
  // 查询
  // ================================================================

  /// 展台展位列表
  /// GET /display-case/list
  Future<List<DisplayCase>> list({
    List<int>? departmentIDs,
    List<int>? standardIDs,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final queryParams = <String, dynamic>{};
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }
    if (standardIDs != null && standardIDs.isNotEmpty) {
      queryParams['standardIDs'] = standardIDs;
    }
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (orderBy != null) queryParams['orderBy'] = orderBy;

    final res = await _client.get('/display-case/list',
        queryParameters: queryParams);
    final result = res.data['res'] as List<dynamic>? ?? [];
    return result
        .map((e) => DisplayCase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 展台展位总数
  /// GET /display-case/count
  Future<int> count({
    List<int>? departmentIDs,
    List<int>? standardIDs,
  }) async {
    final queryParams = <String, dynamic>{};
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }
    if (standardIDs != null && standardIDs.isNotEmpty) {
      queryParams['standardIDs'] = standardIDs;
    }

    final res = await _client.get('/display-case/count',
        queryParameters: queryParams);
    final result = res.data['res'];
    return result as int? ?? 0;
  }

  /// 展台展位详情
  /// GET /display-case/detail
  Future<DisplayCase?> detail(int id) async {
    final res = await _client.get('/display-case/detail',
        queryParameters: {'id': id});
    final result = res.data['res'] as Map<String, dynamic>?;
    if (result == null || result.isEmpty) return null;
    return DisplayCase.fromJson(result);
  }

  // ================================================================
  // 操作
  // ================================================================

  /// 新增展台展位
  /// POST /display-case/add
  Future<bool> add({
    required String name,
    required int departmentID,
    required int standardID,
    List<String>? imgs,
    String? remarks,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'departmentID': departmentID,
      'standardID': standardID,
    };
    if (imgs != null) data['imgs'] = imgs;
    if (remarks != null) data['remarks'] = remarks;

    final res = await _client.post('/display-case/add', data: data);
    return res.data['code'] == 10000;
  }

  /// 编辑展台展位
  /// POST /display-case/edit
  Future<bool> edit({
    required int id,
    int? departmentID,
    int? standardID,
    List<String>? imgs,
    String? remarks,
  }) async {
    final data = <String, dynamic>{'id': id};
    if (departmentID != null) data['departmentID'] = departmentID;
    if (standardID != null) data['standardID'] = standardID;
    if (imgs != null) data['imgs'] = imgs;
    if (remarks != null) data['remarks'] = remarks;

    final res = await _client.post('/display-case/edit', data: data);
    return res.data['code'] == 10000;
  }

  /// 删除展台展位
  /// POST /display-case/delete
  Future<bool> delete(List<int> ids) async {
    final res = await _client.post('/display-case/delete', data: {'ids': ids});
    return res.data['code'] == 10000;
  }
}

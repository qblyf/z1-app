import 'api_client.dart';
import '../models/display_standard.dart';

/// 展陈标准 API
/// 对应后端 display-standard 系列接口
class DisplayStandardApi {
  final ApiClient _client = ApiClient();

  /// 展陈标准列表
  /// GET /display-standard/list
  Future<List<DisplayStandard>> list({
    List<int>? ids,
    List<int>? cateIDs,
    String? type,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final queryParams = <String, dynamic>{};
    if (ids != null && ids.isNotEmpty) queryParams['ids'] = ids;
    if (cateIDs != null && cateIDs.isNotEmpty) queryParams['cateIDs'] = cateIDs;
    if (type != null) queryParams['type'] = type;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (orderBy != null) queryParams['orderBy'] = orderBy;

    final res = await _client.get('/display-standard/list',
        queryParameters: queryParams);
    final result = res.data['res'] as List<dynamic>? ?? [];
    return result
        .map((e) => DisplayStandard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 展陈标准总数
  /// GET /display-standard/count
  Future<int> count({
    List<int>? cateIDs,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (cateIDs != null && cateIDs.isNotEmpty) queryParams['cateIDs'] = cateIDs;
    if (type != null) queryParams['type'] = type;

    final res = await _client.get('/display-standard/count',
        queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 展陈标准详情
  /// GET /display-standard/detail
  Future<DisplayStandard?> detail(int id) async {
    final res = await _client.get('/display-standard/detail',
        queryParameters: {'id': id});
    final result = res.data['res'] as Map<String, dynamic>?;
    if (result == null || result.isEmpty) return null;
    return DisplayStandard.fromJson(result);
  }

  /// 新增展陈标准
  /// POST /display-standard/add
  Future<bool> add({
    required String name,
    required int cateID,
    required String type,
    int? length,
    int? width,
    int? height,
    String? material,
    List<String>? imgs,
    String? remarks,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'cateID': cateID,
      'type': type,
    };
    if (length != null) data['length'] = length;
    if (width != null) data['width'] = width;
    if (height != null) data['height'] = height;
    if (material != null) data['material'] = material;
    if (imgs != null) data['imgs'] = imgs;
    if (remarks != null) data['remarks'] = remarks;

    final res = await _client.post('/display-standard/add', data: data);
    return res.data['code'] == 10000;
  }

  /// 编辑展陈标准
  /// POST /display-standard/edit
  Future<bool> edit({
    required int id,
    String? name,
    int? cateID,
    String? type,
    int? length,
    int? width,
    int? height,
    String? material,
    List<String>? imgs,
    String? remarks,
  }) async {
    final data = <String, dynamic>{'id': id};
    if (name != null) data['name'] = name;
    if (cateID != null) data['cateID'] = cateID;
    if (type != null) data['type'] = type;
    if (length != null) data['length'] = length;
    if (width != null) data['width'] = width;
    if (height != null) data['height'] = height;
    if (material != null) data['material'] = material;
    if (imgs != null) data['imgs'] = imgs;
    if (remarks != null) data['remarks'] = remarks;

    final res = await _client.post('/display-standard/edit', data: data);
    return res.data['code'] == 10000;
  }

  /// 删除展陈标准
  /// POST /display-standard/delete
  Future<bool> delete(List<int> ids) async {
    final res = await _client.post('/display-standard/delete', data: {'ids': ids});
    return res.data['code'] == 10000;
  }
}

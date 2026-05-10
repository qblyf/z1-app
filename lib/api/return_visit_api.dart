import 'api_client.dart';
import '../models/return_visit.dart';

/// 客户回访 API
/// 对应后端 /return-visit/* API (p=z1func)
class ReturnVisitApi {
  final ApiClient _client = ApiClient();

  /// 获取回访列表
  /// GET /return-visit/list
  Future<List<ReturnVisit>> list({
    List<String>? type,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? employees,
    List<String>? status,
    String? orderNumber,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      if (limit > 0) 'limit': limit,
      if (offset > 0) 'offset': offset,
    };
    if (type != null && type.isNotEmpty) params['type'] = type.join(',');
    if (minCreatedAt != null) params['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) params['maxCreatedAt'] = maxCreatedAt;
    if (employees != null && employees.isNotEmpty) params['employees'] = employees.join(',');
    if (status != null && status.isNotEmpty) params['status'] = status.join(',');
    if (orderNumber != null && orderNumber.isNotEmpty) params['orderNumber'] = orderNumber;

    final res = await _client.get('/return-visit/list', queryParameters: params);
    final data = res.data;
    if (data is List) {
      return data.map((e) => ReturnVisit.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取回访总数
  /// GET /return-visit/count
  Future<int> count({
    List<String>? type,
    int? minCreatedAt,
    int? maxCreatedAt,
    List<int>? employees,
    List<String>? status,
    String? orderNumber,
  }) async {
    final params = <String, dynamic>{};
    if (type != null && type.isNotEmpty) params['type'] = type.join(',');
    if (minCreatedAt != null) params['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) params['maxCreatedAt'] = maxCreatedAt;
    if (employees != null && employees.isNotEmpty) params['employees'] = employees.join(',');
    if (status != null && status.isNotEmpty) params['status'] = status.join(',');
    if (orderNumber != null && orderNumber.isNotEmpty) params['orderNumber'] = orderNumber;

    final res = await _client.get('/return-visit/count', queryParameters: params);
    final data = res.data;
    if (data is int) return data;
    if (data is Map) return data['res'] as int? ?? 0;
    return 0;
  }

  /// 获取回访详情
  /// GET /return-visit/detail?number={number}
  Future<ReturnVisit?> detail(String number) async {
    final res = await _client.get(
      '/return-visit/detail',
      queryParameters: {'number': number},
    );
    final data = res.data;
    if (data is List && data.isNotEmpty) {
      return ReturnVisit.fromJson(data[0] as Map<String, dynamic>);
    }
    return null;
  }

  /// 我的回访列表
  /// GET /return-visit/my-list
  Future<List<ReturnVisit>> myList({
    String? type,
    String? status,
    String? orderNumber,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      if (limit > 0) 'limit': limit,
      if (offset > 0) 'offset': offset,
    };
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (orderNumber != null && orderNumber.isNotEmpty) params['orderNumber'] = orderNumber;

    final res = await _client.get('/return-visit/my-list', queryParameters: params);
    final data = res.data;
    if (data is List) {
      return data.map((e) => ReturnVisit.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 添加回访记录
  /// POST /return-visit/add-record
  Future<bool> addRecord({
    required int id,
    required String content,
    required String method,
    int? createdAt,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'record': {
        'content': content,
        'method': method,
        if (createdAt != null) 'createdAt': createdAt,
      },
    };

    final res = await _client.post('/return-visit/add-record', data: body);
    final data = res.data;
    if (data is bool) return data;
    if (data is Map) return data['res'] as bool? ?? false;
    return false;
  }

  /// 修改回访状态
  /// POST /return-visit/edit-status
  Future<bool> editStatus({required int id, required String status}) async {
    final body = <String, dynamic>{
      'id': id,
      'status': status,
    };

    final res = await _client.post('/return-visit/edit-status', data: body);
    final data = res.data;
    if (data is bool) return data;
    if (data is Map) return data['res'] as bool? ?? false;
    return false;
  }
}

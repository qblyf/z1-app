import 'api_client.dart';
import '../models/send_notice.dart';

/// 客户提醒（发送通知）API
/// 对应后端 /send-notice/* API (p=z1func)
class SendNoticeApi {
  final ApiClient _client = ApiClient();

  /// 获取提醒列表
  /// GET /send-notice/list
  Future<List<SendNotice>> list({
    String? number,
    List<String>? types,
    List<int>? createdBy,
    List<String>? status,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minSendAt,
    int? maxSendAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      if (limit > 0) 'limit': limit,
      if (offset > 0) 'offset': offset,
    };
    if (number != null && number.isNotEmpty) params['number'] = number;
    if (types != null && types.isNotEmpty) params['types'] = types.join(',');
    if (createdBy != null && createdBy.isNotEmpty) params['createdBy'] = createdBy.join(',');
    if (status != null && status.isNotEmpty) params['status'] = status.join(',');
    if (minCreatedAt != null) params['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) params['maxCreatedAt'] = maxCreatedAt;
    if (minSendAt != null) params['minSendAt'] = minSendAt;
    if (maxSendAt != null) params['maxSendAt'] = maxSendAt;

    final res = await _client.get('/send-notice/list', queryParameters: params);
    final data = res.data;
    if (data is List) {
      return data.map((e) => SendNotice.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取提醒总数
  /// GET /send-notice/count
  Future<int> count({
    String? number,
    List<String>? types,
    List<int>? createdBy,
    List<String>? status,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minSendAt,
    int? maxSendAt,
  }) async {
    final params = <String, dynamic>{};
    if (number != null && number.isNotEmpty) params['number'] = number;
    if (types != null && types.isNotEmpty) params['types'] = types.join(',');
    if (createdBy != null && createdBy.isNotEmpty) params['createdBy'] = createdBy.join(',');
    if (status != null && status.isNotEmpty) params['status'] = status.join(',');
    if (minCreatedAt != null) params['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) params['maxCreatedAt'] = maxCreatedAt;
    if (minSendAt != null) params['minSendAt'] = minSendAt;
    if (maxSendAt != null) params['maxSendAt'] = maxSendAt;

    final res = await _client.get('/send-notice/count', queryParameters: params);
    final data = res.data;
    if (data is int) return data;
    if (data is Map) return data['res'] as int? ?? 0;
    return 0;
  }

  /// 获取提醒详情
  /// GET /send-notice/details
  Future<List<SendNotice>> detail({List<int>? ids}) async {
    final params = <String, dynamic>{};
    if (ids != null && ids.isNotEmpty) params['ids'] = ids.join(',');

    final res = await _client.get('/send-notice/details', queryParameters: params);
    final data = res.data;
    if (data is List) {
      return data.map((e) => SendNotice.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 创建提醒
  /// POST /send-notice/add
  Future<int> add({
    required String type,
    required String method,
    required int sendAt,
    required String info,
    required List<int> idents,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'method': method,
      'sendAt': sendAt,
      'info': info,
      'idents': idents,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    };

    final res = await _client.post('/send-notice/add', data: body);
    final data = res.data;
    if (data is int) return data;
    if (data is Map) return data['res'] as int? ?? 0;
    return 0;
  }

  /// 编辑提醒
  /// POST /send-notice/edit
  Future<bool> edit({
    required int id,
    String? type,
    String? method,
    int? sendAt,
    String? info,
    List<int>? idents,
    String? remarks,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (type != null) body['type'] = type;
    if (method != null) body['method'] = method;
    if (sendAt != null) body['sendAt'] = sendAt;
    if (info != null) body['info'] = info;
    if (idents != null) body['idents'] = idents;
    if (remarks != null) body['remarks'] = remarks;

    final res = await _client.post('/send-notice/edit', data: body);
    final data = res.data;
    if (data is bool) return data;
    if (data is Map) return data['res'] as bool? ?? false;
    return false;
  }

  /// 取消提醒
  /// POST /send-notice/cancel
  Future<bool> cancel({required List<int> ids, required String cancelRemarks}) async {
    final body = <String, dynamic>{
      'ids': ids,
      'cancelRemarks': cancelRemarks,
    };

    final res = await _client.post('/send-notice/cancel', data: body);
    final data = res.data;
    if (data is bool) return data;
    if (data is Map) return data['res'] as bool? ?? false;
    return false;
  }

  /// 完成提醒
  /// POST /send-notice/finish
  Future<bool> finish({required List<int> ids, String? remarks}) async {
    final body = <String, dynamic>{
      'ids': ids,
      if (remarks != null) 'remarks': remarks,
    };

    final res = await _client.post('/send-notice/finish', data: body);
    final data = res.data;
    if (data is bool) return data;
    if (data is Map) return data['res'] as bool? ?? false;
    return false;
  }
}

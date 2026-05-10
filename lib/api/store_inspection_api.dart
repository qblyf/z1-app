import 'api_client.dart';
import '../models/store_inspection.dart';

/// 门店巡店 API
/// 后端路径: /store-inspection/*
class StoreInspectionApi {
  final ApiClient _client = ApiClient();

  /// 查询巡店日志列表
  Future<List<StoreInspectionLog>> list({
    List<int>? statusValues,
    List<String>? types,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    if (types != null && types.isNotEmpty) body['types'] = types;
    if (minCreatedAt != null) body['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) body['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get(
      '/store-inspection/list',
      queryParameters: body,
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => StoreInspectionLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取巡店日志详情
  Future<StoreInspectionLog?> detail(int logID) async {
    final res = await _client.get(
      '/store-inspection/detail',
      queryParameters: {'id': logID},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return StoreInspectionLog.fromJson(data);
  }

  /// 获取巡店日志数量
  Future<int> count({
    List<int>? statusValues,
  }) async {
    final body = <String, dynamic>{};
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    final res = await _client.get('/store-inspection/count', queryParameters: body);
    return res.data['res'] as int? ?? 0;
  }

  // ==================== 巡店记录 API (/store-inspection-log/*) ====================

  /// 巡店记录列表
  /// GET /store-inspection-log/list
  Future<List<StoreInspectionLogDetail>> logList({
    String? storeInspectionType,
    List<int>? storeInspectionCate,
    List<int>? departmentIDs,
    List<String>? status,
    List<int>? createdBys,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minUpdatedAt,
    int? maxUpdatedAt,
    String? orderBy,
    int limit = 300,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (storeInspectionType != null) 'storeInspectionType': storeInspectionType,
      if (storeInspectionCate != null && storeInspectionCate.isNotEmpty)
        'storeInspectionCate': storeInspectionCate.join(','),
      if (departmentIDs != null && departmentIDs.isNotEmpty)
        'departmentIDs': departmentIDs.join(','),
      if (status != null && status.isNotEmpty) 'status': status.join(','),
      if (createdBys != null && createdBys.isNotEmpty)
        'createdBys': createdBys.join(','),
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (minUpdatedAt != null) 'minUpdatedAt': minUpdatedAt,
      if (maxUpdatedAt != null) 'maxUpdatedAt': maxUpdatedAt,
      if (orderBy != null) 'orderBy': orderBy,
    };
    final res = await _client.get('/store-inspection-log/list', queryParameters: params);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => StoreInspectionLogDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 巡店记录数量
  /// GET /store-inspection-log/count
  Future<int> logCount({
    String? storeInspectionType,
    List<int>? storeInspectionCate,
    List<int>? departmentIDs,
    List<String>? status,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final params = <String, dynamic>{
      if (storeInspectionType != null) 'storeInspectionType': storeInspectionType,
      if (storeInspectionCate != null && storeInspectionCate.isNotEmpty)
        'storeInspectionCate': storeInspectionCate.join(','),
      if (departmentIDs != null && departmentIDs.isNotEmpty)
        'departmentIDs': departmentIDs.join(','),
      if (status != null && status.isNotEmpty) 'status': status.join(','),
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };
    final res = await _client.get('/store-inspection-log/count', queryParameters: params);
    return res.data['res'] as int? ?? 0;
  }

  /// 巡店记录详情
  /// GET /store-inspection-log/detail
  Future<StoreInspectionLogDetail?> logDetail(int id) async {
    final res = await _client.get('/store-inspection-log/detail', queryParameters: {'id': id});
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return StoreInspectionLogDetail.fromJson(data);
  }

  /// 创建巡店记录
  /// POST /store-inspection-log/add
  Future<int> addLog({
    required int departmentID,
    required int storeInspectionID,
  }) async {
    final res = await _client.post('/store-inspection-log/add', data: {
      'departmentID': departmentID,
      'storeInspectionID': storeInspectionID,
    });
    return res.data['res'] as int? ?? 0;
  }

  /// 编辑巡店记录
  /// POST /store-inspection-log/edit-info
  Future<bool> editLog({
    required int logID,
    String? status,
    Map<String, dynamic>? summarize,
    List<int>? sendTo,
    int? correctBy,
    int? acceptedBy,
    int? reviewedBy,
    List<Map<String, dynamic>>? result,
    List<Map<String, dynamic>>? rectify,
  }) async {
    final body = <String, dynamic>{'logID': logID};
    if (status != null) body['status'] = status;
    if (summarize != null) body['summarize'] = summarize;
    if (sendTo != null) body['sendTo'] = sendTo;
    if (correctBy != null) body['correctBy'] = correctBy;
    if (acceptedBy != null) body['acceptedBy'] = acceptedBy;
    if (reviewedBy != null) body['reviewedBy'] = reviewedBy;
    if (result != null) body['result'] = result;
    if (rectify != null) body['rectify'] = rectify;
    final res = await _client.post('/store-inspection-log/edit-info', data: body);
    return res.data['res'] == true;
  }

  /// 驳回巡店记录
  /// POST /store-inspection-log/reject
  Future<bool> rejectLog(int id) async {
    final res = await _client.post('/store-inspection-log/reject', data: {'id': id});
    return res.data['res'] == true;
  }

  /// 验收巡店记录
  /// POST /store-inspection-log/accepte
  Future<bool> acceptLog({
    required int id,
    String? acceptanceComments,
    int? reviewedBy,
    List<int>? sendTo,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (acceptanceComments != null) body['acceptanceComments'] = acceptanceComments;
    if (reviewedBy != null) body['reviewedBy'] = reviewedBy;
    if (sendTo != null) body['sendTo'] = sendTo;
    final res = await _client.post('/store-inspection-log/accepte', data: body);
    return res.data['res'] == true;
  }

  /// 复核巡店记录
  /// POST /store-inspection-log/review
  Future<bool> reviewLog({
    required int id,
    String? reviewedComments,
    List<int>? sendTo,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (reviewedComments != null) body['reviewedComments'] = reviewedComments;
    if (sendTo != null) body['sendTo'] = sendTo;
    final res = await _client.post('/store-inspection-log/review', data: body);
    return res.data['res'] == true;
  }

  /// 获取巡店记录结果
  /// GET /store-inspection-log/get-result
  Future<List<StoreInspectionLogResult>> getResultByLogID(int logID) async {
    final res = await _client.get('/store-inspection-log/get-result', queryParameters: {'logID': logID});
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => StoreInspectionLogResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取巡店整改结果
  /// GET /store-inspection-log/get-rectify-result
  Future<List<StoreInspectionRectifyResult>> getRectifyResultByLogID(int logID) async {
    final res = await _client.get('/store-inspection-log/get-rectify-result', queryParameters: {'logID': logID});
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => StoreInspectionRectifyResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}

import 'dart:convert';
import 'package:z1_app/api/api_client.dart';

/// 通用草稿 API
/// 对应后端 /draft/*
class DraftApi {
  final ApiClient _client = ApiClient();

  /// 获取草稿单列表
  /// GET /draft/list
  Future<List<GeneralDraft>> list({
    List<String>? createdBys,
    List<int>? types,
    List<int>? inWarehouseIDs,
    List<int>? outWarehouseIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      if (createdBys != null && createdBys.isNotEmpty)
        'createdBys': createdBys,
      if (types != null && types.isNotEmpty) 'types': types,
      if (inWarehouseIDs != null && inWarehouseIDs.isNotEmpty)
        'inWarehouseIDs': inWarehouseIDs,
      if (outWarehouseIDs != null && outWarehouseIDs.isNotEmpty)
        'outWarehouseIDs': outWarehouseIDs,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get('/draft/list', queryParameters: params);
    final data = response.data['list'] as List<dynamic>? ??
                 response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => GeneralDraft.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取草稿单总数
  /// GET /draft/count
  Future<int> count({
    List<String>? createdBys,
    List<int>? types,
    List<int>? inWarehouseIDs,
    List<int>? outWarehouseIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final params = <String, dynamic>{
      if (createdBys != null && createdBys.isNotEmpty)
        'createdBys': createdBys,
      if (types != null && types.isNotEmpty) 'types': types,
      if (inWarehouseIDs != null && inWarehouseIDs.isNotEmpty)
        'inWarehouseIDs': inWarehouseIDs,
      if (outWarehouseIDs != null && outWarehouseIDs.isNotEmpty)
        'outWarehouseIDs': outWarehouseIDs,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    final response = await _client.get('/draft/count', queryParameters: params);
    return response.data['count'] as int? ?? 0;
  }

  /// 获取草稿详情
  /// GET /draft/detail?id=X
  Future<GeneralDraft?> getDetail(int id) async {
    final response = await _client.get('/draft/detail', queryParameters: {'id': id});
    final list = response.data['list'] ?? response.data['res'];
    if (list is List && list.isNotEmpty) {
      return GeneralDraft.fromJson(list[0] as Map<String, dynamic>);
    }
    return null;
  }

  /// 保存草稿（新建）
  /// POST /draft/add
  /// 返回新建的草稿ID
  Future<int> save({
    required String type,
    required List<int> users,
    required Map<String, dynamic> data,
    String? associated,
    String? remarks,
  }) async {
    final requestData = <String, dynamic>{
      'type': type,
      'users': users,
      'data': data,
    };
    if (associated != null) requestData['associated'] = associated;
    if (remarks != null) requestData['remarks'] = remarks;

    final response = await _client.post('/draft/add', data: requestData);
    final res = response.data['res'];
    if (res is int) return res;
    return 0;
  }

  /// 更新草稿
  /// POST /draft/edit
  Future<bool> update({
    required int id,
    List<int>? users,
    Map<String, dynamic>? data,
    String? associated,
    String? remarks,
  }) async {
    final requestData = <String, dynamic>{'id': id};
    if (users != null) requestData['users'] = users;
    if (data != null) requestData['data'] = data;
    if (associated != null) requestData['associated'] = associated;
    if (remarks != null) requestData['remarks'] = remarks;

    final response = await _client.post('/draft/edit', data: requestData);
    return response.data['res'] == true || response.data['code'] == 10000;
  }

  /// 合并调拨单草稿
  /// POST /draft/merged/transfer
  Future<int> mergeTransfer(List<int> draftIds) async {
    final response = await _client.post(
      '/draft/merged/transfer',
      data: {'draftIDs': draftIds},
    );
    final res = response.data['res'];
    if (res is int) return res;
    throw Exception('合并失败');
  }

  /// 删除草稿
  /// POST /draft/delete
  Future<bool> delete(List<int> draftIds) async {
    final response = await _client.post(
      '/draft/delete',
      data: {'ids': draftIds},
    );
    return response.data['res'] == true;
  }
}

/// 通用草稿类型枚举（字符串类型，用于 API）
enum DraftTypeStr {
  purchaseOrder('purchase-order', '采购订单'),
  transferOrder('transfer-order', '调拨订单');

  const DraftTypeStr(this.value, this.label);
  final String value;
  final String label;

  static DraftTypeStr? fromValue(String v) {
    for (final t in values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

/// 通用草稿类型枚举（旧版数值类型）
enum GeneralDraftType {
  standardTransfer(1, '标品调拨'),
  smartCallback(2, '智能回调'),
  smartDistribution(3, '智能配货'),
  quickTransfer(4, '快捷调拨'),
  groupTransfer(5, '组内调拨');

  final int value;
  final String label;
  const GeneralDraftType(this.value, this.label);

  static GeneralDraftType? fromValue(int v) {
    for (final t in values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

/// 通用草稿
class GeneralDraft {
  final int id;
  final int type;
  final String? data;
  final String createdBy;
  final int createdAt;
  final int updatedAt;
  /// 字符串类型（新版）
  final String? typeStr;
  /// 备注
  final String? remarks;
  /// 关联单号
  final String? associated;
  /// 创建人名称
  final String? creatorName;

  GeneralDraft({
    required this.id,
    required this.type,
    this.data,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.typeStr,
    this.remarks,
    this.associated,
    this.creatorName,
  });

  factory GeneralDraft.fromJson(Map<String, dynamic> json) {
    return GeneralDraft(
      id: json['id'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      data: json['data'] is String
          ? json['data'] as String
          : (json['data'] != null ? jsonEncode(json['data']) : null),
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      typeStr: json['typeStr'] as String? ?? json['type']?.toString(),
      remarks: json['remarks'] as String?,
      associated: json['associated'] as String?,
      creatorName: json['creatorName'] as String?,
    );
  }

  GeneralDraftType? get draftType => GeneralDraftType.fromValue(type);

  /// 字符串类型枚举
  DraftTypeStr? get draftTypeStr => typeStr != null ? DraftTypeStr.fromValue(typeStr!) : null;

  /// 格式化创建时间
  String get formattedCreatedAt {
    if (createdAt == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 提取入库仓库ID
  int? get inWarehouseId {
    final d = parseData();
    return d['inWarehouseID'] as int?;
  }

  /// 提取出库仓库ID
  int? get outWarehouseId {
    final d = parseData();
    return d['outWarehouseID'] as int?;
  }

  /// 解析 data 字段为 Map
  Map<String, dynamic> parseData() {
    if (data == null) return {};
    if (data!.startsWith('{')) {
      try {
        return Map<String, dynamic>.from(jsonDecode(data!) as Map);
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}

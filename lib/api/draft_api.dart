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

/// 通用草稿类型枚举
enum GeneralDraftType {
  标品调拨(1, '标品调拨'),
  智能回调(2, '智能回调'),
  智能配货(3, '智能配货'),
  快捷调拨(4, '快捷调拨'),
  组内调拨(5, '组内调拨');

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

  GeneralDraft({
    required this.id,
    required this.type,
    this.data,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeneralDraft.fromJson(Map<String, dynamic> json) {
    return GeneralDraft(
      id: json['id'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      data: json['data'] as String?,
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  GeneralDraftType? get draftType => GeneralDraftType.fromValue(type);

  /// 提取入库仓库ID
  int? get inWarehouseId {
    if (data == null) return null;
    try {
      final Map<String, dynamic> d = _parseData();
      return d['inWarehouseID'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// 提取出库仓库ID
  int? get outWarehouseId {
    if (data == null) return null;
    try {
      final Map<String, dynamic> d = _parseData();
      return d['outWarehouseID'] as int?;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _parseData() {
    if (data == null) return {};
    if (data!.startsWith('{')) {
      return Map<String, dynamic>.from(
        _parseJson(data!) ?? {},
      );
    }
    return {};
  }

  static Map<String, dynamic>? _parseJson(String s) {
    try {
      int i = 0;
      return _parseObject(s, i).$1;
    } catch (_) {
      return null;
    }
  }

  static (Map<String, dynamic>?, int) _parseObject(String s, int i) {
    final map = <String, dynamic>{};
    i++; // skip {
    while (i < s.length) {
      if (s[i] == '}') { i++; break; }
      if (s[i] == '"') {
        final (key, ni) = _parseString(s, i);
        i = ni;
        while (i < s.length && (s[i] == ' ' || s[i] == ':')) i++;
        final (value, ni2) = _parseValue(s, i);
        map[key] = value;
        i = ni2;
      } else {
        i++;
      }
    }
    return (map, i);
  }

  static (String, int) _parseString(String s, int i) {
    i++; // skip opening "
    final buf = StringBuffer();
    while (i < s.length) {
      if (s[i] == '"') { i++; break; }
      if (s[i] == '\\' && i + 1 < s.length) { i++; }
      buf.write(s[i]);
      i++;
    }
    return (buf.toString(), i);
  }

  static (dynamic, int) _parseValue(String s, int i) {
    while (i < s.length && (s[i] == ' ' || s[i] == ',')) i++;
    if (i >= s.length) return (null, i);
    if (s[i] == '"') {
      final (v, ni) = _parseString(s, i);
      return (v, ni);
    }
    if (s[i] == '{') return _parseObject(s, i);
    if (s[i] == '[') return _parseArray(s, i);
    if (s[i] == 't' && s.substring(i).startsWith('true')) return (true, i + 4);
    if (s[i] == 'f' && s.substring(i).startsWith('false')) return (false, i + 5);
    if (s[i] == 'n' && s.substring(i).startsWith('null')) return (null, i + 4);
    // number
    final start = i;
    while (i < s.length && (s[i].contains(RegExp(r'[0-9.eE+-]')))) i++;
    final numStr = s.substring(start, i);
    if (numStr.contains('.')) return (double.tryParse(numStr), i);
    return (int.tryParse(numStr), i);
  }

  static (List<dynamic>, int) _parseArray(String s, int i) {
    final list = <dynamic>[];
    i++; // skip [
    while (i < s.length) {
      if (s[i] == ']') { i++; break; }
      final (v, ni) = _parseValue(s, i);
      list.add(v);
      i = ni;
      while (i < s.length && (s[i] == ' ' || s[i] == ',')) i++;
    }
    return (list, i);
  }
}

import 'api_client.dart';
import '../models/task_management.dart';

/// 岗位任务 API
/// 后端路径: /task-allocation/*
class TaskManagementApi {
  final ApiClient _client = ApiClient();

  /// 查询任务分配列表
  Future<List<TaskAllocation>> listAllocations({
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (minCreatedAt != null) body['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) body['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/task-allocation/list', queryParameters: body);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => TaskAllocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 查询任务分配日志（员工执行记录）
  Future<List<TaskAllocationLog>> listLogs({
    List<int>? statusValues,
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
    if (minCreatedAt != null) body['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) body['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/task-allocation/list', queryParameters: body);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => TaskAllocationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取任务分配数量
  Future<int> countAllocations() async {
    final res = await _client.get('/task-allocation/count', queryParameters: {});
    return res.data['res'] as int? ?? 0;
  }

  /// 获取任务日志数量
  Future<int> countLogs({List<int>? statusValues}) async {
    final body = <String, dynamic>{};
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    final res = await _client.get('/task-allocation/count', queryParameters: body);
    return res.data['res'] as int? ?? 0;
  }

  // ── 任务统计 ──────────────────────────────────────────────

  /// 任务记录统计计数
  /// 后端 GET /task-log/count?statStartAt=X&statEndAt=X&giveBy=X
  /// 返回 Array<{ status: string, count: int }>
  Future<List<TaskLogCountItem>> taskLogCount({
    int? statStartAt,
    int? statEndAt,
    List<int>? giveBy,
  }) async {
    final queryParams = <String, dynamic>{
      if (statStartAt != null) 'statStartAt': statStartAt,
      if (statEndAt != null) 'statEndAt': statEndAt,
      if (giveBy != null && giveBy.isNotEmpty) 'giveBy': giveBy,
    };
    final res = await _client.get(
      '/task-log/count',
      queryParameters: queryParams,
    );
    final data = res.data;
    final list = data is List ? data : (data['res'] as List?);
    if (list == null) return [];
    return list.map((e) => TaskLogCountItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 任务记录统计明细
  /// 后端 GET /task-log/statistic?startAt=X&endAt=X&dimension=X&userIdents=X
  /// dimension: label=按标签, employee=按职员, taskTemplateCate=按分类
  /// 返回 Array<{ userIdent?, labelID?, taskTemplateCate?, statistic: [...] }>
  Future<List<TaskLogStatisticItem>> taskLogStatistic({
    int? startAt,
    int? endAt,
    List<int>? userIdents,
    required String dimension,
  }) async {
    final queryParams = <String, dynamic>{
      if (startAt != null) 'startAt': startAt,
      if (endAt != null) 'endAt': endAt,
      if (userIdents != null && userIdents.isNotEmpty) 'userIdents': userIdents,
      'dimension': dimension,
    };
    final res = await _client.get(
      '/task-log/statistic',
      queryParameters: queryParams,
    );
    final data = res.data;
    final list = data is List ? data : (data['res'] as List?);
    if (list == null) return [];
    return list.map((e) => TaskLogStatisticItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 任务记录统计计数项
class TaskLogCountItem {
  final String status;
  final int count;

  const TaskLogCountItem({required this.status, required this.count});

  factory TaskLogCountItem.fromJson(Map<String, dynamic> json) {
    return TaskLogCountItem(
      status: json['status'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

/// 任务记录统计明细项
class TaskLogStatisticItem {
  final int? userIdent;
  final int? labelID;
  final String? taskTemplateCate;
  final List<TaskLogCountItem> statistic;

  const TaskLogStatisticItem({
    this.userIdent,
    this.labelID,
    this.taskTemplateCate,
    required this.statistic,
  });

  factory TaskLogStatisticItem.fromJson(Map<String, dynamic> json) {
    final statList = json['statistic'];
    return TaskLogStatisticItem(
      userIdent: json['userIdent'] as int?,
      labelID: json['labelID'] as int?,
      taskTemplateCate: json['taskTemplateCate'] as String?,
      statistic: (statList is List)
          ? statList.map((e) => TaskLogCountItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

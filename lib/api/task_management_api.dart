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

  // ── 任务分配详情/编辑 ─────────────────────────────────────

  /// 获取任务分配详情
  /// GET /task-allocation/detail
  Future<TaskAllocationDetail?> getTaskAllocationDetail(int id) async {
    final res = await _client.get(
      '/task-allocation/detail',
      queryParameters: {'ids': id},
    );
    final data = res.data['res'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return TaskAllocationDetail.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 编辑任务分配
  /// POST /task-allocation/edit
  Future<bool> editTaskAllocation({
    required int id,
    int? startAt,
    int? endAt,
    int? duration,
    String? repeatCycle,
    List<int>? responsibleRoles,
    List<int>? responsibleEmployees,
    int? frequency,
    List<int>? giveDays,
    int? repeatNum,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (startAt != null) body['startAt'] = startAt;
    if (endAt != null) body['endAt'] = endAt;
    if (duration != null) body['duration'] = duration;
    if (repeatCycle != null) body['repeatCycle'] = repeatCycle;
    if (responsibleRoles != null) body['responsibleRoles'] = responsibleRoles;
    if (responsibleEmployees != null) body['responsibleEmployees'] = responsibleEmployees;
    if (frequency != null) body['frequency'] = frequency;
    if (giveDays != null) body['giveDays'] = giveDays;
    if (repeatNum != null) body['repeatNum'] = repeatNum;

    final res = await _client.post('/task-allocation/edit', data: body);
    return res.data['res'] == true;
  }

  // ── 任务模板 ───────────────────────────────────────────────

  /// 任务模板列表
  /// GET /task-template/list?limit=X&offset=X
  Future<List<TaskTemplate>> listTaskTemplates({
    List<int>? labelIDs,
    List<int>? createdBy,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (labelIDs != null && labelIDs.isNotEmpty) {
      queryParams['labelIDs'] = labelIDs;
    }
    if (createdBy != null && createdBy.isNotEmpty) {
      queryParams['createdBy'] = createdBy;
    }
    final res = await _client.get('/task-template/list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => TaskTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 任务模板总数
  /// GET /task-template/count
  Future<int> countTaskTemplates({List<int>? createdBy}) async {
    final queryParams = <String, dynamic>{};
    if (createdBy != null && createdBy.isNotEmpty) {
      queryParams['createdBy'] = createdBy;
    }
    final res = await _client.get('/task-template/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 任务模板详情
  /// GET /task-template/detail?ids=X
  Future<TaskTemplateDetail?> getTaskTemplateDetail(String id) async {
    final res = await _client.get(
      '/task-template/detail',
      queryParameters: {'ids': id},
    );
    final data = res.data['res'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return TaskTemplateDetail.fromJson(data[0] as Map<String, dynamic>);
  }

  /// 新增任务模板
  /// POST /task-template/add
  Future<bool> addTaskTemplate({
    required String taskTemplateCate,
    required String name,
    required int taskWeight,
    String? introduction,
    String? description,
    List<int>? labelIDs,
    String? allowCheckType,
    List<int>? allowCheckEmployees,
    bool? isNeedSelfEvaluation,
    List<String>? accessoriesUrls,
    List<int>? sendUser,
    int? responsibleStartRemind,
    int? responsibleEndRemind,
    int? checkStartRemind,
    String? selfEvaluationDesc,
  }) async {
    final body = <String, dynamic>{
      'taskTemplateCate': taskTemplateCate,
      'name': name,
      'taskWeight': taskWeight,
    };
    if (introduction != null) body['introduction'] = introduction;
    if (description != null) body['description'] = description;
    if (labelIDs != null && labelIDs.isNotEmpty) body['labelIDs'] = labelIDs;
    if (allowCheckType != null) body['allowCheckType'] = allowCheckType;
    if (allowCheckEmployees != null && allowCheckEmployees.isNotEmpty) {
      body['allowCheckEmployees'] = allowCheckEmployees;
    }
    if (isNeedSelfEvaluation != null) body['isNeedSelfEvaluation'] = isNeedSelfEvaluation;
    if (accessoriesUrls != null && accessoriesUrls.isNotEmpty) {
      body['accessoriesUrls'] = accessoriesUrls;
    }
    if (sendUser != null && sendUser.isNotEmpty) body['sendUser'] = sendUser;
    if (responsibleStartRemind != null) body['responsibleStartRemind'] = responsibleStartRemind;
    if (responsibleEndRemind != null) body['responsibleEndRemind'] = responsibleEndRemind;
    if (checkStartRemind != null) body['checkStartRemind'] = checkStartRemind;
    if (selfEvaluationDesc != null) body['selfEvaluationDesc'] = selfEvaluationDesc;

    final res = await _client.post('/task-template/add', data: body);
    return res.data['res'] != null;
  }

  /// 编辑任务模板
  /// POST /task-template/edit
  Future<bool> editTaskTemplate({
    required String id,
    String? taskTemplateCate,
    String? name,
    String? introduction,
    String? description,
    int? taskWeight,
    List<int>? labelIDs,
    String? allowCheckType,
    List<int>? allowCheckEmployees,
    bool? isNeedSelfEvaluation,
    List<String>? accessoriesUrls,
    List<int>? sendUser,
    String? status,
    int? responsibleStartRemind,
    int? responsibleEndRemind,
    int? checkStartRemind,
    String? selfEvaluationDesc,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (taskTemplateCate != null) body['taskTemplateCate'] = taskTemplateCate;
    if (name != null) body['name'] = name;
    if (introduction != null) body['introduction'] = introduction;
    if (description != null) body['description'] = description;
    if (taskWeight != null) body['taskWeight'] = taskWeight;
    if (labelIDs != null) body['labelIDs'] = labelIDs;
    if (allowCheckType != null) body['allowCheckType'] = allowCheckType;
    if (allowCheckEmployees != null) body['allowCheckEmployees'] = allowCheckEmployees;
    if (isNeedSelfEvaluation != null) body['isNeedSelfEvaluation'] = isNeedSelfEvaluation;
    if (accessoriesUrls != null) body['accessoriesUrls'] = accessoriesUrls;
    if (sendUser != null) body['sendUser'] = sendUser;
    if (status != null) body['status'] = status;
    if (responsibleStartRemind != null) body['responsibleStartRemind'] = responsibleStartRemind;
    if (responsibleEndRemind != null) body['responsibleEndRemind'] = responsibleEndRemind;
    if (checkStartRemind != null) body['checkStartRemind'] = checkStartRemind;
    if (selfEvaluationDesc != null) body['selfEvaluationDesc'] = selfEvaluationDesc;

    final res = await _client.post('/task-template/edit', data: body);
    return res.data['res'] == true;
  }

  /// 停用/启用任务模板
  /// POST /task-template/invalid
  Future<bool> invalidateTaskTemplate(String id, {bool disable = true}) async {
    final res = await _client.post(
      '/task-template/invalid',
      data: {'id': id, 'status': disable ? 'disabled' : 'enabled'},
    );
    return res.data['res'] == true;
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

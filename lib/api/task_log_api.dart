import 'package:flutter/cupertino.dart';
import 'api_client.dart';

/// 任务记录 API
/// 对应后端 /task-log/*
class TaskLogApi {
  final ApiClient _client = ApiClient();

  /// 任务记录列表
  /// GET /task-log/list
  Future<List<TaskLogItem>> list({
    List<String>? taskLogStatus,
    List<int>? taskTemplateIDs,
    int? limit,
    int? offset,
  }) async {
    final params = <String, dynamic>{};
    if (taskLogStatus != null && taskLogStatus.isNotEmpty) {
      params['taskLogStatus'] = taskLogStatus.join(',');
    }
    if (taskTemplateIDs != null && taskTemplateIDs.isNotEmpty) {
      params['taskTemplateIDs'] = taskTemplateIDs.join(',');
    }
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;

    final res = await _client.get('/task-log/list', queryParameters: params);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => TaskLogItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 任务记录详情
  /// GET /task-log/detail
  Future<TaskLogDetail?> detail(int taskLogId) async {
    final res = await _client.get(
      '/task-log/detail',
      queryParameters: {'taskLogID': taskLogId},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return TaskLogDetail.fromJson(data);
  }

  /// 任务记录统计
  /// GET /task-log/statistic
  Future<TaskLogStatistic> statistic() async {
    final res = await _client.get('/task-log/statistic');
    final data = res.data['res'] as Map<String, dynamic>?;
    return data == null
        ? const TaskLogStatistic(doingCount: 0, uncheckedCount: 0, finishedCount: 0, overdueCount: 0)
        : TaskLogStatistic.fromJson(data);
  }

  /// 任务记录模板分类统计
  /// GET /task-log/template-cate-statistic
  Future<List<TaskLogCateStatistic>> templateCateStatistic() async {
    final res = await _client.get('/task-log/template-cate-statistic');
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => TaskLogCateStatistic.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 完成任务记录（自评完成）
  /// POST /task-log/self-evaluation-finished
  Future<bool> selfEvaluationFinished({
    required int taskLogId,
    required int score,
    String? content,
    List<String>? accessories,
  }) async {
    final body = <String, dynamic>{
      'taskLogID': taskLogId,
      'score': score,
    };
    if (content != null) body['content'] = content;
    if (accessories != null) body['accessories'] = accessories;

    final res = await _client.post('/task-log/self-evaluation-finished', data: body);
    return res.data['code'] == 10000;
  }

  /// 验收任务记录
  /// POST /task-log/check
  Future<bool> check({
    required int taskLogId,
    required int score,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'taskLogID': taskLogId,
      'score': score,
    };
    if (remarks != null) body['remarks'] = remarks;

    final res = await _client.post('/task-log/check', data: body);
    return res.data['code'] == 10000;
  }

  /// 任务记录评论（抄送）
  /// POST /task-log/review
  Future<bool> review({required int taskLogId, required String content}) async {
    final res = await _client.post('/task-log/review', data: {
      'taskLogID': taskLogId,
      'content': content,
    });
    return res.data['code'] == 10000;
  }

  /// 预自评完成（仅保存，不修改状态）
  /// POST /task-log/pre-self-evaluation-finished
  Future<bool> preSelfEvaluationFinished({
    required int taskLogId,
    int? taskScore,
    String? selfEvaluationContent,
    List<String>? selfEvaluationAccessories,
  }) async {
    final body = <String, dynamic>{'id': taskLogId};
    if (taskScore != null) body['taskScore'] = taskScore;
    if (selfEvaluationContent != null) body['selfEvaluationContent'] = selfEvaluationContent;
    if (selfEvaluationAccessories != null) body['selfEvaluationAccessories'] = selfEvaluationAccessories;
    final res = await _client.post('/task-log/pre-self-evaluation-finished', data: body);
    return res.data['code'] == 10000;
  }

  /// 验收任务记录
  /// POST /task-log/check
  /// 通过: lastCheckResult=true → 已完成
  /// 驳回: lastCheckResult=false → 进行中
  Future<bool> checkTaskLog({
    required int taskLogId,
    int? checkScore,
    required String lastCheckRemarks,
    required bool lastCheckResult,
  }) async {
    final body = <String, dynamic>{
      'id': taskLogId,
      'lastCheckRemarks': lastCheckRemarks,
      'lastCheckResult': lastCheckResult,
    };
    if (checkScore != null) body['checkScore'] = checkScore;
    final res = await _client.post('/task-log/check', data: body);
    return res.data['code'] == 10000;
  }

  /// 获取文件上传凭证（返回上传URL）
  /// GET /upload/token
  Future<String> getUploadToken() async {
    final res = await _client.get('/upload/token');
    return res.data['res']?['token'] ?? '';
  }
}

/// 任务记录状态
enum TaskLogStatus {
  doing('doing', '进行中', Color(0xFFFF9500)),
  unchecked('unchecked', '待验收', Color(0xFFBF5AF2)),
  finished('finished', '已完成', Color(0xFF30D158)),
  overdueFinished('overdueFinished', '逾期完成', Color(0xFFFF9500)),
  unfinished('unfinished', '未完成', Color(0xFFFF3B30)),
  invalid('invalid', '停用', Color(0xFF8E8E93));

  final String value;
  final String label;
  final Color color;

  const TaskLogStatus(this.value, this.label, this.color);

  static TaskLogStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 任务记录列表项
class TaskLogItem {
  final int taskLogId;
  final String? taskTemplateName;
  final int? taskTemplateId;
  final String? taskTitle;
  final String? taskContent;
  final String taskLogStatus;
  final String? taskLogType;
  final String? employeeName;
  final int? employeeId;
  final String? departmentName;
  final int? startAt;
  final int? endAt;
  final int? completedAt;
  final int? taskScore;
  final int? checkScore;
  final int? selfScore;

  const TaskLogItem({
    required this.taskLogId,
    this.taskTemplateName,
    this.taskTemplateId,
    this.taskTitle,
    this.taskContent,
    required this.taskLogStatus,
    this.taskLogType,
    this.employeeName,
    this.employeeId,
    this.departmentName,
    this.startAt,
    this.endAt,
    this.completedAt,
    this.taskScore,
    this.checkScore,
    this.selfScore,
  });

  factory TaskLogItem.fromJson(Map<String, dynamic> json) {
    return TaskLogItem(
      taskLogId: json['taskLogID'] as int? ?? json['id'] as int? ?? 0,
      taskTemplateName: json['taskTemplateName'] as String?,
      taskTemplateId: json['taskTemplateID'] as int?,
      taskTitle: json['taskTitle'] as String?,
      taskContent: json['taskContent'] as String?,
      taskLogStatus: json['taskLogStatus'] as String? ?? '',
      taskLogType: json['taskLogType'] as String?,
      employeeName: json['employeeName'] as String?,
      employeeId: json['employeeID'] as int?,
      departmentName: json['departmentName'] as String?,
      startAt: json['startAt'] as int?,
      endAt: json['endAt'] as int?,
      completedAt: json['completedAt'] as int?,
      taskScore: json['taskScore'] as int?,
      checkScore: json['checkScore'] as int?,
      selfScore: json['selfScore'] as int?,
    );
  }

  TaskLogStatus? get status => TaskLogStatus.fromValue(taskLogStatus);

  String get formattedEndAt {
    if (endAt == null || endAt == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(endAt! * 1000);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 任务记录详情
class TaskLogDetail {
  final int taskLogId;

  // 任务模板信息
  final String? name; // 任务模板名称
  final String? introduction; // 任务简介
  final String? description; // 任务说明
  final int? taskWeight; // 任务权重
  final String? selfEvaluationDesc; // 自评说明
  final List<String>? accessoriesUrls; // 附件URL列表

  // 任务发放信息
  final int? giveStartAt; // 发放开始时间
  final int? giveEndAt; // 发放结束时间
  final int? startAt; // 任务开始时间
  final int? endAt; // 任务结束时间
  final int? duration; // 持续时间
  final String? repeatCycle; // 重复周期

  // 验收配置
  final String? allowCheckType; // 验收类型
  final List<int>? allowCheckEmployees; // 可验收员工ID列表
  final bool isNeedSelfEvaluation; // 是否需要自评

  // 任务记录状态
  final String taskLogStatus;
  final String? taskLogType;

  // 责任人信息
  final int? responsibleEmployee;
  final String? employeeName;
  final int? employeeId;
  final String? departmentName;

  // 评分信息
  final int? taskScore; // 任务得分
  final int? checkScore; // 验收得分
  final int? selfScore; // 自评得分
  final int? lastScore; // 最终得分

  // 自评信息
  final String? selfEvaluationContent; // 自评内容
  final List<String> selfEvaluationAccessories; // 自评附件
  final int? completedAt; // 完成时间

  // 验收信息
  final int? lastCheckBy; // 最后验收人
  final String? lastCheckByName;
  final String? lastCheckRemarks; // 验收备注

  // 其他
  final String? remarks;
  final int? taskAllocationId;
  final int? taskTemplateId;
  final int? taskAllocationID;
  final String? giveID;

  const TaskLogDetail({
    required this.taskLogId,
    this.name,
    this.introduction,
    this.description,
    this.taskWeight,
    this.selfEvaluationDesc,
    this.accessoriesUrls,
    this.giveStartAt,
    this.giveEndAt,
    this.startAt,
    this.endAt,
    this.duration,
    this.repeatCycle,
    this.allowCheckType,
    this.allowCheckEmployees,
    this.isNeedSelfEvaluation = false,
    required this.taskLogStatus,
    this.taskLogType,
    this.responsibleEmployee,
    this.employeeName,
    this.employeeId,
    this.departmentName,
    this.taskScore,
    this.checkScore,
    this.selfScore,
    this.lastScore,
    this.selfEvaluationContent,
    this.selfEvaluationAccessories = const [],
    this.completedAt,
    this.lastCheckBy,
    this.lastCheckByName,
    this.lastCheckRemarks,
    this.remarks,
    this.taskAllocationId,
    this.taskTemplateId,
    this.taskAllocationID,
    this.giveID,
  });

  factory TaskLogDetail.fromJson(Map<String, dynamic> json) {
    return TaskLogDetail(
      taskLogId: json['taskLogID'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String?,
      introduction: json['introduction'] as String?,
      description: json['description'] as String?,
      taskWeight: json['taskWeight'] as int?,
      selfEvaluationDesc: json['selfEvaluationDesc'] as String?,
      accessoriesUrls: (json['accessoriesUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      giveStartAt: json['giveStartAt'] as int?,
      giveEndAt: json['giveEndAt'] as int?,
      startAt: json['startAt'] as int?,
      endAt: json['endAt'] as int?,
      duration: json['duration'] as int?,
      repeatCycle: json['repeatCycle'] as String?,
      allowCheckType: json['allowCheckType'] as String?,
      allowCheckEmployees: (json['allowCheckEmployees'] as List<dynamic>?)
          ?.map((e) => (e is int) ? e : int.tryParse('$e') ?? 0)
          .toList(),
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      taskLogStatus: json['taskLogStatus'] as String? ?? '',
      taskLogType: json['taskLogType'] as String?,
      responsibleEmployee: json['responsibleEmployee'] as int?,
      employeeName: json['employeeName'] as String?,
      employeeId: json['employeeID'] as int?,
      departmentName: json['departmentName'] as String?,
      taskScore: json['taskScore'] as int?,
      checkScore: json['checkScore'] as int?,
      selfScore: json['selfScore'] as int?,
      lastScore: json['lastScore'] as int?,
      selfEvaluationContent: json['selfEvaluationContent'] as String?,
      selfEvaluationAccessories: (json['selfEvaluationAccessories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      completedAt: json['completedAt'] as int?,
      lastCheckBy: json['lastCheckBy'] as int?,
      lastCheckByName: json['lastCheckByName'] as String?,
      lastCheckRemarks: json['lastCheckRemarks'] as String?,
      remarks: json['remarks'] as String?,
      taskAllocationId: json['taskAllocationID'] as int?,
      taskTemplateId: json['taskTemplateID'] as int?,
      taskAllocationID: json['taskAllocationID'] as int?,
      giveID: json['giveID'] as String?,
    );
  }

  TaskLogStatus? get status => TaskLogStatus.fromValue(taskLogStatus);

  /// 是否已开始（当前时间超过开始时间）
  bool get hasStarted {
    if (startAt == null || startAt == 0) return false;
    return DateTime.now().millisecondsSinceEpoch > startAt! * 1000;
  }

  /// 是否需要自评
  bool get needSelfEvaluation => isNeedSelfEvaluation;

  /// 是否是已完成或逾期完成状态
  bool get isFinished =>
      taskLogStatus == 'finished' || taskLogStatus == 'overdueFinished';
}

/// 任务记录统计
class TaskLogStatistic {
  final int doingCount;
  final int uncheckedCount;
  final int finishedCount;
  final int overdueCount;

  const TaskLogStatistic({
    required this.doingCount,
    required this.uncheckedCount,
    required this.finishedCount,
    required this.overdueCount,
  });

  factory TaskLogStatistic.fromJson(Map<String, dynamic> json) {
    return TaskLogStatistic(
      doingCount: json['doingCount'] as int? ?? 0,
      uncheckedCount: json['uncheckedCount'] as int? ?? 0,
      finishedCount: json['finishedCount'] as int? ?? 0,
      overdueCount: json['overdueCount'] as int? ?? 0,
    );
  }

  int get total => doingCount + uncheckedCount + finishedCount + overdueCount;
}

/// 任务记录模板分类统计
class TaskLogCateStatistic {
  final String taskTemplateCate;
  final int count;

  const TaskLogCateStatistic({required this.taskTemplateCate, required this.count});

  factory TaskLogCateStatistic.fromJson(Map<String, dynamic> json) {
    return TaskLogCateStatistic(
      taskTemplateCate: json['taskTemplateCate'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

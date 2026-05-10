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
  final String? selfEvaluationContent;
  final List<String> selfEvaluationAccessories;
  final String? lastCheckRemarks;
  final String? lastCheckByName;
  final String? remarks;
  final int? taskAllocationId;
  final int? taskTemplateId;

  const TaskLogDetail({
    required this.taskLogId,
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
    this.selfEvaluationContent,
    this.selfEvaluationAccessories = const [],
    this.lastCheckRemarks,
    this.lastCheckByName,
    this.remarks,
    this.taskAllocationId,
    this.taskTemplateId,
  });

  factory TaskLogDetail.fromJson(Map<String, dynamic> json) {
    return TaskLogDetail(
      taskLogId: json['taskLogID'] as int? ?? json['id'] as int? ?? 0,
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
      selfEvaluationContent: json['selfEvaluationContent'] as String?,
      selfEvaluationAccessories: (json['selfEvaluationAccessories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastCheckRemarks: json['lastCheckRemarks'] as String?,
      lastCheckByName: json['lastCheckByName'] as String?,
      remarks: json['remarks'] as String?,
      taskAllocationId: json['taskAllocationID'] as int?,
      taskTemplateId: json['taskTemplateID'] as int?,
    );
  }

  TaskLogStatus? get status => TaskLogStatus.fromValue(taskLogStatus);
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

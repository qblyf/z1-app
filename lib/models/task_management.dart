import 'package:flutter/cupertino.dart';

/// 任务分配状态
enum TaskAllocationStatus {
  pending(1, '待执行', Color(0xFFFF9500)),
  inProgress(2, '执行中', Color(0xFF0A84FF)),
  pendingCheck(3, '待验收', Color(0xFFBF5AF2)),
  completed(4, '已完成', Color(0xFF30D158)),
  overdue(5, '已逾期', Color(0xFFFF3B30));

  final int value;
  final String label;
  final Color color;

  const TaskAllocationStatus(this.value, this.label, this.color);

  static TaskAllocationStatus fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 任务分配类型
enum TaskAllocationType {
  auto('auto', '自动'),
  manual('manual', '手动');

  final String value;
  final String label;

  const TaskAllocationType(this.value, this.label);

  static TaskAllocationType? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 任务分配
class TaskAllocation {
  final int id;
  final int taskTemplateID;
  final String? taskTemplateName;
  final int? startAt;
  final int? endAt;
  final int duration; // 小时
  final String repeatCycle; // no/day/week/month
  final TaskAllocationType type;
  final List<int> responsibleEmployeeIDs;
  final List<String?> responsibleEmployeeNames;
  final int? frequency;
  final List<int>? giveDays;
  final int? repeatNum;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int updatedAt;

  const TaskAllocation({
    required this.id,
    required this.taskTemplateID,
    this.taskTemplateName,
    this.startAt,
    this.endAt,
    required this.duration,
    required this.repeatCycle,
    required this.type,
    this.responsibleEmployeeIDs = const [],
    this.responsibleEmployeeNames = const [],
    this.frequency,
    this.giveDays,
    this.repeatNum,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskAllocation.fromJson(Map<String, dynamic> json) {
    return TaskAllocation(
      id: json['id'] as int? ?? 0,
      taskTemplateID: json['taskTemplateID'] as int? ?? 0,
      taskTemplateName: json['taskTemplateName'] as String?,
      startAt: json['startAt'] as int?,
      endAt: json['endAt'] as int?,
      duration: json['duration'] as int? ?? 0,
      repeatCycle: json['repeatCycle'] as String? ?? 'no',
      type: TaskAllocationType.fromValue(json['allocationType'] as String?) ?? TaskAllocationType.manual,
      responsibleEmployeeIDs: (json['responsibleEmployees'] as List<dynamic>?)?.cast<int>() ?? [],
      responsibleEmployeeNames: (json['responsibleEmployeeNames'] as List<dynamic>?)?.map((e) => e as String?).toList() ?? [],
      frequency: json['frequency'] as int?,
      giveDays: (json['giveDays'] as List<dynamic>?)?.cast<int>(),
      repeatNum: json['repeatNum'] as int?,
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  String get repeatCycleLabel {
    switch (repeatCycle) {
      case 'day': return '每天';
      case 'week': return '每周';
      case 'month': return '每月';
      default: return '不重复';
    }
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// 任务分配日志（员工执行记录）
class TaskAllocationLog {
  final int id;
  final int taskTemplateID;
  final String? taskTemplateName;
  final int taskAllocationID;
  final String? giveID;
  final int startAt;
  final int endAt;
  final String allowCheckType;
  final bool isNeedSelfEvaluation;
  final int giveTaskWeight;
  final String? employeeName;
  final int? employeeID;
  final String? departmentName;
  final TaskAllocationStatus status;
  final int? selfScore;
  final int? finalScore;
  final int? completedAt;

  const TaskAllocationLog({
    required this.id,
    required this.taskTemplateID,
    this.taskTemplateName,
    required this.taskAllocationID,
    this.giveID,
    required this.startAt,
    required this.endAt,
    required this.allowCheckType,
    required this.isNeedSelfEvaluation,
    required this.giveTaskWeight,
    this.employeeName,
    this.employeeID,
    this.departmentName,
    required this.status,
    this.selfScore,
    this.finalScore,
    this.completedAt,
  });

  factory TaskAllocationLog.fromJson(Map<String, dynamic> json) {
    return TaskAllocationLog(
      id: json['id'] as int? ?? 0,
      taskTemplateID: json['taskTemplateID'] as int? ?? 0,
      taskTemplateName: json['taskTemplateName'] as String?,
      taskAllocationID: json['taskAllocationID'] as int? ?? 0,
      giveID: json['giveID'] as String?,
      startAt: json['startAt'] as int? ?? 0,
      endAt: json['endAt'] as int? ?? 0,
      allowCheckType: json['allowCheckType'] as String? ?? '',
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      giveTaskWeight: json['giveTaskWeight'] as int? ?? 0,
      employeeName: json['employeeName'] as String?,
      employeeID: json['employeeID'] as int?,
      departmentName: json['departmentName'] as String?,
      status: TaskAllocationStatus.fromValue(json['status'] as int? ?? 1),
      selfScore: json['selfScore'] as int?,
      finalScore: json['finalScore'] as int?,
      completedAt: json['completedAt'] as int?,
    );
  }

  String get formattedStartAt => _format(startAt);
  String get formattedEndAt => _format(endAt);

  String _format(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

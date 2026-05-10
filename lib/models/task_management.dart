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

/// 任务分配详情（包含模板信息）
class TaskAllocationDetail {
  final int id;
  final int taskTemplateID;
  final String? taskName;
  final String? taskTemplateCate;
  final String? introduction;
  final List<int> labelIDs;
  final int? startAt; // 秒时间戳
  final int? endAt;
  final int duration; // 小时
  final String repeatCycle; // no/day/week/month
  final String allocationType; // auto/manual
  final List<int> responsibleRoles;
  final List<int> responsibleEmployees;
  final int? frequency;
  final List<int>? giveDays;
  final int? repeatNum;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int updatedAt;
  final bool isNeedSelfEvaluation;
  final String? allowCheckType;

  const TaskAllocationDetail({
    required this.id,
    required this.taskTemplateID,
    this.taskName,
    this.taskTemplateCate,
    this.introduction,
    this.labelIDs = const [],
    this.startAt,
    this.endAt,
    required this.duration,
    required this.repeatCycle,
    required this.allocationType,
    this.responsibleRoles = const [],
    this.responsibleEmployees = const [],
    this.frequency,
    this.giveDays,
    this.repeatNum,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.isNeedSelfEvaluation = false,
    this.allowCheckType,
  });

  factory TaskAllocationDetail.fromJson(Map<String, dynamic> json) {
    return TaskAllocationDetail(
      id: json['id'] as int? ?? 0,
      taskTemplateID: json['taskTemplateID'] as int? ?? 0,
      taskName: json['taskName'] as String?,
      taskTemplateCate: json['taskTemplateCate'] as String?,
      introduction: json['introduction'] as String?,
      labelIDs: (json['labelIDs'] as List<dynamic>?)?.cast<int>() ?? [],
      startAt: json['startAt'] as int?,
      endAt: json['endAt'] as int?,
      duration: json['duration'] as int? ?? 0,
      repeatCycle: json['repeatCycle'] as String? ?? 'no',
      allocationType: json['allocationType'] as String? ?? 'manual',
      responsibleRoles: (json['responsibleRoles'] as List<dynamic>?)?.cast<int>() ?? [],
      responsibleEmployees: (json['responsibleEmployees'] as List<dynamic>?)?.cast<int>() ?? [],
      frequency: json['frequency'] as int?,
      giveDays: (json['giveDays'] as List<dynamic>?)?.cast<int>(),
      repeatNum: json['repeatNum'] as int?,
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      allowCheckType: json['allowCheckType'] as String?,
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

  String get allocationTypeLabel => allocationType == 'auto' ? '定时分配' : '立即分配';

  String get formattedStartAt {
    if (startAt == null || startAt == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(startAt! * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedEndAt {
    if (endAt == null || endAt == 0) return '无限期';
    final dt = DateTime.fromMillisecondsSinceEpoch(endAt! * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    if (duration >= 24) {
      return '${(duration / 24).toStringAsFixed(0)}天';
    }
    return '${duration}小时';
  }
}

// ── 任务模板 ───────────────────────────────────────────────

/// 任务模板分类
enum TaskTemplateCate {
  goal('goal', '目标'),
  operation('operation', '运营'),
  training('training', '培训'),
  marketing('marketing', '营销');

  final String value;
  final String label;

  const TaskTemplateCate(this.value, this.label);

  static TaskTemplateCate? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 验收类型
enum AllowCheckType {
  currentLeader('currentLeader', '当前部门负责人'),
  higherLeader('higherLeader', '上级部门负责人'),
  designation('designation', '指定职员'),
  nocheck('nocheck', '不需要验收');

  final String value;
  final String label;

  const AllowCheckType(this.value, this.label);

  static AllowCheckType? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 任务模板列表项
class TaskTemplate {
  final String id;
  final String taskTemplateCate;
  final List<int> labelIDs;
  final String name;
  final int? giveStartAt;
  final int? giveEndAt;
  final String introduction;
  final String description;
  final String allowCheckType;
  final List<int> allowCheckEmployees;
  final bool isNeedSelfEvaluation;
  final int taskWeight;
  final String status;
  final List<String> accessoriesUrls;
  final List<int> sendUser;
  final int? responsibleStartRemind;
  final int? responsibleEndRemind;
  final int? checkStartRemind;
  final int createdAt;
  final int createdBy;
  final int updatedAt;
  final int updatedBy;
  final String selfEvaluationDesc;

  const TaskTemplate({
    required this.id,
    required this.taskTemplateCate,
    this.labelIDs = const [],
    required this.name,
    this.giveStartAt,
    this.giveEndAt,
    this.introduction = '',
    this.description = '',
    required this.allowCheckType,
    this.allowCheckEmployees = const [],
    this.isNeedSelfEvaluation = false,
    required this.taskWeight,
    required this.status,
    this.accessoriesUrls = const [],
    this.sendUser = const [],
    this.responsibleStartRemind,
    this.responsibleEndRemind,
    this.checkStartRemind,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.selfEvaluationDesc = '',
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] as String? ?? '',
      taskTemplateCate: json['taskTemplateCate'] as String? ?? '',
      labelIDs: (json['labelIDs'] as List<dynamic>?)?.cast<int>() ?? [],
      name: json['name'] as String? ?? '',
      giveStartAt: json['giveStartAt'] as int?,
      giveEndAt: json['giveEndAt'] as int?,
      introduction: json['introduction'] as String? ?? '',
      description: json['description'] as String? ?? '',
      allowCheckType: json['allowCheckType'] as String? ?? 'nocheck',
      allowCheckEmployees: (json['allowCheckEmployees'] as List<dynamic>?)?.cast<int>() ?? [],
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      taskWeight: json['taskWeight'] as int? ?? 0,
      status: json['status'] as String? ?? 'enabled',
      accessoriesUrls: (json['accessoriesUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sendUser: (json['sendUser'] as List<dynamic>?)?.cast<int>() ?? [],
      responsibleStartRemind: json['responsibleStartRemind'] as int?,
      responsibleEndRemind: json['responsibleEndRemind'] as int?,
      checkStartRemind: json['checkStartRemind'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      selfEvaluationDesc: json['selfEvaluationDesc'] as String? ?? '',
    );
  }

  TaskTemplateCate? get cate => TaskTemplateCate.fromValue(taskTemplateCate);
  AllowCheckType? get checkType => AllowCheckType.fromValue(allowCheckType);
  bool get isEnabled => status == 'enabled';

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// 任务模板详情
class TaskTemplateDetail {
  final String id;
  final String taskTemplateCate;
  final List<int> labelIDs;
  final String name;
  final int? giveStartAt;
  final int? giveEndAt;
  final String introduction;
  final String description;
  final String allowCheckType;
  final List<int> allowCheckEmployees;
  final bool isNeedSelfEvaluation;
  final int taskWeight;
  final String status;
  final List<String> accessoriesUrls;
  final List<int> sendUser;
  final int? responsibleStartRemind;
  final int? responsibleEndRemind;
  final int? checkStartRemind;
  final int createdAt;
  final int createdBy;
  final int updatedAt;
  final int updatedBy;
  final String selfEvaluationDesc;

  const TaskTemplateDetail({
    required this.id,
    required this.taskTemplateCate,
    this.labelIDs = const [],
    required this.name,
    this.giveStartAt,
    this.giveEndAt,
    this.introduction = '',
    this.description = '',
    required this.allowCheckType,
    this.allowCheckEmployees = const [],
    this.isNeedSelfEvaluation = false,
    required this.taskWeight,
    required this.status,
    this.accessoriesUrls = const [],
    this.sendUser = const [],
    this.responsibleStartRemind,
    this.responsibleEndRemind,
    this.checkStartRemind,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.selfEvaluationDesc = '',
  });

  factory TaskTemplateDetail.fromJson(Map<String, dynamic> json) {
    return TaskTemplateDetail(
      id: json['id'] as String? ?? '',
      taskTemplateCate: json['taskTemplateCate'] as String? ?? '',
      labelIDs: (json['labelIDs'] as List<dynamic>?)?.cast<int>() ?? [],
      name: json['name'] as String? ?? '',
      giveStartAt: json['giveStartAt'] as int?,
      giveEndAt: json['giveEndAt'] as int?,
      introduction: json['introduction'] as String? ?? '',
      description: json['description'] as String? ?? '',
      allowCheckType: json['allowCheckType'] as String? ?? 'nocheck',
      allowCheckEmployees: (json['allowCheckEmployees'] as List<dynamic>?)?.cast<int>() ?? [],
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      taskWeight: json['taskWeight'] as int? ?? 0,
      status: json['status'] as String? ?? 'enabled',
      accessoriesUrls: (json['accessoriesUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sendUser: (json['sendUser'] as List<dynamic>?)?.cast<int>() ?? [],
      responsibleStartRemind: json['responsibleStartRemind'] as int?,
      responsibleEndRemind: json['responsibleEndRemind'] as int?,
      checkStartRemind: json['checkStartRemind'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      selfEvaluationDesc: json['selfEvaluationDesc'] as String? ?? '',
    );
  }

  TaskTemplateCate? get cate => TaskTemplateCate.fromValue(taskTemplateCate);
  AllowCheckType? get checkType => AllowCheckType.fromValue(allowCheckType);
  bool get isEnabled => status == 'enabled';

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

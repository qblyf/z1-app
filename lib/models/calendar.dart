import 'package:equatable/equatable.dart';

/// 行事历状态
enum CalendarStatus {
  pending('待执行', 1),
  inProgress('进行中', 2),
  completed('已完成', 3),
  cancelled('已取消', 4),
  expired('已过期', 5);

  const CalendarStatus(this.label, this.value);
  final String label;
  final int value;
}

/// 行事历任务模型
class CalendarTask extends Equatable {
  final String id;
  final String? taskLogID; // 任务记录ID (my-check-calendar 返回 taskLogID)
  final String title;
  final String? description;
  final int? departmentId;
  final String? departmentName;
  final int assignee;
  final String? assigneeName;
  final int creator;
  final String? creatorName;
  final int startTime;
  final int endTime;
  final int status;
  final int? checkInTime; // 签到时间
  final int? checkOutTime; // 签退时间
  final String? location;
  final String? remark;
  final List<CalendarAttachment>? attachments;
  final List<CalendarParticipant>? participants;
  final int createdAt;
  final int updatedAt;

  const CalendarTask({
    required this.id,
    this.taskLogID,
    required this.title,
    this.description,
    this.departmentId,
    this.departmentName,
    required this.assignee,
    this.assigneeName,
    required this.creator,
    this.creatorName,
    required this.startTime,
    required this.endTime,
    this.status = 1,
    this.checkInTime,
    this.checkOutTime,
    this.location,
    this.remark,
    this.attachments,
    this.participants,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  /// 获取用于跳转任务日志详情的ID，优先使用 taskLogID，否则使用 id
  String get taskLogIdent => taskLogID ?? id;

  factory CalendarTask.fromJson(Map<String, dynamic> json) {
    // taskLogID 可能是 String 或 int，统一转为 String
    final taskLogIdRaw = json['taskLogID'] ?? json['taskLogId'] ?? json['taskLogID'];
    String taskLogIdStr = '';
    if (taskLogIdRaw != null) {
      taskLogIdStr = taskLogIdRaw is int ? taskLogIdRaw.toString() : taskLogIdRaw.toString();
    }
    return CalendarTask(
      id: json['id']?.toString() ?? json['p']?.toString() ?? taskLogIdStr,
      taskLogID: taskLogIdStr.isNotEmpty ? taskLogIdStr : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      departmentId: json['departmentId'] as int? ?? json['department_id'] as int?,
      departmentName: json['departmentName'] as String? ?? json['department_name'] as String?,
      assignee: json['assignee'] as int? ?? 0,
      assigneeName: json['assigneeName'] as String? ?? json['assignee_name'] as String?,
      creator: json['creator'] as int? ?? 0,
      creatorName: json['creatorName'] as String? ?? json['creator_name'] as String?,
      startTime: json['startTime'] as int? ?? json['start_time'] as int? ?? 0,
      endTime: json['endTime'] as int? ?? json['end_time'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
      checkInTime: json['checkInTime'] as int? ?? json['check_in_time'] as int?,
      checkOutTime: json['checkOutTime'] as int? ?? json['check_out_time'] as int?,
      location: json['location'] as String?,
      remark: json['remark'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => CalendarAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => CalendarParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? json['updated_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskLogID': taskLogID,
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'assignee': assignee,
      'assigneeName': assigneeName,
      'creator': creator,
      'creatorName': creatorName,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'location': location,
      'remark': remark,
      'attachments': attachments?.map((e) => e.toJson()).toList(),
      'participants': participants?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 获取状态标签
  String get statusLabel {
    switch (status) {
      case 1:
        return '待执行';
      case 2:
        return '进行中';
      case 3:
        return '已完成';
      case 4:
        return '已取消';
      case 5:
        return '已过期';
      default:
        return '未知';
    }
  }

  /// 是否已签到
  bool get isCheckedIn => checkInTime != null && checkInTime! > 0;

  /// 是否已签退
  bool get isCheckedOut => checkOutTime != null && checkOutTime! > 0;

  @override
  List<Object?> get props => [id, title, assignee, startTime, status, taskLogID];
}

/// 行事历详情（含任务日志全字段）
/// 对应 PWA CalendarDetail 类型，组合 Task + TaskLog + TaskGiveLog
/// 用于行事历详情页展示
class CalendarDetail extends Equatable {
  // === 任务基本信息 ===
  final String name;              // 任务名称
  final String taskLogStatus;     // 任务记录状态
  final List<int> labelIDs;       // 任务标签ID列表
  final String introduction;      // 任务简介
  final String description;        // 详细说明
  final int duration;             // 持续时长（小时）
  final List<int> responsibleRoles;    // 责任角色ID列表
  final List<int> responsibleEmployees; // 责任职员ID列表
  final List<String> accessoriesUrls;  // 任务附件URL

  // === 发放信息 ===
  final int startAt;              // 开始发放时间
  final int? endAt;              // 结束发放时间
  final String allowCheckType;    // 验收类型: currentLeader/higherLeader/designation/nocheck
  final bool isNeedSelfEvaluation; // 是否需要自评
  final int? giveTaskWeight;      // 任务权重
  final int responsibleEmployee;   // 当前责任人标识符

  // === 任务记录信息 ===
  final int taskLogID;           // 任务记录ID
  final int? taskScore;          // 任务打分(1-5)
  final int? checkScore;         // 验收打分(1-5)
  final String? selfEvaluationContent; // 自评文字
  final List<String> selfEvaluationAccessories; // 自评附件
  final int? lastCheckBy;        // 最后验收人
  final String? lastCheckRemarks; // 验收评论
  final int? lastScore;           // 最终得分（已完成时显示）
  final List<int> readUser;      // 已读用户列表
  final int? taskCreatedAt;      // 任务创建时间
  final int? taskCreatedBy;      // 任务创建人
  final int? taskUpdatedAt;      // 任务更新时间
  final int? taskUpdatedBy;       // 任务更新人

  // === 附加信息 ===
  final String? categoryName;    // 项目/分类名称

  const CalendarDetail({
    required this.name,
    required this.taskLogStatus,
    this.labelIDs = const [],
    this.introduction = '',
    this.description = '',
    this.duration = 0,
    this.responsibleRoles = const [],
    this.responsibleEmployees = const [],
    this.accessoriesUrls = const [],
    required this.startAt,
    this.endAt,
    this.allowCheckType = 'nocheck',
    this.isNeedSelfEvaluation = false,
    this.giveTaskWeight,
    required this.responsibleEmployee,
    required this.taskLogID,
    this.taskScore,
    this.checkScore,
    this.selfEvaluationContent,
    this.selfEvaluationAccessories = const [],
    this.lastCheckBy,
    this.lastCheckRemarks,
    this.lastScore,
    this.readUser = const [],
    this.taskCreatedAt,
    this.taskCreatedBy,
    this.taskUpdatedAt,
    this.taskUpdatedBy,
    this.categoryName,
  });

  factory CalendarDetail.fromJson(Map<String, dynamic> json) {
    List<int> parseIntList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      return [];
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return CalendarDetail(
      name: json['name'] as String? ?? '',
      taskLogStatus: json['taskLogStatus'] as String? ?? '',
      labelIDs: parseIntList(json['labelIDs']),
      introduction: json['introduction'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      responsibleRoles: parseIntList(json['responsibleRoles']),
      responsibleEmployees: parseIntList(json['responsibleEmployees']),
      accessoriesUrls: parseStringList(json['accessoriesUrls']),
      startAt: json['startAt'] as int? ?? 0,
      endAt: json['endAt'] as int?,
      allowCheckType: json['allowCheckType'] as String? ?? 'nocheck',
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      giveTaskWeight: json['giveTaskWeight'] as int?,
      responsibleEmployee: json['responsibleEmployee'] as int? ?? 0,
      taskLogID: json['taskLogID'] as int? ?? 0,
      taskScore: json['taskScore'] as int?,
      checkScore: json['checkScore'] as int?,
      selfEvaluationContent: json['selfEvaluationContent'] as String?,
      selfEvaluationAccessories: parseStringList(json['selfEvaluationAccessories']),
      lastCheckBy: json['lastCheckBy'] as int?,
      lastCheckRemarks: json['lastCheckRemarks'] as String?,
      lastScore: json['lastScore'] as int?,
      readUser: parseIntList(json['readUser']),
      taskCreatedAt: json['taskCreatedAt'] as int?,
      taskCreatedBy: json['taskCreatedBy'] as int?,
      taskUpdatedAt: json['taskUpdatedAt'] as int?,
      taskUpdatedBy: json['taskUpdatedBy'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  /// 格式化持续时长
  String get formattedDuration {
    final days = duration ~/ 24;
    final hours = duration % 24;
    return '${days > 0 ? '${days}天' : ''}${hours > 0 ? '${hours}小时' : ''}'.trim();
  }

  /// 验收类型标签
  String get allowCheckTypeLabel {
    switch (allowCheckType) {
      case 'currentLeader': return '当前部门负责人';
      case 'higherLeader': return '上级部门负责人';
      case 'designation': return '指定验收人';
      case 'nocheck': return '不需要验收';
      default: return allowCheckType;
    }
  }

  /// 任务记录状态标签
  String get taskLogStatusLabel {
    switch (taskLogStatus) {
      case '待验收': return '待验收';
      case '进行中': return '进行中';
      case '已完成': return '已完成';
      case '未完成': return '未完成';
      default: return taskLogStatus;
    }
  }

  @override
  List<Object?> get props => [taskLogID, name, taskLogStatus];
}

/// 行事历附件
class CalendarAttachment extends Equatable {
  final String id;
  final String name;
  final String url;
  final String? thumbnailUrl;
  final int size;
  final String type;

  const CalendarAttachment({
    required this.id,
    required this.name,
    required this.url,
    this.thumbnailUrl,
    this.size = 0,
    this.type = 'file',
  });

  factory CalendarAttachment.fromJson(Map<String, dynamic> json) {
    return CalendarAttachment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      size: json['size'] as int? ?? 0,
      type: json['type'] as String? ?? 'file',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'size': size,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, url];
}

/// 行事历参与人
class CalendarParticipant extends Equatable {
  final int userId;
  final String? userName;
  final String? avatar;
  final int status; // 1: 待确认, 2: 已确认, 3: 已拒绝

  const CalendarParticipant({
    required this.userId,
    this.userName,
    this.avatar,
    this.status = 1,
  });

  factory CalendarParticipant.fromJson(Map<String, dynamic> json) {
    return CalendarParticipant(
      userId: json['userId'] as int? ?? json['user_id'] as int? ?? 0,
      userName: json['userName'] as String? ?? json['user_name'] as String?,
      avatar: json['avatar'] as String?,
      status: json['status'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
      'status': status,
    };
  }

  String get statusLabel {
    switch (status) {
      case 1:
        return '待确认';
      case 2:
        return '已确认';
      case 3:
        return '已拒绝';
      default:
        return '未知';
    }
  }

  @override
  List<Object?> get props => [userId, status];
}

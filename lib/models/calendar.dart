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

  factory CalendarTask.fromJson(Map<String, dynamic> json) {
    return CalendarTask(
      id: json['id'] as String? ?? json['p'] as String? ?? '',
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
  List<Object?> get props => [id, title, assignee, startTime, status];
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

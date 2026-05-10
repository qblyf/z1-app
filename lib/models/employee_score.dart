import 'package:equatable/equatable.dart';
import 'dart:ui';

/// 员工积分/工分模型
/// 对应后端 z1-mid 的 department-employee-score 系列接口

/// 积分分类
class ScoreClass extends Equatable {
  final int id;
  final String name;
  final String? icon;
  final int? maxScore;
  final int? minScore;

  const ScoreClass({
    required this.id,
    required this.name,
    this.icon,
    this.maxScore,
    this.minScore,
  });

  factory ScoreClass.fromJson(Map<String, dynamic> json) {
    return ScoreClass(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      maxScore: json['maxScore'] as int?,
      minScore: json['minScore'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// 积分申报单
class ScoreApply extends Equatable {
  final int id;
  final String? title;
  final int classId;
  final String? className;
  final int creatorId;
  final String? creatorName;
  final int departmentId;
  final String? departmentName;
  final int status; // 1=待确认 2=已确认 3=已拒绝
  final int happenedAt; // 发生时间
  final String? description; // 事件描述
  final List<ScoreApplyItem> items; // 申报明细
  final int createdAt;
  final int? confirmedAt;
  final int? confirmedBy;
  final String? confirmedName;

  const ScoreApply({
    required this.id,
    this.title,
    required this.classId,
    this.className,
    required this.creatorId,
    this.creatorName,
    required this.departmentId,
    this.departmentName,
    required this.status,
    required this.happenedAt,
    this.description,
    this.items = const [],
    required this.createdAt,
    this.confirmedAt,
    this.confirmedBy,
    this.confirmedName,
  });

  factory ScoreApply.fromJson(Map<String, dynamic> json) {
    return ScoreApply(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String?,
      classId: json['classID'] as int? ?? json['classId'] as int? ?? 0,
      className: json['className'] as String?,
      creatorId: json['creatorID'] as int? ?? json['creatorId'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      departmentId: json['departmentID'] as int? ?? json['departmentId'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      status: json['status'] as int? ?? 1,
      happenedAt: json['happenedAt'] as int? ?? json['happened_at'] as int? ?? 0,
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ScoreApplyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int? ?? 0,
      confirmedAt: json['confirmedAt'] as int?,
      confirmedBy: json['confirmedBy'] as int?,
      confirmedName: json['confirmedName'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 1: return '待确认';
      case 2: return '已确认';
      case 3: return '已拒绝';
      default: return '未知';
    }
  }

  Color get statusColor {
    switch (status) {
      case 1: return const Color(0xFFFF9500);
      case 2: return const Color(0xFF30D158);
      case 3: return const Color(0xFFFF3B30);
      default: return const Color(0xFF8E8E93);
    }
  }

  @override
  List<Object?> get props => [id, status];
}

/// 积分申报明细项
class ScoreApplyItem extends Equatable {
  final int userId;
  final String? userName;
  final String? avatar;
  final int? score;
  final String? remark;

  const ScoreApplyItem({
    required this.userId,
    this.userName,
    this.avatar,
    this.score,
    this.remark,
  });

  factory ScoreApplyItem.fromJson(Map<String, dynamic> json) {
    return ScoreApplyItem(
      userId: json['user'] as int? ?? 0,
      userName: json['userName'] as String?,
      avatar: json['avatar'] as String?,
      score: json['score'] as int?,
      remark: json['remark'] as String?,
    );
  }

  @override
  List<Object?> get props => [userId, score];
}

/// 积分发放记录
class ScoreGiveLog extends Equatable {
  final int id;
  final int employeeId; // 兼容旧字段
  final int userIdent; // 后端 userIdent 字段
  final String? employeeName;
  final String? avatar;
  final int departmentId;
  final String? departmentName;
  final int score;
  final int giveValue; // 后端 giveValue 字段（与 score 含义相同）
  final int classId;
  final String? className;
  final String? remark;
  final String? remarks; // 后端 remarks 字段
  final int givenAt;
  final int givenBy;
  final String? givenByName;
  final int? group; // 分组
  final int? createdAt;
  final int? applyId; // 关联申报ID

  const ScoreGiveLog({
    required this.id,
    required this.employeeId,
    this.userIdent = 0,
    this.employeeName,
    this.avatar,
    required this.departmentId,
    this.departmentName,
    required this.score,
    this.giveValue = 0,
    required this.classId,
    this.className,
    this.remark,
    this.remarks,
    required this.givenAt,
    required this.givenBy,
    this.givenByName,
    this.group,
    this.createdAt,
    this.applyId,
  });

  /// 获取实际积分值（优先用 giveValue，其次用 score）
  int get effectiveScore => giveValue != 0 ? giveValue : score;

  /// 获取实际备注（优先用 remarks，其次用 remark）
  String? get effectiveRemark => remarks ?? remark;

  factory ScoreGiveLog.fromJson(Map<String, dynamic> json) {
    final empId = json['userIdent'] as int? ??
        json['employeeID'] as int? ??
        json['employeeId'] as int? ??
        0;
    return ScoreGiveLog(
      id: json['id'] as int? ?? 0,
      employeeId: empId,
      userIdent: json['userIdent'] as int? ?? empId,
      employeeName: json['employeeName'] as String? ?? json['name'] as String?,
      avatar: json['avatar'] as String?,
      departmentId: json['departmentID'] as int? ?? json['departmentId'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      score: json['score'] as int? ?? 0,
      giveValue: json['giveValue'] as int? ?? 0,
      classId: json['classID'] as int? ?? json['classId'] as int? ?? 0,
      className: json['className'] as String?,
      remark: json['remark'] as String?,
      remarks: json['remarks'] as String?,
      givenAt: json['giveAt'] as int? ?? json['givenAt'] as int? ?? 0,
      givenBy: json['createdBy'] as int? ?? json['givenBy'] as int? ?? json['given_by'] as int? ?? 0,
      givenByName: json['givenByName'] as String? ?? json['createdByName'] as String?,
      group: json['group'] as int?,
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int?,
      applyId: json['applyID'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, userIdent, effectiveScore];
}

/// 积分统计/红黑榜
class ScoreStatistics extends Equatable {
  final int departmentId;
  final String? departmentName;
  final List<ScoreRanking> rankings;
  final int totalScore;
  final int totalGiven;
  final int totalRemaining;

  const ScoreStatistics({
    required this.departmentId,
    this.departmentName,
    this.rankings = const [],
    this.totalScore = 0,
    this.totalGiven = 0,
    this.totalRemaining = 0,
  });

  factory ScoreStatistics.fromJson(Map<String, dynamic> json) {
    return ScoreStatistics(
      departmentId: json['departmentID'] as int? ?? json['departmentId'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      rankings: (json['rankings'] as List<dynamic>?)
              ?.map((e) => ScoreRanking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['list'] as List<dynamic>?)
              ?.map((e) => ScoreRanking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalScore: json['totalScore'] as int? ?? 0,
      totalGiven: json['totalGiven'] as int? ?? 0,
      totalRemaining: json['totalRemaining'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [departmentId, totalScore];
}

/// 积分排行
class ScoreRanking extends Equatable {
  final int userId;
  final String? userName;
  final String? avatar;
  final int score;
  final int rank; // 排名，正数为红榜，负数为黑榜
  final int? departmentId;
  final String? departmentName;

  const ScoreRanking({
    required this.userId,
    this.userName,
    this.avatar,
    required this.score,
    required this.rank,
    this.departmentId,
    this.departmentName,
  });

  factory ScoreRanking.fromJson(Map<String, dynamic> json) {
    return ScoreRanking(
      userId: json['userID'] as int? ?? json['userId'] as int? ?? 0,
      userName: json['userName'] as String?,
      avatar: json['avatar'] as String?,
      score: json['score'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      departmentId: json['departmentID'] as int?,
      departmentName: json['departmentName'] as String?,
    );
  }

  bool get isRed => rank > 0; // 红榜（高分）
  bool get isBlack => rank < 0; // 黑榜（低分）

  Color get rankColor {
    final absRank = rank.abs();
    if (absRank == 1) return const Color(0xFFFFD700); // 金色
    if (absRank == 2) return const Color(0xFFC0C0C0); // 银色
    if (absRank == 3) return const Color(0xFFCD7F32); // 铜色
    if (isBlack) return const Color(0xFF8E8E93); // 灰色
    return const Color(0xFF30D158); // 绿色
  }

  @override
  List<Object?> get props => [userId, rank, score];
}

/// 当前用户积分余额
class CurrentUserScore extends Equatable {
  final int getScores; // 可发放积分
  final int giveOutScores; // 已发放积分

  const CurrentUserScore({
    this.getScores = 0,
    this.giveOutScores = 0,
  });

  factory CurrentUserScore.fromJson(Map<String, dynamic> json) {
    return CurrentUserScore(
      getScores: json['getScores'] as int? ?? 0,
      giveOutScores: json['giveOutScores'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [getScores, giveOutScores];
}

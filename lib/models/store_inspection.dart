import 'package:flutter/cupertino.dart';

/// 巡店类型
enum StoreInspectionType {
  shopInspection('shopInspection', '巡店'),
  selfInspection('selfInspection', '自检');

  final String value;
  final String label;

  const StoreInspectionType(this.value, this.label);

  static StoreInspectionType? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 巡店状态（简单列表用）
enum StoreInspectionStatus {
  pending(1, '待执行', Color(0xFFFF9500)),
  inProgress(2, '执行中', Color(0xFF0A84FF)),
  completed(3, '已完成', Color(0xFF30D158)),
  overdue(4, '已逾期', Color(0xFFFF3B30));

  final int value;
  final String label;
  final Color color;

  const StoreInspectionStatus(this.value, this.label, this.color);

  static StoreInspectionStatus fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 巡店日志（简单列表用）
class StoreInspectionLog {
  final int logID;
  final String? logNumber;
  final int departmentID;
  final String? departmentName;
  final int inspectionID;
  final String? inspectionName;
  final StoreInspectionStatus status;
  final StoreInspectionType type;
  final int assignedBy;
  final String? assignedByName;
  final int assignee;
  final String? assigneeName;
  final int createdAt;
  final int? completedAt;
  final int? deadline;
  final int? score;
  final int? totalScore;

  const StoreInspectionLog({
    required this.logID,
    this.logNumber,
    required this.departmentID,
    this.departmentName,
    required this.inspectionID,
    this.inspectionName,
    required this.status,
    required this.type,
    required this.assignedBy,
    this.assignedByName,
    required this.assignee,
    this.assigneeName,
    required this.createdAt,
    this.completedAt,
    this.deadline,
    this.score,
    this.totalScore,
  });

  factory StoreInspectionLog.fromJson(Map<String, dynamic> json) {
    return StoreInspectionLog(
      logID: json['logID'] as int? ?? 0,
      logNumber: json['logNumber'] as String?,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      inspectionID: json['inspectionID'] as int? ?? 0,
      inspectionName: json['inspectionName'] as String?,
      status: StoreInspectionStatus.fromValue(json['status'] as int? ?? 1),
      type: StoreInspectionType.fromValue(json['type'] as String?) ?? StoreInspectionType.shopInspection,
      assignedBy: json['assignedBy'] as int? ?? 0,
      assignedByName: json['assignedByName'] as String?,
      assignee: json['assignee'] as int? ?? 0,
      assigneeName: json['assigneeName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      completedAt: json['completedAt'] as int?,
      deadline: json['deadline'] as int?,
      score: json['score'] as int?,
      totalScore: json['totalScore'] as int?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String? get scoreDisplay {
    if (score == null || totalScore == null) return null;
    return '$score/$totalScore';
  }
}

/// 巡店记录状态 (来自 PWA store-inspection-log-types.ts)
enum StoreInspectionLogStatus {
  doing('doing', '进行中', Color(0xFF30D158)),
  toRectify('to-rectify', '待整改', Color(0xFFFF3B30)),
  toAccepted('to-accepted', '待验收', Color(0xFFFF9500)),
  toReviewed('to-reviewed', '待复核', Color(0xFFBF5AF2)),
  finished('finished', '已完成', Color(0xFF0A84FF));

  final String value;
  final String label;
  final Color color;

  const StoreInspectionLogStatus(this.value, this.label, this.color);

  static StoreInspectionLogStatus fromValue(String? v) {
    if (v == null) return doing;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return doing;
  }
}

/// 检查项
class StoreInspectionCheckItem {
  final String uuid;
  final String name;
  final String description;
  final List<String> attachment;
  final List<int>? scoreRange;
  final List<int>? numericRange;

  const StoreInspectionCheckItem({
    required this.uuid,
    required this.name,
    required this.description,
    this.attachment = const [],
    this.scoreRange,
    this.numericRange,
  });

  factory StoreInspectionCheckItem.fromJson(Map<String, dynamic> json) {
    return StoreInspectionCheckItem(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      attachment: (json['attachment'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      scoreRange: (json['scoreRange'] as List<dynamic>?)?.map((e) => e as int).toList(),
      numericRange: (json['numericRange'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }
}

/// 巡店记录结果
class StoreInspectionLogResult {
  final int id;
  final int logID;
  final String checkUUID;
  final String comments;
  final List<String> photos;
  final int? score;
  final int? numeric;
  final bool? needRectify;
  final int createdBy;
  final int createdAt;
  final int updatedBy;
  final int updatedAt;

  const StoreInspectionLogResult({
    required this.id,
    required this.logID,
    required this.checkUUID,
    required this.comments,
    this.photos = const [],
    this.score,
    this.numeric,
    this.needRectify,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  factory StoreInspectionLogResult.fromJson(Map<String, dynamic> json) {
    return StoreInspectionLogResult(
      id: json['id'] as int? ?? 0,
      logID: json['logID'] as int? ?? 0,
      checkUUID: json['checkUUID'] as String? ?? '',
      comments: json['comments'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      score: json['score'] as int?,
      numeric: json['tableInfo']?['numeric'] as int?,
      needRectify: json['needRectify'] as bool?,
      createdBy: json['createdBy'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }
}

/// 整改结果
class StoreInspectionRectifyResult {
  final int id;
  final int resultID;
  final int createdBy;
  final int createdAt;
  final int updatedBy;
  final int updatedAt;
  final String content;
  final List<String> photos;
  final bool? acceptedResult;

  const StoreInspectionRectifyResult({
    required this.id,
    required this.resultID,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    required this.content,
    this.photos = const [],
    this.acceptedResult,
  });

  factory StoreInspectionRectifyResult.fromJson(Map<String, dynamic> json) {
    return StoreInspectionRectifyResult(
      id: json['id'] as int? ?? 0,
      resultID: json['resultID'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      acceptedResult: json['acceptedResult'] as bool?,
    );
  }
}

/// 巡店记录详情（含检查项详情）
class StoreInspectionLogDetail {
  final int id;
  final int departmentID;
  final String? departmentName;
  final int inspectionID;
  final String? inspectionName;
  final String? storeInspectionType;
  final int? storeInspectionCate;
  final int? spend;
  final String? assess;
  final String? thinkAbout;
  final int? score;
  final String status;
  final int createdBy;
  final String? createdByName;
  final int createdAt;
  final int updatedBy;
  final int updatedAt;
  final int? correctBy;
  final String? correctByName;
  final List<int> sendTo;
  final int? acceptedBy;
  final String? acceptedByName;
  final int? acceptedAt;
  final String? acceptanceComments;
  final int? reviewedBy;
  final String? reviewedByName;
  final int? reviewedAt;
  final String? reviewedComments;
  final List<StoreInspectionCheckItem> checkInfo;

  const StoreInspectionLogDetail({
    required this.id,
    required this.departmentID,
    this.departmentName,
    required this.inspectionID,
    this.inspectionName,
    this.storeInspectionType,
    this.storeInspectionCate,
    this.spend,
    this.assess,
    this.thinkAbout,
    this.score,
    required this.status,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    this.correctBy,
    this.correctByName,
    this.sendTo = const [],
    this.acceptedBy,
    this.acceptedByName,
    this.acceptedAt,
    this.acceptanceComments,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewedComments,
    this.checkInfo = const [],
  });

  factory StoreInspectionLogDetail.fromJson(Map<String, dynamic> json) {
    final summarize = json['summarize'] as Map<String, dynamic>?;
    final checkInfoJson = json['checkInfo'] as List<dynamic>? ?? [];
    return StoreInspectionLogDetail(
      id: json['id'] as int? ?? 0,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      inspectionID: json['inspectionID'] as int? ?? 0,
      inspectionName: json['inspectionName'] as String?,
      storeInspectionType: json['storeInspectionType'] as String?,
      storeInspectionCate: json['storeInspectionCate'] as int?,
      spend: json['spend'] as int?,
      assess: summarize?['assess'] as String?,
      thinkAbout: summarize?['thinkAbout'] as String?,
      score: json['score'] as int?,
      status: json['status'] as String? ?? 'doing',
      createdBy: json['createdBy'] as int? ?? 0,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      correctBy: json['correctBy'] as int?,
      correctByName: json['correctByName'] as String?,
      sendTo: (json['sendTo'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      acceptedBy: json['acceptedBy'] as int?,
      acceptedByName: json['acceptedByName'] as String?,
      acceptedAt: json['acceptedAt'] as int?,
      acceptanceComments: json['acceptanceComments'] as String?,
      reviewedBy: json['reviewedBy'] as int?,
      reviewedByName: json['reviewedByName'] as String?,
      reviewedAt: json['reviewedAt'] as int?,
      reviewedComments: json['reviewedComments'] as String?,
      checkInfo: checkInfoJson.map((e) => StoreInspectionCheckItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  StoreInspectionLogStatus get logStatus => StoreInspectionLogStatus.fromValue(status);

  String _fmt(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCreatedAt => _fmt(createdAt);
  String get formattedUpdatedAt => _fmt(updatedAt);
  String? get formattedAcceptedAt => acceptedAt != null ? _fmt(acceptedAt!) : null;
  String? get formattedReviewedAt => reviewedAt != null ? _fmt(reviewedAt!) : null;
}

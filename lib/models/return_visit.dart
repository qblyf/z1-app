/// 客户回访模型
/// 对应后端 /return-visit/* API

/// 回访类型
enum ReturnVisitType {
  order('订单回访', 0xFF007AFF),
  change('换机回访', 0xFF5E5CE6);

  const ReturnVisitType(this.label, this.colorValue);
  final String label;
  final int colorValue;

  static ReturnVisitType? fromString(String? v) {
    if (v == null) return null;
    return ReturnVisitType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ReturnVisitType.order,
    );
  }
}

/// 回访状态
enum ReturnVisitStatus {
  todo('待回访', 0xFFFF9500),
  doing('进行中', 0xFF0A84FF),
  failed('回访失败', 0xFFFF3B30),
  abort('回访中止', 0xFF8E8E93),
  success('回访成功', 0xFF30D158);

  const ReturnVisitStatus(this.label, this.colorValue);
  final String label;
  final int colorValue;

  static ReturnVisitStatus? fromString(String? v) {
    if (v == null) return null;
    return ReturnVisitStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ReturnVisitStatus.todo,
    );
  }
}

/// 回访方式
enum ReturnVisitMethod {
  phone('电话', 0xFF007AFF),
  message('短信', 0xFF5E5CE6),
  wechat('微信', 0xFF30D158),
  enterpriseWeChat('企业微信', 0xFF00C853),
  qq('QQ', 0xFF607D8B),
  other('其他', 0xFF8E8E93);

  const ReturnVisitMethod(this.label, this.colorValue);
  final String label;
  final int colorValue;

  static ReturnVisitMethod? fromString(String? v) {
    if (v == null) return null;
    return ReturnVisitMethod.values.firstWhere(
      (e) => e.name == v || e.name.toLowerCase() == v?.toLowerCase(),
      orElse: () => ReturnVisitMethod.other,
    );
  }
}

/// 回访记录
class ReturnVisitRecord {
  final String content;
  final int createdAt;
  final int createdBy;
  final ReturnVisitMethod method;

  ReturnVisitRecord({
    required this.content,
    required this.createdAt,
    required this.createdBy,
    required this.method,
  });

  factory ReturnVisitRecord.fromJson(Map<String, dynamic> json) {
    return ReturnVisitRecord(
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      method: ReturnVisitMethod.fromString(json['method'] as String?) ?? ReturnVisitMethod.other,
    );
  }

  DateTime get createdTime => DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

  String get formattedTime {
    final dt = createdTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 回访记录
class ReturnVisit {
  final int id;
  final String number;
  final String orderNumber;
  final ReturnVisitType type;
  final int employee; // 回访人
  final int customer; // 被回访人
  final ReturnVisitStatus status;
  final List<ReturnVisitRecord> record;
  final int createdAt;
  final int lastUpdatedAt;

  ReturnVisit({
    required this.id,
    required this.number,
    required this.orderNumber,
    required this.type,
    required this.employee,
    required this.customer,
    required this.status,
    required this.record,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory ReturnVisit.fromJson(Map<String, dynamic> json) {
    return ReturnVisit(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      type: ReturnVisitType.fromString(json['type'] as String?) ?? ReturnVisitType.order,
      employee: json['employee'] as int? ?? 0,
      customer: json['customer'] as int? ?? 0,
      status: ReturnVisitStatus.fromString(json['status'] as String?) ?? ReturnVisitStatus.todo,
      record: (json['record'] as List<dynamic>?)
          ?.map((e) => ReturnVisitRecord.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] as int? ?? 0,
      lastUpdatedAt: json['lastUpdatedAt'] as int? ?? 0,
    );
  }

  DateTime get createdTime => DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  DateTime get lastUpdatedTime => DateTime.fromMillisecondsSinceEpoch(lastUpdatedAt * 1000);

  String get formattedCreatedTime {
    final dt = createdTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String get formattedLastUpdatedTime {
    final dt = lastUpdatedTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 客户提醒（发送通知）模型
/// 对应后端 /send-notice/* API

/// 提醒状态
enum SendNoticeStatus {
  todo('待提醒', 0xFFFF9500),
  finish('已提醒', 0xFF30D158),
  cancel('已取消', 0xFF8E8E93);

  const SendNoticeStatus(this.label, this.colorValue);
  final String label;
  final int colorValue;

  static SendNoticeStatus? fromString(String? v) {
    if (v == null) return null;
    return SendNoticeStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SendNoticeStatus.todo,
    );
  }
}

/// 提醒类型
enum SendNoticeType {
  activity('活动提醒', 0xFF5E5CE6),
  discount('优惠提醒', 0xFF30D158),
  new_('新机上市', 0xFFFF9500);

  const SendNoticeType(this.label, this.colorValue);
  final String label;
  final int colorValue;

  static SendNoticeType? fromString(String? v) {
    if (v == null) return null;
    return SendNoticeType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SendNoticeType.activity,
    );
  }
}

/// 提醒方式
enum SendNoticeMethod {
  sms('短信', 0xFF007AFF),
  publicAccount('公众号', 0xFF30D158),
  miniProgram('小程序', 0xFF5E5CE6);

  const SendNoticeMethod(this.label, this.colorValue);
  final String label;
  final int colorValue;

  static SendNoticeMethod? fromString(String? v) {
    if (v == null) return null;
    return SendNoticeMethod.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SendNoticeMethod.sms,
    );
  }
}

/// 发送通知记录
class SendNotice {
  final int sendNoticeId;
  final String sendNoticeNumber;
  final SendNoticeStatus status;
  final SendNoticeType type;
  final SendNoticeMethod method;
  final int sendAt; // Unix 时间戳
  final String info;
  final List<int> idents; // 接收人 ident 列表
  final String? remarks;
  final String? cancelRemarks;
  final int createdAt;
  final int createdBy;
  final int? updatedAt;
  final int? updatedBy;

  SendNotice({
    required this.sendNoticeId,
    required this.sendNoticeNumber,
    required this.status,
    required this.type,
    required this.method,
    required this.sendAt,
    required this.info,
    required this.idents,
    this.remarks,
    this.cancelRemarks,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory SendNotice.fromJson(Map<String, dynamic> json) {
    return SendNotice(
      sendNoticeId: json['sendNoticeID'] as int? ?? 0,
      sendNoticeNumber: json['sendNoticeNumber'] as String? ?? '',
      status: SendNoticeStatus.fromString(json['status'] as String?) ?? SendNoticeStatus.todo,
      type: SendNoticeType.fromString(json['type'] as String?) ?? SendNoticeType.activity,
      method: SendNoticeMethod.fromString(json['method'] as String?) ?? SendNoticeMethod.sms,
      sendAt: json['sendAt'] as int? ?? 0,
      info: json['info'] as String? ?? '',
      idents: (json['idents'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      remarks: json['remarks'] as String?,
      cancelRemarks: json['cancelRemarks'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int?,
      updatedBy: json['updatedBy'] as int?,
    );
  }

  /// 发送时间
  DateTime get sendTime => DateTime.fromMillisecondsSinceEpoch(sendAt * 1000);

  /// 创建时间
  DateTime get createdTime => DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

  /// 格式化发送时间
  String get formattedSendTime {
    final dt = sendTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化创建时间
  String get formattedCreatedTime {
    final dt = createdTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 接收人数量
  int get receiverCount => idents.length;
}

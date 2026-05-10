/// 收件人类型
enum ReceiverType {
  receiver('receiver', '收件人'),
  carbonCopy('carbonCopy', '抄送人');

  const ReceiverType(this.value, this.label);
  final String value;
  final String label;

  static ReceiverType? fromValue(String? v) {
    if (v == null) return null;
    return ReceiverType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ReceiverType.receiver,
    );
  }
}

/// 已读状态
enum ReadStatus {
  read('read', '已读'),
  unread('unread', '未读');

  const ReadStatus(this.value, this.label);
  final String value;
  final String label;

  static ReadStatus? fromValue(String? v) {
    if (v == null) return null;
    return ReadStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ReadStatus.unread,
    );
  }
}

/// 关联类型（通知关联的业务对象）
enum AssociatedType {
  none('none', '无'),
  preSaleOrder('preSaleOrder', '预售订单'),
  order('order', '商城订单'),
  invoice('invoice', '发票'),
  approval('approval', '审批'),
  transferOrder('transferOrder', '调拨单');

  final String value;
  final String label;
  const AssociatedType(this.value, this.label);

  static AssociatedType fromValue(String? v) {
    if (v == null) return AssociatedType.none;
    return AssociatedType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => AssociatedType.none,
    );
  }
}

/// 通知附件
class NoticeAttachment {
  final String name;
  final String url;
  final String? mimeType;

  const NoticeAttachment({
    required this.name,
    required this.url,
    this.mimeType,
  });

  factory NoticeAttachment.fromJson(Map<String, dynamic> json) {
    return NoticeAttachment(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
    );
  }

  bool get isImage => mimeType?.startsWith('image/') ?? false;
}

/// 通知记录
class NoticeLog {
  final int id;
  final int noticeID;
  final int receiver;
  final ReceiverType receiverType;
  final ReadStatus readStatus;
  final int? readAt;
  final int createdAt;
  final int? sender;
  final String? senderName;
  final String title;
  final String content;
  final AssociatedType associatedType;
  final int? associatedID;
  final List<NoticeAttachment> attachments;

  const NoticeLog({
    required this.id,
    required this.noticeID,
    required this.receiver,
    required this.receiverType,
    required this.readStatus,
    this.readAt,
    required this.createdAt,
    this.sender,
    this.senderName,
    this.title = '',
    this.content = '',
    this.associatedType = AssociatedType.none,
    this.associatedID,
    this.attachments = const [],
  });

  factory NoticeLog.fromJson(Map<String, dynamic> json) {
    return NoticeLog(
      id: json['id'] as int? ?? 0,
      noticeID: json['noticeID'] as int? ?? json['id'] as int? ?? 0,
      receiver: json['receiver'] as int? ?? 0,
      receiverType: ReceiverType.fromValue(json['receiverType'] as String?) ?? ReceiverType.receiver,
      readStatus: ReadStatus.fromValue(json['readStatus'] as String?) ?? ReadStatus.unread,
      readAt: json['readAt'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      sender: json['sender'] as int?,
      senderName: json['senderName'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      associatedType: AssociatedType.fromValue(json['associatedType'] as String?),
      associatedID: json['associatedID'] as int?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => NoticeAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 通知统计
class NoticeCount {
  final int carbonCopyCount;
  final int receiverCount;

  const NoticeCount({
    required this.carbonCopyCount,
    required this.receiverCount,
  });

  int get total => carbonCopyCount + receiverCount;

  factory NoticeCount.fromJson(Map<String, dynamic> json) {
    return NoticeCount(
      carbonCopyCount: json['carbonCopyCount'] as int? ?? 0,
      receiverCount: json['receiverCount'] as int? ?? 0,
    );
  }
}

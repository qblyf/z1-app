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
  final String title;
  final String content;

  const NoticeLog({
    required this.id,
    required this.noticeID,
    required this.receiver,
    required this.receiverType,
    required this.readStatus,
    this.readAt,
    required this.createdAt,
    this.sender,
    this.title = '',
    this.content = '',
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
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
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

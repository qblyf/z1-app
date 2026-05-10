/// 卡券模型

/// 卡券状态
enum CouponState {
  invalid(1, '已失效', 0xFF8E8E93),
  available(2, '可用', 0xFF30D158),
  used(3, '已使用', 0xFF5E5CE6),
  prePaid(4, '预支付', 0xFFFF9500);

  const CouponState(this.value, this.label, this.colorValue);
  final int value;
  final String label;
  final int colorValue;

  static CouponState fromValue(int? v) {
    if (v == null) return CouponState.invalid;
    return CouponState.values.firstWhere(
      (e) => e.value == v,
      orElse: () => CouponState.invalid,
    );
  }
}

/// 卡券
class Coupon {
  final int id;
  final int classId;
  final int? userIdent;
  final String? number;
  final int? handler;
  final int? department;
  final int? goods;
  final int? issuedDept;
  final int? issuedBy;
  final int? issuedAt;
  final int gotAt;
  final int? usedAt;
  final int invalidAt;
  final CouponState state;
  final String? remark;
  final int createdAt;
  final int usedCount;
  final int amount;
  final int? owner;
  final int usedAmount;
  final int transferCount;

  Coupon({
    required this.id,
    required this.classId,
    this.userIdent,
    this.number,
    this.handler,
    this.department,
    this.goods,
    this.issuedDept,
    this.issuedBy,
    this.issuedAt,
    required this.gotAt,
    this.usedAt,
    required this.invalidAt,
    required this.state,
    this.remark,
    required this.createdAt,
    required this.usedCount,
    required this.amount,
    this.owner,
    required this.usedAmount,
    required this.transferCount,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as int? ?? 0,
      classId: json['classID'] as int? ?? 0,
      userIdent: json['user'] as int?,
      number: json['number'] as String?,
      handler: json['handler'] as int?,
      department: json['department'] as int?,
      goods: json['goods'] as int?,
      issuedDept: json['issuedDept'] as int?,
      issuedBy: json['issuedBy'] as int?,
      issuedAt: json['issuedAt'] as int?,
      gotAt: json['gotAt'] as int? ?? 0,
      usedAt: json['usedAt'] as int?,
      invalidAt: json['invalidAt'] as int? ?? 0,
      state: CouponState.fromValue(json['state'] as int?),
      remark: json['remark'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      usedCount: json['usedCount'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      owner: json['owner'] as int?,
      usedAmount: json['usedAmount'] as int? ?? 0,
      transferCount: json['transferCount'] as int? ?? 0,
    );
  }

  String get amountDisplay => '¥${(amount / 100).toStringAsFixed(2)}';

  String get formattedAmount => amountDisplay;

  /// 卡券名称（从 classId 关联获取，此处作占位）
  String get title => '卡券#$id';

  /// 卡券类型标签
  String get typeLabel => state.label;

  /// 有效期
  String get validPeriod {
    if (invalidAt == 0) return '永久有效';
    final dt = DateTime.fromMillisecondsSinceEpoch(invalidAt * 1000);
    return '有效期至 ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

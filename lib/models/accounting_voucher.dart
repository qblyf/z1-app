/// 凭证状态
enum VoucherState {
  s1(1, '未审核'),
  s2(2, '已审核'),
  s3(3, '草稿'),
  s4(4, '已冲销'),
  s5(5, '已被冲销');

  const VoucherState(this.value, this.label);
  final int value;
  final String label;

  static VoucherState? fromValue(int? v) {
    if (v == null) return null;
    return VoucherState.values.firstWhere(
      (e) => e.value == v,
      orElse: () => VoucherState.s1,
    );
  }
}

/// 凭证字号
enum VoucherType {
  shou(1, '收'),
  fu(2, '付'),
  zhuan(3, '转'),
  ji(4, '记');

  const VoucherType(this.value, this.label);
  final int value;
  final String label;

  static VoucherType? fromValue(int? v) {
    if (v == null) return null;
    return VoucherType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => VoucherType.ji,
    );
  }
}

/// 借贷方向
enum Loan {
  debit(1, '借'),
  credit(2, '贷');

  const Loan(this.value, this.label);
  final int value;
  final String label;

  static Loan? fromValue(int? v) {
    if (v == null) return null;
    return Loan.values.firstWhere(
      (e) => e.value == v,
      orElse: () => Loan.debit,
    );
  }
}

/// 凭证分录草稿
class JournalDraft {
  final int loan; // Loan value
  final int amount;
  final int? account;
  final String? description;
  final int? department;
  final int? related;
  final int? employee;

  const JournalDraft({
    required this.loan,
    required this.amount,
    this.account,
    this.description,
    this.department,
    this.related,
    this.employee,
  });

  factory JournalDraft.fromJson(Map<String, dynamic> json) {
    return JournalDraft(
      loan: json['loan'] as int? ?? 0,
      amount: json['amount'] as int? ?? json['journalPrice'] as int? ?? 0,
      account: json['account'] as int?,
      description: json['description'] as String?,
      department: json['department'] as int?,
      related: json['related'] as int?,
      employee: json['employee'] as int?,
    );
  }
}

/// 凭证分录（已审核凭证）
class JournalEntry {
  final int id;
  final int voucher;
  final int? account;
  final String? description;
  final int? department;
  final int? related;
  final int? vendor;
  final int? employee;
  final int loan; // Loan value
  final int amountCent;
  final String? remarks;

  const JournalEntry({
    required this.id,
    required this.voucher,
    this.account,
    this.description,
    this.department,
    this.related,
    this.vendor,
    this.employee,
    required this.loan,
    required this.amountCent,
    this.remarks,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as int? ?? 0,
      voucher: json['voucher'] as int? ?? 0,
      account: json['account'] as int?,
      description: json['description'] as String?,
      department: json['department'] as int?,
      related: json['related'] as int?,
      vendor: json['vendor'] as int?,
      employee: json['employee'] as int?,
      loan: json['loan'] as int? ?? 0,
      amountCent: json['amountCent'] as int? ?? json['amount'] as int? ?? 0,
      remarks: json['remarks'] as String?,
    );
  }
}

/// 凭证
class AccountingVoucher {
  final int id;
  final int branch;
  final int? year;
  final int? month;
  final int number;
  final VoucherState state;
  final VoucherType type;
  final int? sysVoucherType;
  final int creator;
  final int? auditor;
  final int? accountant;
  final int? cashier;
  final String? remarks;
  final int createdAt;
  final int? auditedAt;
  final int? voucherTime;
  final int? reverser;
  final int? reversedAt;
  final int? reversedVoucher;
  /// 审核权限人列表
  final List<int>? auditors;
  /// 附件图片
  final List<String>? attach;
  /// 凭证分录草稿（草稿状态）
  final List<JournalDraft>? journalDraft;
  /// 关联信息
  final Map<String, dynamic>? associated;

  const AccountingVoucher({
    required this.id,
    required this.branch,
    this.year,
    this.month,
    required this.number,
    required this.state,
    required this.type,
    this.sysVoucherType,
    required this.creator,
    this.auditor,
    this.accountant,
    this.cashier,
    this.remarks,
    required this.createdAt,
    this.auditedAt,
    this.voucherTime,
    this.reverser,
    this.reversedAt,
    this.reversedVoucher,
    this.auditors,
    this.attach,
    this.journalDraft,
    this.associated,
  });

  /// 凭证字号+编号，如"记-001"
  String get displayNumber {
    final prefix = type.label;
    final numStr = number.toString().padLeft(3, '0');
    return '$prefix-$numStr';
  }

  /// 年月
  String get period {
    if (year != null && month != null) {
      return '$year/${month.toString().padLeft(2, '0')}';
    }
    return '';
  }

  /// 是否可审核（未审核状态且当前用户在审核人列表中）
  bool canAudit(List<int> currentUserIdents) {
    if (state != VoucherState.s1) return false;
    if (auditors == null || auditors!.isEmpty) return false;
    return auditors!.any((id) => currentUserIdents.contains(id));
  }

  factory AccountingVoucher.fromJson(Map<String, dynamic> json) {
    return AccountingVoucher(
      id: json['id'] as int? ?? 0,
      branch: json['branch'] as int? ?? 0,
      year: json['year'] as int?,
      month: json['month'] as int?,
      number: json['number'] as int? ?? 0,
      state: VoucherState.fromValue(json['state'] as int?) ?? VoucherState.s1,
      type: VoucherType.fromValue(json['type'] as int?) ?? VoucherType.ji,
      sysVoucherType: json['sysVoucherType'] as int?,
      creator: json['creator'] as int? ?? 0,
      auditor: json['auditor'] as int?,
      accountant: json['accountant'] as int?,
      cashier: json['cashier'] as int?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      auditedAt: json['auditedAt'] as int?,
      voucherTime: json['voucherTime'] as int?,
      reverser: json['reverser'] as int?,
      reversedAt: json['reversedAt'] as int?,
      reversedVoucher: json['reversedVoucher'] as int?,
      auditors: (json['auditors'] as List<dynamic>?)?.cast<int>(),
      attach: (json['attach'] as List<dynamic>?)?.cast<String>(),
      journalDraft: (json['journalDraft'] as List<dynamic>?)
          ?.map((e) => JournalDraft.fromJson(e as Map<String, dynamic>))
          .toList(),
      associated: json['associated'] as Map<String, dynamic>?,
    );
  }
}

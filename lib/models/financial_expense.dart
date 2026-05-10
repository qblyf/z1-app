// 财务支出模型
// 对应 z1-mid FinancialExpenses 类型

/// 财务支出状态
enum FinancialExpenseStatus {
  paymentNo(0, '待审核', 0xFFFF9500),
  paymentYes(1, '已打款', 0xFF30D158),
  closed(2, '已关闭', 0xFF8E8E93);

  const FinancialExpenseStatus(this.value, this.label, this.colorValue);
  final int value;
  final String label;
  final int colorValue;

  static FinancialExpenseStatus fromValue(int? v) {
    if (v == null) return FinancialExpenseStatus.paymentNo;
    return FinancialExpenseStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => FinancialExpenseStatus.paymentNo,
    );
  }
}

/// 财务支出条目
class FinancialExpenseItem {
  final int id;
  final String number;
  final int? financialExpensesType;
  final String? financialExpensesTypeName;
  final String title;
  final FinancialExpenseStatus status;
  final int? createdBy;
  final String? creatorName;
  final int createdAt;
  final int totalAmount;
  final String? remark;

  FinancialExpenseItem({
    required this.id,
    required this.number,
    this.financialExpensesType,
    this.financialExpensesTypeName,
    required this.title,
    required this.status,
    this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.totalAmount,
    this.remark,
  });

  factory FinancialExpenseItem.fromJson(Map<String, dynamic> json) {
    return FinancialExpenseItem(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      financialExpensesType: json['financialExpensesType'] as int?,
      financialExpensesTypeName: json['financialExpensesTypeName'] as String?,
      title: json['title'] as String? ?? '',
      status: FinancialExpenseStatus.fromValue(json['status'] as int?),
      createdBy: json['createdBy'] as int?,
      creatorName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      totalAmount: json['totalAmount'] as int? ?? 0,
      remark: json['remark'] as String?,
    );
  }

  String get amountDisplay => '¥${(totalAmount / 100).toStringAsFixed(2)}';
}

/// 财务支出汇总
class FinancialExpenseSummary {
  final int totalOrderNum;
  final int auditOrderNum;
  final int auditOrderAmount;
  final int unAuditOrderNum;
  final int unAuditOrderAmount;

  /// 默认空实例
  const FinancialExpenseSummary({
    this.totalOrderNum = 0,
    this.auditOrderNum = 0,
    this.auditOrderAmount = 0,
    this.unAuditOrderNum = 0,
    this.unAuditOrderAmount = 0,
  });

  factory FinancialExpenseSummary.fromJson(Map<String, dynamic> json) {
    return FinancialExpenseSummary(
      totalOrderNum: json['totalOrderNum'] as int? ?? 0,
      auditOrderNum: json['auditOrderNum'] as int? ?? 0,
      auditOrderAmount: json['auditOrderAmount'] as int? ?? 0,
      unAuditOrderNum: json['unAuditOrderNum'] as int? ?? 0,
      unAuditOrderAmount: json['unAuditOrderAmount'] as int? ?? 0,
    );
  }

  String get auditAmountDisplay => '¥${(auditOrderAmount / 100).toStringAsFixed(2)}';
  String get unAuditAmountDisplay => '¥${(unAuditOrderAmount / 100).toStringAsFixed(2)}';
}

/// 财务支出单完整类型（含 infos）
/// 对应 z1-mid FinancialExpenses
class FinancialExpense {
  final int id;
  final String number;
  final int? departmentID;
  final int financialExpensesType;
  final String businessType;
  final String title;
  final String content;
  final FinancialExpenseStatus status;
  final List<FinancialExpenseInfo> infos;
  final int? approvalID;
  final int createdAt;
  final int createdBy;
  final int? auditedAt;
  final int? auditedBy;

  const FinancialExpense({
    required this.id,
    required this.number,
    this.departmentID,
    required this.financialExpensesType,
    required this.businessType,
    required this.title,
    required this.content,
    required this.status,
    this.infos = const [],
    this.approvalID,
    required this.createdAt,
    required this.createdBy,
    this.auditedAt,
    this.auditedBy,
  });

  factory FinancialExpense.fromJson(Map<String, dynamic> json) {
    final infoList = json['infos'] as List<dynamic>? ?? [];
    return FinancialExpense(
      id: json['id'] as int? ?? 0,
      number: json['financialExpensesNumber'] as String? ?? json['number'] as String? ?? '',
      departmentID: json['departmentID'] as int?,
      financialExpensesType: json['financialExpensesType'] as int? ?? 0,
      businessType: json['businessType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      status: FinancialExpenseStatus.fromValue(json['status'] as int?),
      infos: infoList.map((e) => FinancialExpenseInfo.fromJson(e as Map<String, dynamic>)).toList(),
      approvalID: json['approvalID'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      auditedAt: json['auditedAt'] as int?,
      auditedBy: json['auditedBy'] as int?,
    );
  }

  /// 预支金额总计（分）
  int get totalAmount => infos.fold(0, (sum, info) => sum + info.amount);

  String get totalAmountDisplay => '¥${(totalAmount / 100).toStringAsFixed(2)}';
}

/// 财务支出条目信息（infos 中的项）
/// 对应 z1-mid FinancialExpensesInfo
class FinancialExpenseInfo {
  final String? remarks;
  final int amount;
  final List<VoucherInfo> voucherInfo;
  final int? vendorID;
  final int? employeeIdent;
  final String? number;
  final AccountInfo? accountInfo;
  final List<String> attachedFiles;
  final List<String> financeAttachedFiles;

  const FinancialExpenseInfo({
    this.remarks,
    required this.amount,
    this.voucherInfo = const [],
    this.vendorID,
    this.employeeIdent,
    this.number,
    this.accountInfo,
    this.attachedFiles = const [],
    this.financeAttachedFiles = const [],
  });

  factory FinancialExpenseInfo.fromJson(Map<String, dynamic> json) {
    final voucherList = json['voucherInfo'] as List<dynamic>? ?? [];
    return FinancialExpenseInfo(
      remarks: json['remarks'] as String?,
      amount: json['amount'] as int? ?? 0,
      voucherInfo: voucherList.map((e) => VoucherInfo.fromJson(e as Map<String, dynamic>)).toList(),
      vendorID: json['vendorID'] as int?,
      employeeIdent: json['employeeIdent'] as int?,
      number: json['number'] as String?,
      accountInfo: json['accountInfo'] != null
          ? AccountInfo.fromJson(json['accountInfo'] as Map<String, dynamic>)
          : null,
      attachedFiles: (json['attachedFiles'] as List<dynamic>?)?.cast<String>() ?? [],
      financeAttachedFiles: (json['financeAttachedFiles'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  String get amountDisplay => '¥${(amount / 100).toStringAsFixed(2)}';
}

/// 凭证信息
/// 对应 z1-mid VoucherInfo
class VoucherInfo {
  final int? id;
  final String? name;
  final String? remarks;

  const VoucherInfo({this.id, this.name, this.remarks});

  factory VoucherInfo.fromJson(Map<String, dynamic> json) {
    return VoucherInfo(
      id: json['id'] as int?,
      name: json['name'] as String?,
      remarks: json['remarks'] as String?,
    );
  }
}

/// 账户信息
/// 对应 z1-mid AccountInfo
class AccountInfo {
  final int? accountID;
  final String? bankCardNumber;
  final String? bankName;
  final String? accountName;

  const AccountInfo({
    this.accountID,
    this.bankCardNumber,
    this.bankName,
    this.accountName,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      accountID: json['accountID'] as int?,
      bankCardNumber: json['bankCardNumber'] as String?,
      bankName: json['bankName'] as String?,
      accountName: json['accountName'] as String?,
    );
  }
}

/// 结算单款项信息（提交时用）
/// 对应 AddSettleFinancialExpensesApproval 的 infos 项
class SettlementInfo {
  final int? vendorID;
  final int? employeeIdent;
  final AccountInfo? accountInfo;
  final int amount;
  final String? number;
  final String? remarks;
  final List<String> attachedFiles;
  final String key;

  const SettlementInfo({
    this.vendorID,
    this.employeeIdent,
    this.accountInfo,
    required this.amount,
    this.number,
    this.remarks,
    this.attachedFiles = const [],
    required this.key,
  });

  Map<String, dynamic> toJson() {
    return {
      if (vendorID != null) 'vendorID': vendorID,
      if (employeeIdent != null) 'employeeIdent': employeeIdent,
      if (accountInfo != null)
        'accountInfo': {
          'accountID': accountInfo!.accountID,
          'bankCardNumber': accountInfo!.bankCardNumber,
          'bankName': accountInfo!.bankName,
          'accountName': accountInfo!.accountName,
        },
      'amount': amount,
      if (number != null) 'number': number,
      if (remarks != null) 'remarks': remarks,
      'attachedFiles': attachedFiles,
    };
  }
}


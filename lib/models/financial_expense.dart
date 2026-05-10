/// 财务支出模型

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

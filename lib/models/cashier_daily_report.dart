import 'package:flutter/cupertino.dart';

/// 收银日报状态
enum CashierDailyReportState {
  unaudited('unaudited', '未审核', Color(0xFFFF9500)),
  audited('audited', '已审核', Color(0xFF30D158));

  final String value;
  final String label;
  final Color color;

  const CashierDailyReportState(this.value, this.label, this.color);

  static CashierDailyReportState? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// POS进账记录
class PaymentPos {
  final int posClientID;
  final int amount; // 单位：分

  const PaymentPos({required this.posClientID, required this.amount});

  factory PaymentPos.fromJson(Map<String, dynamic> json) {
    return PaymentPos(
      posClientID: json['posClientID'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }

  double get amountYuan => amount / 100.0;
}

/// 银行存款记录
class BankAccountInfo {
  final int bankAccountID;
  final int amount;

  const BankAccountInfo({required this.bankAccountID, required this.amount});

  factory BankAccountInfo.fromJson(Map<String, dynamic> json) {
    return BankAccountInfo(
      bankAccountID: json['bankAccountID'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }

  double get amountYuan => amount / 100.0;
}

/// 其他收入项（带支付方式信息）
class OtherIncomeItem {
  final int? paymentDetailID;
  final int paymentTypeID;
  final int amount;
  final String? remarks;
  final List<String>? images;

  const OtherIncomeItem({
    this.paymentDetailID,
    required this.paymentTypeID,
    required this.amount,
    this.remarks,
    this.images,
  });

  factory OtherIncomeItem.fromJson(Map<String, dynamic> json) {
    return OtherIncomeItem(
      paymentDetailID: json['paymentDetailID'] as int?,
      paymentTypeID: json['paymentTypeID'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      remarks: json['remarks'] as String?,
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
    );
  }

  double get amountYuan => amount / 100.0;
}

/// 收银日报表
class CashierDailyReport {
  final int cashierDailyReportID;
  final String date; // ISO格式日期 yyyy-MM-dd
  final int departmentID;
  final String? departmentName;
  final List<PaymentPos> paymentPos;
  final List<BankAccountInfo> bankAccountInfo;
  final List<OtherIncomeItem> otherIncome;
  final String? remarks;
  final CashierDailyReportState state;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int updatedBy;
  final int updatedAt;
  final List<String> images;

  // 详情才有的字段
  final int? totalIncomeAmount;
  final int? totalOtherAmount;

  const CashierDailyReport({
    required this.cashierDailyReportID,
    required this.date,
    required this.departmentID,
    this.departmentName,
    required this.paymentPos,
    required this.bankAccountInfo,
    required this.otherIncome,
    this.remarks,
    required this.state,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    required this.images,
    this.totalIncomeAmount,
    this.totalOtherAmount,
  });

  factory CashierDailyReport.fromJson(Map<String, dynamic> json) {
    return CashierDailyReport(
      cashierDailyReportID: json['cashierDailyReportID'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      paymentPos: (json['paymentPos'] as List<dynamic>?)
              ?.map((e) => PaymentPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bankAccountInfo: (json['bankAccountInfo'] as List<dynamic>?)
              ?.map((e) => BankAccountInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      otherIncome: (json['otherIncome'] as List<dynamic>?)
              ?.map((e) => OtherIncomeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      remarks: json['remarks'] as String?,
      state: CashierDailyReportState.fromValue(json['state'] as String?) ??
          CashierDailyReportState.unaudited,
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      totalIncomeAmount: json['totalIncomeAmount'] as int?,
      totalOtherAmount: json['totalOtherAmount'] as int?,
    );
  }

  /// 总收入金额（元）
  double get totalIncomeYuan => (totalIncomeAmount ?? 0) / 100.0;

  /// 其他收入合计（元）
  double get totalOtherYuan => (totalOtherAmount ?? 0) / 100.0;

  /// POS进账合计（元）
  double get posIncomeYuan =>
      paymentPos.fold<int>(0, (sum, p) => sum + p.amount) / 100.0;

  /// 银行账户收入合计（元）
  double get bankIncomeYuan =>
      bankAccountInfo.fold<int>(0, (sum, b) => sum + b.amount) / 100.0;

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

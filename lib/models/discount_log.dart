import 'package:equatable/equatable.dart';

/// 折扣信息类型
enum DiscountInfoType {
  changePrice('changePrice', '改价'),
  coupon('coupon', '优惠券'),
  gift('gift', '赠品'),
  replacementSubsidy('replacementSubsidy', '换新补贴');

  final String value;
  final String label;
  const DiscountInfoType(this.value, this.label);

  static DiscountInfoType? fromValue(String? v) {
    if (v == null) return null;
    return DiscountInfoType.values.cast<DiscountInfoType?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
  }
}

/// 折扣日志状态
enum DiscountLogState {
  autoAudit(1, '自动审核'),
  manualAudit(11, '手动审核'),
  pending(2, '待审核'),
  rejected(3, '审核拒绝'),
  invalid(7, '失效'),
  revoked(71, '撤销');

  final int value;
  final String label;
  const DiscountLogState(this.value, this.label);

  static DiscountLogState fromValue(int v) {
    final found = DiscountLogState.values.cast<DiscountLogState?>().firstWhere(
          (e) => e?.value == v,
          orElse: () => null,
        );
    return found ?? DiscountLogState.pending;
  }

  bool get isPending => this == DiscountLogState.pending;
  bool get isApproved =>
      this == DiscountLogState.autoAudit ||
      this == DiscountLogState.manualAudit;
  bool get isRejected => this == DiscountLogState.rejected;
  bool get isRevoked => this == DiscountLogState.revoked;
}

/// 折扣关联信息
class DiscountLogAssociated extends Equatable {
  final DiscountInfoType type;
  final int differenceAmount; // 折扣变动金额（分）
  final int? skuID;
  final int? serviceID;
  final int? itemID;

  const DiscountLogAssociated({
    required this.type,
    required this.differenceAmount,
    this.skuID,
    this.serviceID,
    this.itemID,
  });

  factory DiscountLogAssociated.fromJson(Map<String, dynamic> json) {
    final diff = json['differenceAmount'] ?? json['difference_amount'];
    return DiscountLogAssociated(
      type: DiscountInfoType.fromValue(json['type'] as String?) ??
          DiscountInfoType.changePrice,
      differenceAmount: (diff as num?)?.toInt() ?? 0,
      skuID: json['skuID'] as int?,
      serviceID: json['serviceID'] as int?,
      itemID: json['itemID'] as int?,
    );
  }

  @override
  List<Object?> get props => [type, differenceAmount, skuID, serviceID, itemID];
}

/// 折扣日志
class DiscountLog extends Equatable {
  final int logID;
  final DiscountLogState state;
  final String mallNumber; // 商城订单编号
  final List<DiscountLogAssociated> associated;
  final int limitCent; // 当前大盘价（分）
  final int? skuID;
  final int? serviceID;
  final int createdAt; // Unix 时间戳
  final String createdBy;
  final int updatedAt;
  final String updatedBy;
  final String? remarks;

  // 关联的商品/服务名称（需外部传入）
  String? productName;
  String? skuName;
  String? serviceName;

  DiscountLog({
    required this.logID,
    required this.state,
    required this.mallNumber,
    required this.associated,
    required this.limitCent,
    this.skuID,
    this.serviceID,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.remarks,
  });

  factory DiscountLog.fromJson(Map<String, dynamic> json) {
    List<DiscountLogAssociated> parseAssociated(dynamic data) {
      if (data is List) {
        return data
            .map((e) => DiscountLogAssociated.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return DiscountLog(
      logID: json['logID'] as int? ?? 0,
      state: DiscountLogState.fromValue(json['state'] as int? ?? 2),
      mallNumber: json['mallNumber'] as String? ?? '',
      associated: parseAssociated(json['associated']),
      limitCent: (json['limitCent'] as num?)?.toInt() ?? 0,
      skuID: json['skuID'] as int?,
      serviceID: json['serviceID'] as int?,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      updatedBy: json['updatedBy'] as String? ?? '',
      remarks: json['remarks'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        logID,
        state,
        mallNumber,
        associated,
        limitCent,
        skuID,
        serviceID,
        createdAt,
      ];
}

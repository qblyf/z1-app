/// 维修类型
enum RepairType {
  local('local', '本地维修'),
  external('external', '送修维修');

  const RepairType(this.value, this.label);
  final String value;
  final String label;

  static RepairType? fromValue(String? v) {
    if (v == null) return null;
    return RepairType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => RepairType.local,
    );
  }
}

/// 维修状态
enum RepairState {
  pending(1, '待派工/待送修'),
  repairing(2, '维修中/送修中'),
  unRepairableConfirm(31, '无法修复待确认'),
  repairedConfirm(32, '已修复待确认'),
  unRepairableNotice(41, '无法修复待通知'),
  repairedNotice(42, '已修复待通知'),
  unRepairableNoticed(51, '无法修复已通知'),
  repairedNoticed(52, '已修复已通知'),
  unRepairablePicked(61, '无法修复已取机'),
  repairedPicked(62, '已修复已取机'),
  missingParts(7, '缺件等候');

  const RepairState(this.value, this.label);
  final int value;
  final String label;

  static RepairState? fromValue(int? v) {
    if (v == null) return null;
    return RepairState.values.firstWhere(
      (e) => e.value == v,
      orElse: () => RepairState.pending,
    );
  }
}

/// 保修状态
enum WarrantyState {
  under('under', '质保期内'),
  outOf('out of', '质保期外'),
  unknown('unknown', '未知');

  const WarrantyState(this.value, this.label);
  final String value;
  final String label;

  static WarrantyState? fromValue(String? v) {
    if (v == null) return null;
    return WarrantyState.values.firstWhere(
      (e) => e.value == v,
      orElse: () => WarrantyState.unknown,
    );
  }
}

/// 维修受理单
class RepairOrder {
  final int repairID;
  final String repairNumber;
  final int userIdent;
  final int departmentID;
  final int goodsID;
  final String buyDate;
  final String description;
  final String? accessoriesDesc;
  final String? valueAddedServices;
  final RepairType repairType;
  final RepairState repairState;
  final int? engineerIdent;
  final int? repairCentreID;
  final int createdAt;
  final int createdBy;
  final int updatedAt;
  final int updatedBy;
  final String? remarks;
  final WarrantyState warrantyState;

  const RepairOrder({
    required this.repairID,
    required this.repairNumber,
    required this.userIdent,
    required this.departmentID,
    required this.goodsID,
    required this.buyDate,
    required this.description,
    this.accessoriesDesc,
    this.valueAddedServices,
    required this.repairType,
    required this.repairState,
    this.engineerIdent,
    this.repairCentreID,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.remarks,
    required this.warrantyState,
  });

  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    return RepairOrder(
      repairID: json['repairID'] as int? ?? 0,
      repairNumber: json['repairNumber'] as String? ?? '',
      userIdent: json['userIdent'] as int? ?? 0,
      departmentID: json['departmentID'] as int? ?? 0,
      goodsID: json['goodsID'] as int? ?? 0,
      buyDate: json['buyDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      accessoriesDesc: json['accessoriesDesc'] as String?,
      valueAddedServices: json['valueAddedServices'] as String?,
      repairType: RepairType.fromValue(json['repairType'] as String?) ?? RepairType.local,
      repairState: RepairState.fromValue(json['repairState'] as int?) ?? RepairState.pending,
      engineerIdent: json['engineerIdent'] as int?,
      repairCentreID: json['repairCentreID'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      remarks: json['remarks'] as String?,
      warrantyState: WarrantyState.fromValue(json['warrantyState'] as String?) ?? WarrantyState.unknown,
    );
  }
}

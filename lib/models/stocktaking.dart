import 'package:flutter/cupertino.dart';

/// 盘库方案状态
enum StocktakingPlanState {
  available(1, '可用'),
  unavailable(2, '不可用');

  final int value;
  final String label;

  const StocktakingPlanState(this.value, this.label);

  static StocktakingPlanState fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return unavailable;
  }
}

/// 商品标准可选项
enum ProductTarget {
  standardOnly(1, '仅标准'),
  nonStandardOnly(2, '仅非标准'),
  standardAndNonStandard(3, '标准与非标准'),
  handRecycle(4, '掌上回收');

  final int value;
  final String label;

  const ProductTarget(this.value, this.label);

  static ProductTarget fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return standardOnly;
  }
}

/// 盘点状态
enum StocktakingState {
  draft(1, '草稿', Color(0xFF8E8E93)),
  pending(2, '待盘点', Color(0xFFFF9500)),
  inProgress(3, '盘点中', Color(0xFF0A84FF)),
  completed(4, '已完成', Color(0xFF30D158)),
  cancelled(5, '已取消', Color(0xFF8E8E93));

  final int value;
  final String label;
  final Color color;

  const StocktakingState(this.value, this.label, this.color);

  static StocktakingState fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 盘点类型
enum StocktakingType {
  cycle(1, '周期盘点'),
  spot(2, '抽盘'),
  full(3, '全盘');

  final int value;
  final String label;

  const StocktakingType(this.value, this.label);

  static StocktakingType fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return cycle;
  }
}

/// 盘点日志
class StocktakingLog {
  final int stocktakingLogID;
  final String? stocktakingLogNumber;
  final int warehouseID;
  final String? warehouseName;
  final int departmentID;
  final String? departmentName;
  final StocktakingState status;
  final StocktakingType type;
  final int createdBy;
  final String? creatorName;
  final int createdAt;
  final int? completedAt;
  final int totalSkuCount;
  final int checkedCount;
  final String? remarks;

  const StocktakingLog({
    required this.stocktakingLogID,
    this.stocktakingLogNumber,
    required this.warehouseID,
    this.warehouseName,
    required this.departmentID,
    this.departmentName,
    required this.status,
    required this.type,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    this.completedAt,
    this.totalSkuCount = 0,
    this.checkedCount = 0,
    this.remarks,
  });

  factory StocktakingLog.fromJson(Map<String, dynamic> json) {
    return StocktakingLog(
      stocktakingLogID: json['stocktakingLogID'] as int? ?? 0,
      stocktakingLogNumber: json['stocktakingLogNumber'] as String?,
      warehouseID: json['warehouseID'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      departmentID: json['departmentID'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      status: StocktakingState.fromValue(json['status'] as int? ?? 2),
      type: StocktakingType.fromValue(json['type'] as int? ?? 1),
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      completedAt: json['completedAt'] as int?,
      totalSkuCount: json['totalSkuCount'] as int? ?? 0,
      checkedCount: json['checkedCount'] as int? ?? 0,
      remarks: json['remarks'] as String?,
    );
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  double get progress => totalSkuCount > 0 ? checkedCount / totalSkuCount : 0;
}

/// 盘库计划周期
class StocktakingTakeCycle {
  final String cycle; // 'day' | 'week' | 'month'
  final List<int> days;

  const StocktakingTakeCycle({required this.cycle, required this.days});

  factory StocktakingTakeCycle.fromJson(Map<String, dynamic> json) {
    return StocktakingTakeCycle(
      cycle: json['cycle'] as String? ?? 'day',
      days: (json['day'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  String get label {
    switch (cycle) {
      case 'day':
        return '每日';
      case 'week':
        final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
        return '每周${days.map((d) => weekDays[d - 1]).join('、')}';
      case 'month':
        return '每月${days.join('、')}日';
      default:
        return cycle;
    }
  }
}

/// 盘库方案
class StocktakingPlan {
  final int id;
  final String title;
  final List<int> productCates;
  final StocktakingPlanState state;
  final ProductTarget productTarget;
  final String? icon;
  final StocktakingTakeCycle cycle;
  final int createdAt;
  final int createdBy;
  final int updatedAt;
  final int updatedBy;
  final String? remindText;
  final String? remindTime;

  const StocktakingPlan({
    required this.id,
    required this.title,
    required this.productCates,
    required this.state,
    required this.productTarget,
    this.icon,
    required this.cycle,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.remindText,
    this.remindTime,
  });

  factory StocktakingPlan.fromJson(Map<String, dynamic> json) {
    return StocktakingPlan(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      productCates: (json['productCates'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      state: StocktakingPlanState.fromValue(json['state'] as int? ?? 2),
      productTarget: ProductTarget.fromValue(json['productTarget'] as int? ?? 1),
      icon: json['icon'] as String?,
      cycle: json['cycle'] == null
          ? const StocktakingTakeCycle(cycle: 'day', days: [])
          : StocktakingTakeCycle.fromJson(json['cycle'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      remindText: json['remindText'] as String?,
      remindTime: json['remindTime'] as String?,
    );
  }

  String get productTargetLabel => productTarget.label;
  bool get isAvailable => state == StocktakingPlanState.available;
}

/// 盘库记录状态（用于 Stocktaking 记录）
enum StocktakingRecordState {
  inProgress(1, '进行中', Color(0xFFFF9500)),
  completed(2, '已完成', Color(0xFF30D158));

  final int value;
  final String label;
  final Color color;

  const StocktakingRecordState(this.value, this.label, this.color);

  static StocktakingRecordState fromValue(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return inProgress;
  }
}

/// 盘库记录（带系统库存快照）
class Stocktaking {
  final int id;
  final int warehouseID;
  final String? warehouseName;
  final int planID;
  final String? planName;
  final StocktakingRecordState state;
  final bool isLast;
  final int submittedAt;
  final int createdAt;
  final int createdBy;
  final String? creatorName;
  final int updatedAt;
  final int updatedBy;
  final String? remarks;
  /// 系统库存快照
  final List<dynamic>? stockSYS;
  /// 盘库内容
  final List<dynamic>? stockTake;
  /// 锁定系统库存
  final List<dynamic>? lockSYS;
  /// 盘盈数量
  final int? outOfStockQuantity;

  const Stocktaking({
    required this.id,
    required this.warehouseID,
    this.warehouseName,
    required this.planID,
    this.planName,
    required this.state,
    required this.isLast,
    required this.submittedAt,
    required this.createdAt,
    required this.createdBy,
    this.creatorName,
    required this.updatedAt,
    required this.updatedBy,
    this.remarks,
    this.stockSYS,
    this.stockTake,
    this.lockSYS,
    this.outOfStockQuantity,
  });

  factory Stocktaking.fromJson(Map<String, dynamic> json) {
    return Stocktaking(
      id: json['id'] as int? ?? 0,
      warehouseID: json['warehouseID'] as int? ?? 0,
      warehouseName: json['warehouseName'] as String?,
      planID: json['planID'] as int? ?? 0,
      planName: json['planName'] as String?,
      state: StocktakingRecordState.fromValue(json['state'] as int? ?? 1),
      isLast: json['isLast'] as bool? ?? false,
      submittedAt: json['submittedAt'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      remarks: json['remarks'] as String?,
      stockSYS: json['stockSYS'] as List<dynamic>?,
      stockTake: json['stockTake'] as List<dynamic>?,
      lockSYS: json['lockSYS'] as List<dynamic>?,
      outOfStockQuantity: json['outOfStockQuantity'] as int?,
    );
  }

  bool get isInProgress => state == StocktakingRecordState.inProgress;
  bool get isCompleted => state == StocktakingRecordState.completed;

  int get stockSYSCount => stockSYS?.length ?? 0;
  int get stockTakeCount => stockTake?.length ?? 0;

  /// 调拨锁货数量（lockSYS 汇总）
  int get transferLockStockQuantity {
    if (lockSYS == null) return 0;
    int count = 0;
    for (final item in lockSYS!) {
      final map = item as Map<String, dynamic>;
      if (map.containsKey('qty')) {
        count += (map['qty'] as int?) ?? 0;
      } else {
        count += 1; // 强制序列号商品每个计1
      }
    }
    return count;
  }

  /// 实际系统库存数量（去除锁货后）
  int get dueQuantity {
    if (stockSYS == null) return 0;
    final lockIds = <String>{};
    if (lockSYS != null) {
      for (final item in lockSYS!) {
        final map = item as Map<String, dynamic>;
        if (map.containsKey('recycleID')) {
          lockIds.add('recycle:${map['recycleID']}');
        } else if (map.containsKey('goodsID')) {
          lockIds.add('goods:${map['goodsID']}');
        } else if (map.containsKey('itemID')) {
          lockIds.add('item:${map['itemID']}');
        } else if (map.containsKey('qty') && map.containsKey('productID')) {
          lockIds.add('product:${map['productID']}');
        }
      }
    }

    int total = 0;
    for (final item in stockSYS!) {
      final map = item as Map<String, dynamic>;
      bool isLocked = false;
      if (map.containsKey('recycleID')) {
        isLocked = lockIds.contains('recycle:${map['recycleID']}');
      } else if (map.containsKey('goodsID')) {
        isLocked = lockIds.contains('goods:${map['goodsID']}');
      } else if (map.containsKey('itemID')) {
        isLocked = lockIds.contains('item:${map['itemID']}');
      }
      if (!isLocked) {
        if (map.containsKey('qty')) {
          total += (map['qty'] as int?) ?? 0;
        } else {
          total += 1;
        }
      }
    }
    return total;
  }

  /// 已盘库数量
  int get actualQuantity => stockTakeCount;

  /// 盘亏数量（系统有但未盘的）
  int get computedOutOfStockQuantity {
    if (stockSYS == null) return 0;
    final takeIds = <String>{};
    if (stockTake != null) {
      for (final item in stockTake!) {
        final map = item as Map<String, dynamic>;
        if (map.containsKey('recycleID')) {
          takeIds.add('recycle:${map['recycleID']}');
        } else if (map.containsKey('goodsID')) {
          takeIds.add('goods:${map['goodsID']}');
        } else if (map.containsKey('itemID')) {
          takeIds.add('item:${map['itemID']}');
        } else if (map.containsKey('productID')) {
          takeIds.add('product:${map['productID']}');
        }
      }
    }
    // 从去锁货后的stockSYS中统计未盘的
    final lockIds = <String>{};
    if (lockSYS != null) {
      for (final item in lockSYS!) {
        final map = item as Map<String, dynamic>;
        if (map.containsKey('recycleID')) lockIds.add('recycle:${map['recycleID']}');
        else if (map.containsKey('goodsID')) lockIds.add('goods:${map['goodsID']}');
        else if (map.containsKey('itemID')) lockIds.add('item:${map['itemID']}');
        else if (map.containsKey('productID')) lockIds.add('product:${map['productID']}');
      }
    }

    int total = 0;
    for (final item in stockSYS!) {
      final map = item as Map<String, dynamic>;
      bool isLocked = false;
      String key = '';
      if (map.containsKey('recycleID')) {
        key = 'recycle:${map['recycleID']}';
        isLocked = lockIds.contains(key);
      } else if (map.containsKey('goodsID')) {
        key = 'goods:${map['goodsID']}';
        isLocked = lockIds.contains(key);
      } else if (map.containsKey('itemID')) {
        key = 'item:${map['itemID']}';
        isLocked = lockIds.contains(key);
      } else if (map.containsKey('productID')) {
        key = 'product:${map['productID']}';
        isLocked = lockIds.contains(key);
      }
      if (!isLocked && !takeIds.contains(key)) {
        if (map.containsKey('qty')) {
          total += (map['qty'] as int?) ?? 0;
        } else {
          total += 1;
        }
      }
    }
    return total;
  }

  /// 盘盈数量（盘了但系统没有的）
  int get extraQuantity {
    if (stockTake == null) return 0;
    if (stockSYS == null) return stockTakeCount;

    final sysIds = <String>{};
    for (final item in stockSYS!) {
      final map = item as Map<String, dynamic>;
      String key = '';
      if (map.containsKey('recycleID')) {
        key = 'recycle:${map['recycleID']}';
      } else if (map.containsKey('goodsID')) {
        key = 'goods:${map['goodsID']}';
      } else if (map.containsKey('itemID')) {
        key = 'item:${map['itemID']}';
      } else if (map.containsKey('productID')) {
        key = 'product:${map['productID']}';
      }
      sysIds.add(key);
    }

    int total = 0;
    for (final item in stockTake!) {
      final map = item as Map<String, dynamic>;
      String key = '';
      if (map.containsKey('recycleID')) {
        key = 'recycle:${map['recycleID']}';
      } else if (map.containsKey('goodsID')) {
        key = 'goods:${map['goodsID']}';
      } else if (map.containsKey('itemID')) {
        key = 'item:${map['itemID']}';
      } else if (map.containsKey('productID')) {
        key = 'product:${map['productID']}';
      }
      if (!sysIds.contains(key)) {
        if (map.containsKey('qty')) {
          total += (map['qty'] as int?) ?? 0;
        } else {
          total += 1;
        }
      }
    }
    return total;
  }

  String get formattedCreatedAt {
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 盘库值班状态
enum StocktakingOnDutyStatus {
  pending('pending', '待确认', Color(0xFFFF9500)),
  inUse('in-use', '在用已确认', Color(0xFF30D158)),
  complete('complete', '已完成', Color(0xFF8E8E93)),
  refused('refused', '已拒绝', Color(0xFFFF3B30));

  final String value;
  final String label;
  final Color color;

  const StocktakingOnDutyStatus(this.value, this.label, this.color);

  static StocktakingOnDutyStatus fromValue(String v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return pending;
  }
}

/// 用户盘库值班记录
class UserStocktakingOnDuty {
  final int id;
  final int warehouseID;
  final int planID;
  final int? preManager;
  final int? newManager;
  final int at;
  final StocktakingOnDutyStatus status;
  final int createdBy;
  final String? remarks;

  const UserStocktakingOnDuty({
    required this.id,
    required this.warehouseID,
    required this.planID,
    this.preManager,
    this.newManager,
    required this.at,
    required this.status,
    required this.createdBy,
    this.remarks,
  });

  factory UserStocktakingOnDuty.fromJson(Map<String, dynamic> json) {
    return UserStocktakingOnDuty(
      id: json['id'] as int? ?? 0,
      warehouseID: json['warehouseID'] as int? ?? 0,
      planID: json['planID'] as int? ?? 0,
      preManager: json['preManager'] as int?,
      newManager: json['newManager'] as int?,
      at: json['at'] as int? ?? 0,
      status: json['status'] is String
          ? StocktakingOnDutyStatus.fromValue(json['status'] as String)
          : StocktakingOnDutyStatus.fromValue('pending'),
      createdBy: json['createdBy'] as int? ?? 0,
      remarks: json['remarks'] as String?,
    );
  }
}

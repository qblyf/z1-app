/// 店长助手数据

/// 门店排行条目
class StoreRankItem {
  final int department;
  final int mainProductCount;
  final int totalGross;
  final int totalRatioAverageGross;

  StoreRankItem({
    required this.department,
    required this.mainProductCount,
    required this.totalGross,
    required this.totalRatioAverageGross,
  });

  factory StoreRankItem.fromJson(Map<String, dynamic> json) {
    return StoreRankItem(
      department: json['department'] as int,
      mainProductCount: _extractValue(json['mainProductCount']),
      totalGross: _extractValue(json['totalGross']),
      totalRatioAverageGross: _extractValue(json['totalRatioAverageGross']),
    );
  }

  static int _extractValue(dynamic v) {
    if (v is int) return v;
    if (v is Map) return v['value'] as int? ?? 0;
    return 0;
  }
}

/// 员工销售排行条目
class EmployeeSalesItem {
  final int userIdent;
  final int mainProductCount;
  final int totalGross;
  final int totalRatioAverageGross;

  EmployeeSalesItem({
    required this.userIdent,
    required this.mainProductCount,
    required this.totalGross,
    required this.totalRatioAverageGross,
  });

  factory EmployeeSalesItem.fromJson(Map<String, dynamic> json) {
    return EmployeeSalesItem(
      userIdent: json['userIdent'] as int? ?? 0,
      mainProductCount: _extractValue(json['mainProductCount']),
      totalGross: _extractValue(json['totalGross']),
      totalRatioAverageGross: _extractValue(json['totalRatioAverageGross']),
    );
  }

  static int _extractValue(dynamic v) {
    if (v is int) return v;
    if (v is Map) return v['value'] as int? ?? 0;
    return 0;
  }
}

/// 重点产品统计
class MainProductItem {
  final int productId;
  final int totalCount;
  final int totalGross;

  MainProductItem({
    required this.productId,
    required this.totalCount,
    required this.totalGross,
  });

  factory MainProductItem.fromJson(Map<String, dynamic> json) {
    return MainProductItem(
      productId: json['productId'] as int? ?? json['productID'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      totalGross: json['totalGross'] as int? ?? 0,
    );
  }
}

/// 重点产品员工销售详情条目
class MainProductEmplItem {
  final int seller;
  final int buyCount;
  final int totalGrossProfit;
  final double averageGrossProfit;
  final int totalCommissionPrice;

  MainProductEmplItem({
    required this.seller,
    required this.buyCount,
    required this.totalGrossProfit,
    required this.averageGrossProfit,
    required this.totalCommissionPrice,
  });

  factory MainProductEmplItem.fromJson(Map<String, dynamic> json) {
    return MainProductEmplItem(
      seller: json['seller'] as int? ?? 0,
      buyCount: json['buyCount'] as int? ?? 0,
      totalGrossProfit: json['totalGrossProfit'] as int? ?? 0,
      averageGrossProfit: (json['averageGrossProfit'] as num?)?.toDouble() ?? 0.0,
      totalCommissionPrice: json['totalCommissionPrice'] as int? ?? 0,
    );
  }
}

/// 目标进度条目
class TaskProgressItem {
  final String title;
  final String category;
  final String dimension;
  final int goals;
  final int currentProgress;

  TaskProgressItem({
    required this.title,
    required this.category,
    required this.dimension,
    required this.goals,
    required this.currentProgress,
  });

  factory TaskProgressItem.fromJson(Map<String, dynamic> json) {
    return TaskProgressItem(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      dimension: json['dimension'] as String? ?? '',
      goals: json['goals'] as int? ?? 0,
      currentProgress: json['currentProgress'] as int? ?? 0,
    );
  }
}

/// 任务进度
class TaskProgressRes {
  final int year;
  final int month;
  final int id;
  final int metrics;
  final String title;
  final String dimension;
  final int goals;
  final int currentProgress;
  final String category;

  TaskProgressRes({
    required this.year,
    required this.month,
    required this.id,
    required this.metrics,
    required this.title,
    required this.dimension,
    required this.goals,
    required this.currentProgress,
    required this.category,
  });

  factory TaskProgressRes.fromJson(Map<String, dynamic> json) {
    return TaskProgressRes(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      metrics: json['metrics'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      dimension: json['dimension'] as String? ?? '',
      goals: json['goals'] as int? ?? 0,
      currentProgress: json['currentProgress'] as int? ?? 0,
      category: json['category'] as String? ?? '',
    );
  }
}

/// 实际值
class ActualValueRes {
  final int id;
  final int? value;
  final String title;
  final String dimension;
  final String? category;

  ActualValueRes({
    required this.id,
    this.value,
    required this.title,
    required this.dimension,
    this.category,
  });

  factory ActualValueRes.fromJson(Map<String, dynamic> json) {
    return ActualValueRes(
      id: json['id'] as int? ?? 0,
      value: json['value'] as int?,
      title: json['title'] as String? ?? '',
      dimension: json['dimension'] as String? ?? '',
      category: json['category'] as String?,
    );
  }
}

/// 资金周转条目
class CapitalTurnoverItem {
  final int department;
  final int recentSalesIncome;
  final int currentStockCost;
  final double turnoverRate;

  CapitalTurnoverItem({
    required this.department,
    required this.recentSalesIncome,
    required this.currentStockCost,
    required this.turnoverRate,
  });

  factory CapitalTurnoverItem.fromJson(Map<String, dynamic> json) {
    return CapitalTurnoverItem(
      department: json['departmentID'] as int? ?? json['department'] as int? ?? 0,
      recentSalesIncome: _extractValue(json['recentDiscountAmount']),
      currentStockCost: _extractValue(json['currentCost']),
      turnoverRate: (json['recentCapitalTurnover'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static int _extractValue(dynamic v) {
    if (v is int) return v;
    if (v is Map) return v['value'] as int? ?? 0;
    return 0;
  }
}

/// 月度目标概览
class MonthlyGoalsPandect {
  final List<TaskProgressRes> taskProgressRes;
  final List<ActualValueRes> actualValueRes;
  final int lastTime;

  MonthlyGoalsPandect({
    required this.taskProgressRes,
    required this.actualValueRes,
    required this.lastTime,
  });

  factory MonthlyGoalsPandect.fromJson(Map<String, dynamic> json) {
    final taskList = (json['taskProgressRes'] as List?) ?? [];
    final actualList = (json['actualValueRes'] as List?) ?? [];
    return MonthlyGoalsPandect(
      taskProgressRes: taskList.map((e) => TaskProgressRes.fromJson(e as Map<String, dynamic>)).toList(),
      actualValueRes: actualList.map((e) => ActualValueRes.fromJson(e as Map<String, dynamic>)).toList(),
      lastTime: json['lastTime'] as int? ?? 0,
    );
  }
}

/// SPU排行条目
class SPURankingItem {
  final int spuId;
  final String? spuName;
  final int salesCount;
  final String salesCountRatio;
  final int salesAmount;
  final String salesAmountRatio;
  final int totalStock;
  final int departmentStock;
  final String stockSalesCountRatio;
  final String salesDay;
  final int sampleCount;

  SPURankingItem({
    required this.spuId,
    this.spuName,
    required this.salesCount,
    required this.salesCountRatio,
    required this.salesAmount,
    required this.salesAmountRatio,
    required this.totalStock,
    required this.departmentStock,
    required this.stockSalesCountRatio,
    required this.salesDay,
    required this.sampleCount,
  });

  factory SPURankingItem.fromJson(Map<String, dynamic> json) {
    return SPURankingItem(
      spuId: json['spuID'] as int? ?? 0,
      spuName: json['spuName'] as String?,
      salesCount: json['salesCount'] as int? ?? 0,
      salesCountRatio: json['salesCountRatio'] as String? ?? '',
      salesAmount: json['salesAmount'] as int? ?? 0,
      salesAmountRatio: json['salesAmountRatio'] as String? ?? '',
      totalStock: json['totalStock'] as int? ?? 0,
      departmentStock: json['departmentStock'] as int? ?? 0,
      stockSalesCountRatio: json['stockSalesCountRatio'] as String? ?? '',
      salesDay: json['salesDay'] as String? ?? '',
      sampleCount: json['sampleCount'] as int? ?? 0,
    );
  }
}

/// SKU排行条目
class SKURankingItem {
  final int productId;
  final String? productName;
  final int salesCount;
  final String salesCountRatio;
  final int salesAmount;
  final String salesAmountRatio;
  final int totalStock;
  final int departmentStock;
  final String stockSalesCountRatio;
  final String salesDay;
  final int sampleCount;

  SKURankingItem({
    required this.productId,
    this.productName,
    required this.salesCount,
    required this.salesCountRatio,
    required this.salesAmount,
    required this.salesAmountRatio,
    required this.totalStock,
    required this.departmentStock,
    required this.stockSalesCountRatio,
    required this.salesDay,
    required this.sampleCount,
  });

  factory SKURankingItem.fromJson(Map<String, dynamic> json) {
    return SKURankingItem(
      productId: json['productID'] as int? ?? 0,
      productName: json['productName'] as String?,
      salesCount: json['salesCount'] as int? ?? 0,
      salesCountRatio: json['salesCountRatio'] as String? ?? '',
      salesAmount: json['salesAmount'] as int? ?? 0,
      salesAmountRatio: json['salesAmountRatio'] as String? ?? '',
      totalStock: json['totalStock'] as int? ?? 0,
      departmentStock: json['departmentStock'] as int? ?? 0,
      stockSalesCountRatio: json['stockSalesCountRatio'] as String? ?? '',
      salesDay: json['salesDay'] as String? ?? '',
      sampleCount: json['sampleCount'] as int? ?? 0,
    );
  }
}

/// 区域排行条目
class AreaRankItem {
  final int department;
  final String? departmentName;
  final int mainProductCount;
  final int totalGross;
  final int totalAmount;

  AreaRankItem({
    required this.department,
    this.departmentName,
    required this.mainProductCount,
    required this.totalGross,
    required this.totalAmount,
  });

  factory AreaRankItem.fromJson(Map<String, dynamic> json) {
    return AreaRankItem(
      department: json['department'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      mainProductCount: _extractValue(json['mainProductCount']),
      totalGross: _extractValue(json['totalGross']),
      totalAmount: _extractValue(json['totalAmount']),
    );
  }

  static int _extractValue(dynamic v) {
    if (v is int) return v;
    if (v is Map) return v['value'] as int? ?? 0;
    return 0;
  }
}

/// 门店详情
class StoreDetail {
  final int id;
  final String name;
  final String? manager;
  final String? phone;
  final String? address;
  final int type;

  StoreDetail({
    required this.id,
    required this.name,
    this.manager,
    this.phone,
    this.address,
    required this.type,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    return StoreDetail(
      id: json['departmentID'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      manager: json['manager'] as String?,
      phone: json['telephone'] as String? ?? json['phone'] as String?,
      address: json['address'] as String?,
      type: json['type'] as int? ?? 0,
    );
  }
}

/// 分类统计数据条目
/// 对应后端 TypeStatsData: { type, value, target, monthTarget, comparedValue }
class TypeStatsDataItem {
  final String type;
  final int value;
  final int target;
  final int monthTarget;
  final int comparedValue;

  TypeStatsDataItem({
    required this.type,
    required this.value,
    required this.target,
    required this.monthTarget,
    required this.comparedValue,
  });

  factory TypeStatsDataItem.fromJson(Map<String, dynamic> json) {
    return TypeStatsDataItem(
      type: json['type'] as String? ?? '',
      value: _extractValue(json['value']),
      target: _extractValue(json['target']),
      monthTarget: _extractValue(json['monthTarget']),
      comparedValue: _extractValue(json['comparedValue']),
    );
  }

  static int _extractValue(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is Map) return (v['value'] as num?)?.toInt() ?? 0;
    return 0;
  }

  /// 月环比变化百分比
  double get comparedPercent {
    if (comparedValue == 0) return 0;
    return ((value - comparedValue) / comparedValue) * 100;
  }
}

/// 阶段统计数据
/// 对应后端 TypePhaseStats
class TypePhaseStats {
  final List<TypeStatsDataItem> count;
  final List<TypeStatsDataItem> gross;
  final List<TypeStatsDataItem> amount;
  final List<TypeStatsDataItem> cost;
  final List<TypeStatsDataItem> averageGross;
  final List<TypeStatsDataItem> relatedRate;
  final List<TypeStatsDataItem> other;

  TypePhaseStats({
    required this.count,
    required this.gross,
    required this.amount,
    required this.cost,
    required this.averageGross,
    required this.relatedRate,
    required this.other,
  });

  factory TypePhaseStats.fromJson(Map<String, dynamic> json) {
    List<TypeStatsDataItem> parseList(dynamic list) {
      if (list is! List) return [];
      return list.map((e) => TypeStatsDataItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    return TypePhaseStats(
      count: parseList(json['count']),
      gross: parseList(json['gross']),
      amount: parseList(json['amount']),
      cost: parseList(json['cost']),
      averageGross: parseList(json['averageGross']),
      relatedRate: parseList(json['relatedRate']),
      other: parseList(json['other']),
    );
  }
}

/// 经营助手首页数据（经营分析）
/// 对应 PWA /storekeeper-data/analyse-month-data
class ManagerHomepageData {
  final int updatedAt;
  final TypePhaseStats todayStatsRes;
  final TypePhaseStats monthStatsRes;

  ManagerHomepageData({
    required this.updatedAt,
    required this.todayStatsRes,
    required this.monthStatsRes,
  });

  factory ManagerHomepageData.fromJson(Map<String, dynamic> json) {
    return ManagerHomepageData(
      updatedAt: json['updatedAt'] as int? ?? 0,
      todayStatsRes: TypePhaseStats.fromJson(
        (json['todayStatsRes'] as Map<String, dynamic>?) ?? {},
      ),
      monthStatsRes: TypePhaseStats.fromJson(
        (json['monthStatsRes'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

/// 月度类目分析卡片数据
class MonthAnalyseCard {
  final String title;
  final String allocation; // 配比值
  final int count;
  final String gross; // 毛利（元）
  final String grossComparedPercent;
  final String relatedRate;

  MonthAnalyseCard({
    required this.title,
    required this.allocation,
    required this.count,
    required this.gross,
    required this.grossComparedPercent,
    required this.relatedRate,
  });
}

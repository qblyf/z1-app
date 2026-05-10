import 'package:equatable/equatable.dart';

/// 回收订单状态
enum RecycleOrderState {
  unpaid('unpaid', '未付款'),
  paid('paid', '已付款'),
  transfer('transfer', '调拨在途'),
  notRechecked('not-rechecked', '未复检'),
  rechecked('rechecked', '已复检'),
  nonStandardGoods('non-standard-goods', '转非标'),
  vendor('vendor', '渠道'),
  vendorSold('vendor-sold', '渠道售出'),
  undone('undone', '已撤销');

  const RecycleOrderState(this.value, this.label);
  final String value;
  final String label;

  static RecycleOrderState? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 回收订单模型
class RecycleOrder extends Equatable {
  final int id;
  /// 回收订单号
  final String number;
  /// 回收规则id
  final int ruleId;
  /// 手机串号
  final String serial;
  /// 回收时填写的串号
  final String? serialBefore;
  /// 验机照片
  final List<String> images;
  /// 回收规则名称快照
  final String ruleTitle;
  /// 支付方式
  final String paymentType;
  /// 顾客标识符
  final int customer;
  /// 根据支付方式保存的信息
  final String? payInfo;
  /// 实际支付金额（包括估价金额、活动金额等）
  final int actualAmount;
  /// 回收宝获取金额
  final int evalAmount;
  /// 估价通过加价率计算后的金额
  final int costAmount;
  /// 渠道售出价
  final int? platformPrice;
  /// 回收手机的部门ID
  final int department;
  /// 回收手机人员标识符
  final int operator;
  /// 回收订单创建时间
  final int createdAt;
  /// 复检
  final List<int>? recheck;
  /// 复检验机图片
  final List<String>? recheckImages;
  /// 复检差异
  final int recheckDifference;
  /// 售后复检人员标识符
  final int? inspector;
  /// 回收规则回答第一部分
  final List<String> specification;
  /// 渠道ID
  final int? vendor;
  /// 挂在渠道的订单
  final String? vendorOrder;
  /// 更新时间
  final int? updatedAt;
  /// 订单状态
  final String state;
  /// 备注
  final List<String> remarks;
  /// 调出时间
  final int? transferOutTime;
  /// 调出部门
  final int? outDept;
  /// 调拨人
  final int? transferOut;
  /// 调入时间
  final int? transferInTime;
  /// 调入部门
  final int? inDept;
  /// 接收人
  final int? transferIn;
  /// 已复检时间
  final int? recheckedTime;
  /// 转非标时间
  final int? nonStandardTime;
  /// 平台售出时间
  final int? platformSoldTime;
  /// 绑定的sku
  final int? sku;
  /// 关联的维修单号
  final List<String> repairOrder;
  /// 关联的扩展序列号
  final String? extendSerials;
  /// 根据回收规则选择的所有回答ID
  final List<int> selects;

  const RecycleOrder({
    required this.id,
    required this.number,
    required this.ruleId,
    required this.serial,
    this.serialBefore,
    this.images = const [],
    required this.ruleTitle,
    required this.paymentType,
    required this.customer,
    this.payInfo,
    required this.actualAmount,
    required this.evalAmount,
    required this.costAmount,
    this.platformPrice,
    required this.department,
    required this.operator,
    required this.createdAt,
    this.recheck,
    this.recheckImages,
    required this.recheckDifference,
    this.inspector,
    this.specification = const [],
    this.vendor,
    this.vendorOrder,
    this.updatedAt,
    required this.state,
    this.remarks = const [],
    this.transferOutTime,
    this.outDept,
    this.transferOut,
    this.transferInTime,
    this.inDept,
    this.transferIn,
    this.recheckedTime,
    this.nonStandardTime,
    this.platformSoldTime,
    this.sku,
    this.repairOrder = const [],
    this.extendSerials,
    this.selects = const [],
  });

  factory RecycleOrder.fromJson(Map<String, dynamic> json) {
    return RecycleOrder(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      ruleId: json['ruleID'] as int? ?? 0,
      serial: json['serial'] as String? ?? '',
      serialBefore: json['serialBefore'] as String?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ruleTitle: json['ruleTitle'] as String? ?? '',
      paymentType: json['paymentType'] as String? ?? '',
      customer: json['customer'] as int? ?? 0,
      payInfo: json['payInfo'] as String?,
      actualAmount: json['actualAmount'] as int? ?? 0,
      evalAmount: json['evalAmount'] as int? ?? 0,
      costAmount: json['costAmount'] as int? ?? 0,
      platformPrice: json['platformPrice'] as int?,
      department: json['department'] as int? ?? 0,
      operator: json['operator'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      recheck: (json['recheck'] as List<dynamic>?)?.map((e) => e as int).toList(),
      recheckImages: (json['recheckImages'] as List<dynamic>?)?.map((e) => e as String).toList(),
      recheckDifference: json['recheckDifference'] as int? ?? 0,
      inspector: json['inspector'] as int?,
      specification: (json['specification'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      vendor: json['vendor'] as int?,
      vendorOrder: json['vendorOrder'] as String?,
      updatedAt: json['updatedAt'] as int?,
      state: json['state'] as String? ?? 'unpaid',
      remarks: (json['remarks'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      transferOutTime: json['transferOutTime'] as int?,
      outDept: json['outDept'] as int?,
      transferOut: json['transferOut'] as int?,
      transferInTime: json['transferInTime'] as int?,
      inDept: json['inDept'] as int?,
      transferIn: json['transferIn'] as int?,
      recheckedTime: json['recheckedTime'] as int?,
      nonStandardTime: json['nonStandardTime'] as int?,
      platformSoldTime: json['platformSoldTime'] as int?,
      sku: json['sku'] as int?,
      repairOrder: (json['repairOrder'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      extendSerials: json['extendSerials'] as String?,
      selects: (json['selects'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  /// 状态枚举对象
  RecycleOrderState? get stateEnum => RecycleOrderState.fromValue(state);

  /// 状态显示文本
  String get stateLabel => stateEnum?.label ?? state;

  /// 格式化金额（分转元）
  String get actualAmountYuan => (actualAmount / 100).toStringAsFixed(2);

  /// 格式化估价（分转元）
  String get costAmountYuan => (costAmount / 100).toStringAsFixed(2);

  /// 格式化售出金额（分转元）
  String get platformPriceYuan => platformPrice != null ? (platformPrice! / 100).toStringAsFixed(2) : '-';

  @override
  List<Object?> get props => [
        id,
        number,
        ruleId,
        serial,
        serialBefore,
        images,
        ruleTitle,
        paymentType,
        customer,
        payInfo,
        actualAmount,
        evalAmount,
        costAmount,
        platformPrice,
        department,
        operator,
        createdAt,
        recheck,
        recheckImages,
        recheckDifference,
        inspector,
        specification,
        vendor,
        vendorOrder,
        updatedAt,
        state,
        remarks,
        transferOutTime,
        outDept,
        transferOut,
        transferInTime,
        inDept,
        transferIn,
        recheckedTime,
        nonStandardTime,
        platformSoldTime,
        sku,
        repairOrder,
        extendSerials,
        selects,
      ];
}

/// 回收订单统计
class RecycleOrderStatistics extends Equatable {
  final int count;
  final int totalActualAmount;
  final int totalCostAmount;

  const RecycleOrderStatistics({
    required this.count,
    required this.totalActualAmount,
    required this.totalCostAmount,
  });

  factory RecycleOrderStatistics.fromJson(Map<String, dynamic> json) {
    return RecycleOrderStatistics(
      count: json['count'] as int? ?? 0,
      totalActualAmount: json['totalActualAmount'] as int? ?? 0,
      totalCostAmount: json['totalCostAmount'] as int? ?? 0,
    );
  }

  String get totalActualAmountYuan => (totalActualAmount / 100).toStringAsFixed(2);
  String get totalCostAmountYuan => (totalCostAmount / 100).toStringAsFixed(2);

  @override
  List<Object?> get props => [count, totalActualAmount, totalCostAmount];
}

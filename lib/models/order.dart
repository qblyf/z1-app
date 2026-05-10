import 'dart:ui';
import 'package:equatable/equatable.dart';

/// 网销平台类型枚举
/// 对应后端 NetSalePlatformType
enum NetSalePlatformType {
  员工开单(2, '员工开单'),
  自有商城(3, '自有商城'),
  美团到店(4, '美团到店'),
  美团闪购(5, '美团闪购'),
  京东秒送(6, '京东秒送'),
  抖音来客(7, '抖音来客'),
  抖音小时达(8, '抖音小时达'),
  淘宝闪购(9, '淘宝闪购'),
  抖店(10, '抖店');

  final int value;
  final String label;
  const NetSalePlatformType(this.value, this.label);

  static NetSalePlatformType? fromValue(int? v) {
    if (v == null) return null;
    for (final t in values) {
      if (t.value == v) return t;
    }
    return null;
  }

  String get displayName => label;
}

/// 订单类型枚举
enum SalesModeText {
  inStore('店内', 'inStore'),
  online('网销', 'online'),
  wholesale('批发', 'wholesale'),
  repair('维修', 'repair'),
  recycle('回收', 'recycle');

  const SalesModeText(this.label, this.value);
  final String label;
  final String value;
}

/// 订单状态枚举
enum OrderStatus {
  unpaidNotShipped('未发货未付款', 1),
  paidNotShipped('未发货已付款', 2),
  shippedUnpaid('已发货未付款', 3),
  shippedPaid('已发货已付款', 4),
  cancelled('取消', 5);

  const OrderStatus(this.label, this.value);
  final String label;
  final int value;
}

/// 回收订单状态
enum RecycleOrderState {
  unpaid('未打款', 1),
  paid('已打款', 2),
  cancelled('已撤销', 3);

  const RecycleOrderState(this.label, this.value);
  final String label;
  final int value;
}

/// 订单项模型
class OrderItem extends Equatable {
  final int productId;
  final String? productName;
  final String? skuName;
  final int quantity;
  final int price;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    this.productName,
    this.skuName,
    this.quantity = 1,
    this.price = 0,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as int? ?? json['product_id'] as int? ?? 0,
      productName: json['productName'] as String? ?? json['product_name'] as String?,
      skuName: json['skuName'] as String? ?? json['sku_name'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      price: json['price'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'skuName': skuName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [productId, productName, skuName, quantity, price];
}

/// 订单模型
class Order extends Equatable {
  final int id;
  final String orderNumber;
  final String genre; // 订单类型: inStore, online, wholesale, repair, recycleOrder
  final int status;
  final int department;
  final String? departmentName;
  final int? createdBy;
  final int createdAt;
  final int? paidAt;
  final int? shippedAt;
  final int totalAmount;
  final int? discountAmount;
  final int? actualAmount;
  final List<OrderItem> items;
  final String? remark;
  final int? userIdent;
  final String? userName;
  final String? userPhone;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.genre,
    required this.status,
    required this.department,
    this.departmentName,
    this.createdBy,
    required this.createdAt,
    this.paidAt,
    this.shippedAt,
    this.totalAmount = 0,
    this.discountAmount,
    this.actualAmount,
    this.items = const [],
    this.remark,
    this.userIdent,
    this.userName,
    this.userPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> parseItems(dynamic itemsData) {
      if (itemsData == null) return [];
      if (itemsData is List) {
        return itemsData.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return Order(
      id: json['id'] as int? ?? 0,
      orderNumber: json['orderNumber'] as String? ?? json['order_number'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      status: json['status'] as int? ?? 1,
      department: json['department'] as int? ?? 0,
      departmentName: json['departmentName'] as String? ?? json['department_name'] as String?,
      createdBy: json['createdBy'] as int? ?? json['created_by'] as int?,
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int? ?? 0,
      paidAt: json['paidAt'] as int? ?? json['paid_at'] as int?,
      shippedAt: json['shippedAt'] as int? ?? json['shipped_at'] as int?,
      totalAmount: json['totalAmount'] as int? ?? json['total_amount'] as int? ?? 0,
      discountAmount: json['discountAmount'] as int? ?? json['discount_amount'] as int?,
      actualAmount: json['actualAmount'] as int? ?? json['actual_amount'] as int?,
      items: parseItems(json['items'] ?? json['itemsList'] ?? json['items_list']),
      remark: json['remark'] as String?,
      userIdent: json['userIdent'] as int? ?? json['user_ident'] as int?,
      userName: json['userName'] as String? ?? json['user_name'] as String?,
      userPhone: json['userPhone'] as String? ?? json['user_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'genre': genre,
      'status': status,
      'department': department,
      'departmentName': departmentName,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'shippedAt': shippedAt,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'actualAmount': actualAmount,
      'items': items.map((e) => e.toJson()).toList(),
      'remark': remark,
      'userIdent': userIdent,
      'userName': userName,
      'userPhone': userPhone,
    };
  }

  /// 获取订单类型标签
  String get genreLabel {
    switch (genre) {
      case 'inStore':
        return '销售';
      case 'online':
        return '网销';
      case 'wholesale':
        return '批发';
      case 'repair':
        return '服务';
      case 'recycleOrder':
        return '回收';
      default:
        return '未知';
    }
  }

  /// 获取状态标签
  String get statusLabel {
    if (genre == 'recycleOrder') {
      switch (status) {
        case 1:
          return '未打款';
        case 2:
          return '已打款';
        case 3:
          return '已撤销';
        default:
          return '未知';
      }
    } else {
      switch (status) {
        case 1:
          return '未发货未付款';
        case 2:
          return '未发货已付款';
        case 3:
          return '已发货未付款';
        case 4:
          return '已发货已付款';
        case 5:
          return '已取消';
        default:
          return '未知';
      }
    }
  }

  /// 格式化金额（元）
  String get formattedTotalAmount => '¥${(totalAmount / 100).toStringAsFixed(2)}';

  @override
  List<Object?> get props => [id, orderNumber, genre, status, createdAt];
}

/// ============================================================
/// 商城订单（销售订单 MallOrder）模型
/// 对应后端 z1-mid/src/model/z1/mall-order.ts
/// ============================================================

/// 商城订单状态
enum MallOrderStatusEnum {
  pending(0, '待付款', Color(0xFFFF9F0A)),
  paidNotShip(1, '已付款待发货', Color(0xFF0A84FF)),
  shippedNotReceive(2, '已发货待收货', Color(0xFFBF5AF2)),
  completed(3, '已完成', Color(0xFF30D158)),
  cancelled(4, '已取消', Color(0xFF8E8E93)),
  refunding(5, '退款中', Color(0xFFFF3B30)),
  refunded(6, '已退款', Color(0xFFFF6961));

  const MallOrderStatusEnum(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static MallOrderStatusEnum fromValue(int v) {
    return MallOrderStatusEnum.values.firstWhere(
      (s) => s.value == v,
      orElse: () => MallOrderStatusEnum.pending,
    );
  }
}

/// 商城订单商品项
class MallOrderProduct extends Equatable {
  final int skuId;
  final int? productId;
  final String? skuName;
  final String? productName;
  final int qty;
  final int skuPrice;
  final int discountPrice;
  final String? thumbnail;
  final String? name;

  const MallOrderProduct({
    required this.skuId,
    this.productId,
    this.skuName,
    this.productName,
    this.qty = 1,
    this.skuPrice = 0,
    this.discountPrice = 0,
    this.thumbnail,
    this.name,
  });

  factory MallOrderProduct.fromJson(Map<String, dynamic> json) {
    return MallOrderProduct(
      skuId: json['skuID'] as int? ?? json['skuId'] as int? ?? 0,
      productId: json['productID'] as int? ?? json['productId'] as int?,
      skuName: json['skuName'] as String? ?? json['sku_name'] as String?,
      productName: json['productName'] as String? ?? json['product_name'] as String?,
      qty: json['qty'] as int? ?? 1,
      skuPrice: json['skuPrice'] as int? ?? json['sku_price'] as int? ?? 0,
      discountPrice: json['discountPrice'] as int? ?? json['discount_price'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String? ?? json['imageUrl'] as String? ?? json['image_url'] as String?,
      name: json['name'] as String? ?? json['productName'] as String? ?? json['skuName'] as String? ?? '',
    );
  }

  /// 小计金额
  String get subtotal => '¥${(discountPrice / 100).toStringAsFixed(2)}';
  /// 用于展示的名称
  String get displayName => name ?? productName ?? skuName ?? '';

  @override
  List<Object?> get props => [skuId, productId, skuName, qty];
}

/// 商城订单模型
class MallOrder extends Equatable {
  final int mallId;
  final String number; // 订单编号
  final int customerIdent; // 顾客标识
  final String? customerName;
  final String? customerPhone;
  final int departmentId;
  final String? departmentName;
  final List<MallOrderProduct> products;
  final int status;
  final int orderAmount; // 原始金额（分）
  final int discountAmount; // 折扣后金额（分）
  final int? paidAt;
  final int? shippedAt;
  final int? createdAt;
  final String? remark;
  final String? expressName;
  final String? expressNumber;
  final String? addressName;
  final String? addressPhone;
  final String? addressDetail;
  // 新增字段
  final int? employeeId; // 导购员ID
  final String? employeeName; // 导购员名称
  final int? assistantId; // 助理ID
  final String? assistantName; // 助理名称
  final String? channel; // 销售渠道
  final int? coinAmount; // 积分抵扣金额（分）
  final int? couponAmount; // 优惠券抵扣金额（分）
  final String? couponTitle; // 优惠券名称
  final String? discountInfo; // 折扣说明
  final int? freightAmount; // 运费（分）
  final List<Map<String, dynamic>>? paymentDetails; // 支付明细
  final String? invoiceNumber; // 发票号
  final String? cancelReason; // 取消原因
  // 营业员
  final int? sellerIdent;
  // 专属导购
  final int? shoppingGuide;
  // 折扣审批 ZID
  final String? discountApprovalZID;
  // 标签ID列表
  final List<int>? labelIDs;
  // 订单图片
  final List<String>? images;
  // 现金券
  final List<Map<String, dynamic>>? cashCoupons;
  // 优惠券
  final List<Map<String, dynamic>>? coupons;
  // 协销人员 Map（协销角色类型 → 员工标识）
  /// key: recruitIdent(拉新人), sharer(分享人), qwCustomerService(企微客服)
  final Map<String, int>? assistantIdent;
  // 分享人标识（已支付订单的分享人）
  final int? sharerIdent;
  // 订单来源（网销平台类型）
  final int? salesChannel;

  const MallOrder({
    required this.mallId,
    required this.number,
    required this.customerIdent,
    this.customerName,
    this.customerPhone,
    required this.departmentId,
    this.departmentName,
    this.products = const [],
    required this.status,
    required this.orderAmount,
    required this.discountAmount,
    this.paidAt,
    this.shippedAt,
    this.createdAt,
    this.remark,
    this.expressName,
    this.expressNumber,
    this.addressName,
    this.addressPhone,
    this.addressDetail,
    this.employeeId,
    this.employeeName,
    this.assistantId,
    this.assistantName,
    this.channel,
    this.coinAmount,
    this.couponAmount,
    this.couponTitle,
    this.discountInfo,
    this.freightAmount,
    this.paymentDetails,
    this.invoiceNumber,
    this.cancelReason,
    this.sellerIdent,
    this.shoppingGuide,
    this.discountApprovalZID,
    this.labelIDs,
    this.images,
    this.cashCoupons,
    this.coupons,
    this.assistantIdent,
    this.sharerIdent,
    this.salesChannel,
  });

  factory MallOrder.fromJson(Map<String, dynamic> json) {
    List<MallOrderProduct> parseProducts(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => MallOrderProduct.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return MallOrder(
      mallId: json['mallID'] as int? ?? json['mallId'] as int? ?? 0,
      number: json['number'] as String? ?? json['orderNumber'] as String? ?? '',
      customerIdent: json['customerIdent'] as int? ?? 0,
      customerName: json['customerName'] as String? ?? json['name'] as String?,
      customerPhone: json['customerPhone'] as String? ?? json['phone'] as String?,
      departmentId: json['departmentID'] as int? ?? json['departmentId'] as int? ?? 0,
      departmentName: json['departmentName'] as String?,
      products: parseProducts(json['info'] ?? json['productInfo'] ?? json['products']),
      status: json['status'] as int? ?? 0,
      orderAmount: json['orderAmount'] as int? ?? 0,
      discountAmount: json['discountAmount'] as int? ?? 0,
      paidAt: json['paidAt'] as int? ?? json['paid_at'] as int?,
      shippedAt: json['shippedAt'] as int? ?? json['shipped_at'] as int?,
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int?,
      remark: json['remark'] as String?,
      expressName: json['expressName'] as String?,
      expressNumber: json['expressNumber'] as String?,
      addressName: json['addressName'] as String?,
      addressPhone: json['addressPhone'] as String?,
      addressDetail: json['addressDetail'] as String?,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      assistantId: json['assistantId'] as int?,
      assistantName: json['assistantName'] as String?,
      channel: json['channel'] as String?,
      coinAmount: json['coinAmount'] as int?,
      couponAmount: json['couponAmount'] as int?,
      couponTitle: json['couponTitle'] as String?,
      discountInfo: json['discountInfo'] as String?,
      freightAmount: json['freightAmount'] as int?,
      paymentDetails: (json['paymentDetails'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      invoiceNumber: json['invoiceNumber'] as String?,
      cancelReason: json['cancelReason'] as String?,
      sellerIdent: json['sellerIdent'] as int?,
      shoppingGuide: json['shoppingGuide'] as int?,
      discountApprovalZID: json['discountApprovalZID'] as String?,
      labelIDs: (json['labelIDs'] as List<dynamic>?)?.cast<int>(),
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      cashCoupons: (json['cashCoupons'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      coupons: (json['coupons'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      assistantIdent: (json['assistantIdent'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      sharerIdent: json['sharerIdent'] as int? ?? json['sharer'] as int?,
      salesChannel: json['salesChannel'] as int?,
    );
  }

  MallOrderStatusEnum get statusInfo => MallOrderStatusEnum.fromValue(status);
  /// 兼容 statusEnum 别名
  MallOrderStatusEnum get statusEnum => statusInfo;

  String get formattedAmount => '¥${(discountAmount / 100).toStringAsFixed(2)}';

  String get formattedOrderAmount => '¥${(orderAmount / 100).toStringAsFixed(2)}';

  String get formattedCreatedAt {
    if (createdAt == null) return '-';
    return DateTime.fromMillisecondsSinceEpoch(createdAt! * 1000)
        .toString()
        .substring(0, 16)
        .replaceAll('T', ' ');
  }

  /// 协销人员类型
  static const String assistantRecruit = 'recruitIdent'; // 拉新人
  static const String assistantSharer = 'sharerIdent'; // 分享人
  static const String assistantQwCS = 'qwCustomerService'; // 企微客服

  /// 获取指定类型的协销员工标识
  int? getAssistantIdent(String type) => assistantIdent?[type];

  /// 是否有协销人员
  bool get hasAssistant => assistantIdent != null && assistantIdent!.isNotEmpty;

  /// 订单来源（网销平台类型）
  NetSalePlatformType? get salesChannelType => NetSalePlatformType.fromValue(salesChannel);

  /// 获取协销人员标签列表
  List<String> get assistantLabels {
    if (assistantIdent == null) return [];
    return assistantIdent!.entries.map((e) => _assistantLabelMap[e.key] ?? e.key).toList();
  }

  static const Map<String, String> _assistantLabelMap = {
    'recruitIdent': '拉新人',
    'sharerIdent': '分享人',
    'qwCustomerService': '企微客服',
  };

  @override
  List<Object?> get props => [mallId, number, status];
}

// ── 商城订单完整详情（来自 new-order-mall-order-detail） ─────────────────────

/// 商城订单完整详情
/// 对应 PWA getNewOrderDetailByMallNumber /mall-order/new-order-mall-order-detail
class MallOrderFullDetail extends Equatable {
  final String mallOrderNumber;
  final MallOrder mallOrder;
  final List<NetSaleOrderItem> netSaleOrder;
  final List<NetSaleOrderItem> netSaleBackOrder;
  /// 折扣审批 ZID（用于查询折扣审批状态）
  final String? discountApprovalZID;

  const MallOrderFullDetail({
    required this.mallOrderNumber,
    required this.mallOrder,
    this.netSaleOrder = const [],
    this.netSaleBackOrder = const [],
    this.discountApprovalZID,
  });

  factory MallOrderFullDetail.fromJson(Map<String, dynamic> json) {
    List<NetSaleOrderItem> parseNetSaleOrders(dynamic list) {
      if (list is List) {
        return list.map((e) => NetSaleOrderItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    }

    final mallOrder = MallOrder.fromJson((json['mallOrder'] ?? json) as Map<String, dynamic>);

    return MallOrderFullDetail(
      mallOrderNumber: json['mallOrderNumber'] as String? ?? '',
      mallOrder: mallOrder,
      netSaleOrder: parseNetSaleOrders(json['netSaleOrder']),
      netSaleBackOrder: parseNetSaleOrders(json['netSaleBackOrder']),
      discountApprovalZID: json['discountApprovalZID'] as String? ?? mallOrder.discountApprovalZID,
    );
  }

  /// 是否有折扣审批记录
  bool get hasDiscountApproval => discountApprovalZID != null && discountApprovalZID!.isNotEmpty;

  /// 订单是否处于待支付或部分支付状态（需要显示折扣审批）
  bool get needsDiscountApproval =>
      mallOrder.status == 0 || mallOrder.status == 5; // 待支付、部分支付

  @override
  List<Object?> get props => [mallOrderNumber, mallOrder, netSaleOrder, netSaleBackOrder, discountApprovalZID];
}

/// 网销订单项（来自 new-order-mall-order-detail）
/// 包含 orderInfo, productInfo, serviceInfo, itemInfo, salesNet
class NetSaleOrderItem extends Equatable {
  final NetSaleOrderInfo? orderInfo;
  final List<NetSaleProduct> productInfo;
  final List<NetSaleService> serviceInfo;
  final List<OrderItem> itemInfo;
  final NetSale? salesNet;
  final List<DiscountInfo>? discountInfo;

  const NetSaleOrderItem({
    this.orderInfo,
    this.productInfo = const [],
    this.serviceInfo = const [],
    this.itemInfo = const [],
    this.salesNet,
    this.discountInfo,
  });

  factory NetSaleOrderItem.fromJson(Map<String, dynamic> json) {
    List<NetSaleProduct> parseProducts(dynamic list) {
      if (list is List) return list.map((e) => NetSaleProduct.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    List<NetSaleService> parseServices(dynamic list) {
      if (list is List) return list.map((e) => NetSaleService.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    List<OrderItem> parseItems(dynamic list) {
      if (list is List) return list.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    List<DiscountInfo> parseDiscounts(dynamic list) {
      if (list is List) return list.map((e) => DiscountInfo.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    return NetSaleOrderItem(
      orderInfo: json['orderInfo'] != null
          ? NetSaleOrderInfo.fromJson(json['orderInfo'] as Map<String, dynamic>)
          : null,
      productInfo: parseProducts(json['productInfo']),
      serviceInfo: parseServices(json['serviceInfo']),
      itemInfo: parseItems(json['itemInfo']),
      salesNet: json['salesNet'] != null
          ? NetSale.fromJson(json['salesNet'] as Map<String, dynamic>)
          : null,
      discountInfo: parseDiscounts(json['discountInfo']),
    );
  }

  /// 提取所有赠品（discountInfo 中 type=gift）
  List<GiveawayItem> get giveaways {
    if (discountInfo == null) return [];
    return discountInfo!
        .where((d) => d.type == DiscountInfoType.gift)
        .map((d) => d.asGiveaway())
        .whereType<GiveawayItem>()
        .toList();
  }

  @override
  List<Object?> get props => [orderInfo, productInfo, serviceInfo, itemInfo];
}

/// 网销订单基础信息
class NetSaleOrderInfo extends Equatable {
  final String? orderNumber;
  final String? orderType;
  final int? status;
  final int? employeeId;
  final String? employeeName;
  final int? departmentId;
  final String? departmentName;

  const NetSaleOrderInfo({
    this.orderNumber,
    this.orderType,
    this.status,
    this.employeeId,
    this.employeeName,
    this.departmentId,
    this.departmentName,
  });

  factory NetSaleOrderInfo.fromJson(Map<String, dynamic> json) {
    return NetSaleOrderInfo(
      orderNumber: json['orderNumber'] as String?,
      orderType: json['orderType'] as String?,
      status: json['status'] as int?,
      employeeId: json['employeeID'] as int?,
      employeeName: json['employeeName'] as String?,
      departmentId: json['departmentID'] as int?,
      departmentName: json['departmentName'] as String?,
    );
  }

  @override
  List<Object?> get props => [orderNumber, status];
}

/// 网销商品信息
class NetSaleProduct extends Equatable {
  final int skuId;
  final int? productId;
  final String? skuName;
  final String? productName;
  final int qty;
  final int? skuPrice;
  final int? discountPrice;
  final String? thumbnail;
  final int? orderItemId;
  final List<DiscountInfo>? discountInfo;

  const NetSaleProduct({
    required this.skuId,
    this.productId,
    this.skuName,
    this.productName,
    this.qty = 1,
    this.skuPrice,
    this.discountPrice,
    this.thumbnail,
    this.orderItemId,
    this.discountInfo,
  });

  factory NetSaleProduct.fromJson(Map<String, dynamic> json) {
    List<DiscountInfo> parseDiscounts(dynamic list) {
      if (list is List) return list.map((e) => DiscountInfo.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    return NetSaleProduct(
      skuId: json['skuID'] as int? ?? json['skuId'] as int? ?? 0,
      productId: json['productID'] as int?,
      skuName: json['skuName'] as String?,
      productName: json['productName'] as String?,
      qty: json['qty'] as int? ?? 1,
      skuPrice: json['skuPrice'] as int?,
      discountPrice: json['discountPrice'] as int?,
      thumbnail: json['thumbnail'] as String?,
      orderItemId: json['orderItemID'] as int?,
      discountInfo: parseDiscounts(json['discountInfo']),
    );
  }

  /// 获取赠品列表
  List<GiveawayItem> get giveaways {
    if (discountInfo == null) return [];
    return discountInfo!
        .where((d) => d.type == DiscountInfoType.gift)
        .map((d) => d.asGiveaway())
        .whereType<GiveawayItem>()
        .toList();
  }

  @override
  List<Object?> get props => [skuId, qty];
}

/// 网销服务信息
class NetSaleService extends Equatable {
  final int serviceId;
  final String? serviceName;
  final int? servicePrice;
  final int? discountPrice;
  final int? qty;
  final int? orderServiceId;
  final List<DiscountInfo>? discountInfo;

  const NetSaleService({
    required this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.discountPrice,
    this.qty = 1,
    this.orderServiceId,
    this.discountInfo,
  });

  factory NetSaleService.fromJson(Map<String, dynamic> json) {
    List<DiscountInfo> parseDiscounts(dynamic list) {
      if (list is List) return list.map((e) => DiscountInfo.fromJson(e as Map<String, dynamic>)).toList();
      return [];
    }

    return NetSaleService(
      serviceId: json['serviceID'] as int? ?? json['serviceId'] as int? ?? 0,
      serviceName: json['serviceName'] as String?,
      servicePrice: json['servicePrice'] as int?,
      discountPrice: json['discountPrice'] as int?,
      qty: json['qty'] as int? ?? 1,
      orderServiceId: json['orderServiceID'] as int?,
      discountInfo: parseDiscounts(json['discountInfo']),
    );
  }

  @override
  List<Object?> get props => [serviceId, qty];
}

/// 网销信息（渠道）
class NetSale extends Equatable {
  final String? netSaleNumber;
  final String? netSalePlatform;
  final String? platformType;
  final int? departmentId;
  final String? departmentName;

  const NetSale({
    this.netSaleNumber,
    this.netSalePlatform,
    this.platformType,
    this.departmentId,
    this.departmentName,
  });

  factory NetSale.fromJson(Map<String, dynamic> json) {
    return NetSale(
      netSaleNumber: json['netSaleNumber'] as String?,
      netSalePlatform: json['netSalePlatform'] as String?,
      platformType: json['platformType'] as String?,
      departmentId: json['departmentID'] as int?,
      departmentName: json['departmentName'] as String?,
    );
  }

  @override
  List<Object?> get props => [netSaleNumber];
}

/// 折扣信息类型枚举
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
    for (final t in values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

/// 折扣/优惠信息
class DiscountInfo extends Equatable {
  final DiscountInfoType type;
  final int? skuId;
  final int? serviceId;
  final int? itemId;
  final int? couponId;
  final String? couponTitle;
  final int? amount;
  final int? discount;
  final int? priceChangeId;
  final List<int>? giveawayActivityIds;

  const DiscountInfo({
    required this.type,
    this.skuId,
    this.serviceId,
    this.itemId,
    this.couponId,
    this.couponTitle,
    this.amount,
    this.discount,
    this.priceChangeId,
    this.giveawayActivityIds,
  });

  factory DiscountInfo.fromJson(Map<String, dynamic> json) {
    return DiscountInfo(
      type: DiscountInfoType.fromValue(json['type'] as String?) ?? DiscountInfoType.gift,
      skuId: json['skuID'] as int?,
      serviceId: json['serviceID'] as int?,
      itemId: json['itemID'] as int?,
      couponId: json['couponID'] as int?,
      couponTitle: json['couponTitle'] as String?,
      amount: json['amount'] as int?,
      discount: json['discount'] as int?,
      priceChangeId: json['priceChangeID'] as int?,
      giveawayActivityIds: (json['giveawayActivityIDs'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  /// 转为赠品项（如果是赠品类型）
  GiveawayItem? asGiveaway() {
    if (type != DiscountInfoType.gift) return null;
    if (skuId != null) {
      return GiveawayItem.sku(skuId: skuId!, discount: discount ?? 0);
    }
    if (serviceId != null) {
      return GiveawayItem.service(serviceId: serviceId!, discount: discount ?? 0);
    }
    return null;
  }

  @override
  List<Object?> get props => [type, skuId, serviceId, couponId];
}

/// 赠品项
class GiveawayItem extends Equatable {
  final String key;
  final GiveawayItemType itemType;
  final int? skuId;
  final int? serviceId;
  final int? itemId;
  final int discount;

  const GiveawayItem._({
    required this.key,
    required this.itemType,
    this.skuId,
    this.serviceId,
    this.itemId,
    this.discount = 0,
  });

  factory GiveawayItem.sku({required int skuId, int discount = 0}) {
    return GiveawayItem._(key: 'sku-$skuId', itemType: GiveawayItemType.sku, skuId: skuId, discount: discount);
  }

  factory GiveawayItem.service({required int serviceId, int discount = 0}) {
    return GiveawayItem._(key: 'service-$serviceId', itemType: GiveawayItemType.service, serviceId: serviceId, discount: discount);
  }

  factory GiveawayItem.item({required int itemId, int discount = 0}) {
    return GiveawayItem._(key: 'item-$itemId', itemType: GiveawayItemType.item, itemId: itemId, discount: discount);
  }

  @override
  List<Object?> get props => [key, itemType, skuId, serviceId, itemId];
}

enum GiveawayItemType { sku, service, item }

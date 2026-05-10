import 'dart:ui';
import 'package:equatable/equatable.dart';

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

  @override
  List<Object?> get props => [mallId, number, status];
}

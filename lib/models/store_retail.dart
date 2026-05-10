import 'package:equatable/equatable.dart';
import 'dart:ui';

/// 门店零售 - 商城商品/服务/非标品 购物车项模型
/// 对应 PWA 的 MallItem union type (MallSKU | MallServe | MallNonStandard)

/// 零售订单类型枚举
enum RetailOrderType {
  standard('standard', '标准零售单'),
  nonStandard('nonStandard', '非标零售单'),
  service('service', '服务单');

  const RetailOrderType(this.value, this.label);
  final String value;
  final String label;
}

/// 商城 SKU 商品项（标准商品）
class RetailSkuItem extends Equatable {
  final int skuId;
  final int spuId;
  final String name;
  final int qty;
  final int discountPrice; // 分
  final int skuPrice; // 分
  final String? thumbnail;
  final int stock;
  final List<RetailServiceItem> services; // 附加服务
  final int? goodsId; // 货品ID（用于串码绑定）
  final bool isHasGiveawaysActivity; // 是否有赠品活动
  final Map<String, dynamic>? extra;

  const RetailSkuItem({
    required this.skuId,
    required this.spuId,
    required this.name,
    this.qty = 1,
    required this.discountPrice,
    required this.skuPrice,
    this.thumbnail,
    this.stock = 0,
    this.services = const [],
    this.goodsId,
    this.isHasGiveawaysActivity = false,
    this.extra,
  });

  factory RetailSkuItem.fromJson(Map<String, dynamic> json) {
    return RetailSkuItem(
      skuId: json['skuID'] as int? ?? json['skuId'] as int? ?? json['id'] as int? ?? 0,
      spuId: json['spuID'] as int? ?? json['spuId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      qty: json['qty'] as int? ?? 1,
      discountPrice: json['discountPrice'] as int? ?? json['price'] as int? ?? 0,
      skuPrice: json['skuPrice'] as int? ?? json['originalPrice'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String?,
      stock: json['stock'] as int? ?? 0,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => RetailServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goodsId: json['goodsID'] as int?,
      isHasGiveawaysActivity:
          json['isHasGiveawaysActivity'] as bool? ?? false,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skuID': skuId,
      'spuID': spuId,
      'name': name,
      'qty': qty,
      'discountPrice': discountPrice,
      'skuPrice': skuPrice,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'stock': stock,
      'services': services.map((e) => e.toJson()).toList(),
      if (goodsId != null) 'goodsID': goodsId,
      'isHasGiveawaysActivity': isHasGiveawaysActivity,
    };
  }

  int get subtotal => discountPrice * qty;
  String get formattedPrice => '¥${(discountPrice / 100).toStringAsFixed(2)}';
  String get formattedOriginalPrice => '¥${(skuPrice / 100).toStringAsFixed(2)}';

  RetailSkuItem copyWith({
    int? skuId,
    int? spuId,
    String? name,
    int? qty,
    int? discountPrice,
    int? skuPrice,
    String? thumbnail,
    int? stock,
    List<RetailServiceItem>? services,
    int? goodsId,
    bool? isHasGiveawaysActivity,
  }) {
    return RetailSkuItem(
      skuId: skuId ?? this.skuId,
      spuId: spuId ?? this.spuId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      discountPrice: discountPrice ?? this.discountPrice,
      skuPrice: skuPrice ?? this.skuPrice,
      thumbnail: thumbnail ?? this.thumbnail,
      stock: stock ?? this.stock,
      services: services ?? this.services,
      goodsId: goodsId ?? this.goodsId,
      isHasGiveawaysActivity: isHasGiveawaysActivity ?? this.isHasGiveawaysActivity,
    );
  }

  @override
  List<Object?> get props => [skuId, spuId, qty, discountPrice, services];
}

/// 商城服务项
class RetailServiceItem extends Equatable {
  final int serviceId;
  final String name;
  final String? shortName;
  final int price; // 分
  final int discountPrice; // 分
  final int qty;
  final int? goodsId; // 关联货品
  final bool isGoods; // 是否为货品
  final bool isHasGiveawaysActivity;

  const RetailServiceItem({
    required this.serviceId,
    required this.name,
    this.shortName,
    required this.price,
    this.discountPrice = 0,
    this.qty = 1,
    this.goodsId,
    this.isGoods = false,
    this.isHasGiveawaysActivity = false,
  });

  factory RetailServiceItem.fromJson(Map<String, dynamic> json) {
    return RetailServiceItem(
      serviceId: json['serviceID'] as int? ?? json['serviceId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      price: json['price'] as int? ?? 0,
      discountPrice: json['discountPrice'] as int? ?? 0,
      qty: json['qty'] as int? ?? 1,
      goodsId: json['goodsID'] as int?,
      isGoods: json['isGoods'] as bool? ?? false,
      isHasGiveawaysActivity:
          json['isHasGiveawaysActivity'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceID': serviceId,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      'price': price,
      'discountPrice': discountPrice,
      'qty': qty,
      if (goodsId != null) 'goodsID': goodsId,
      'isGoods': isGoods,
      'isHasGiveawaysActivity': isHasGiveawaysActivity,
    };
  }

  int get effectivePrice => discountPrice > 0 ? discountPrice : price;
  String get formattedPrice => '¥${(effectivePrice / 100).toStringAsFixed(2)}';

  RetailServiceItem copyWith({
    int? serviceId,
    String? name,
    String? shortName,
    int? price,
    int? discountPrice,
    int? qty,
    int? goodsId,
    bool? isGoods,
    bool? isHasGiveawaysActivity,
  }) {
    return RetailServiceItem(
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      qty: qty ?? this.qty,
      goodsId: goodsId ?? this.goodsId,
      isGoods: isGoods ?? this.isGoods,
      isHasGiveawaysActivity: isHasGiveawaysActivity ?? this.isHasGiveawaysActivity,
    );
  }

  @override
  List<Object?> get props => [serviceId, price, discountPrice, qty];
}

/// 商城非标品项
class RetailNonStandardItem extends Equatable {
  final int itemId;
  final String name;
  final int itemPrice; // 分
  final int discountPrice; // 分
  final List<RetailServiceItem> services;
  final int? goodsId;
  final int qty;
  final Map<String, dynamic>? extra;

  const RetailNonStandardItem({
    required this.itemId,
    required this.name,
    required this.itemPrice,
    this.discountPrice = 0,
    this.services = const [],
    this.goodsId,
    this.qty = 1,
    this.extra,
  });

  factory RetailNonStandardItem.fromJson(Map<String, dynamic> json) {
    return RetailNonStandardItem(
      itemId: json['itemID'] as int? ?? json['itemId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      itemPrice: json['itemPrice'] as int? ?? 0,
      discountPrice: json['discountPrice'] as int? ?? 0,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => RetailServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goodsId: json['goodsID'] as int?,
      qty: json['qty'] as int? ?? 1,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemID': itemId,
      'name': name,
      'itemPrice': itemPrice,
      'discountPrice': discountPrice,
      'services': services.map((e) => e.toJson()).toList(),
      if (goodsId != null) 'goodsID': goodsId,
      'qty': qty,
    };
  }

  int get effectivePrice => discountPrice > 0 ? discountPrice : itemPrice;
  int get subtotal => effectivePrice * qty;
  String get formattedPrice => '¥${(effectivePrice / 100).toStringAsFixed(2)}';

  @override
  List<Object?> get props => [itemId, itemPrice, discountPrice, qty];
}

/// 零售购物车（合并所有项）
class RetailCart {
  final List<RetailSkuItem> products;
  final List<RetailServiceItem> services;
  final List<RetailNonStandardItem> nonStandards;
  final RetailOrderType orderType;

  const RetailCart({
    this.products = const [],
    this.services = const [],
    this.nonStandards = const [],
    this.orderType = RetailOrderType.standard,
  });

  /// 订单总金额（分）
  int get totalAmount {
    int amount = 0;
    for (final p in products) {
      amount += p.subtotal;
    }
    for (final s in services) {
      amount += s.effectivePrice * s.qty;
    }
    for (final n in nonStandards) {
      amount += n.subtotal;
    }
    return amount;
  }

  String get formattedTotal => '¥${(totalAmount / 100).toStringAsFixed(2)}';
  bool get isEmpty => products.isEmpty && services.isEmpty && nonStandards.isEmpty;
  int get itemCount => products.length + services.length + nonStandards.length;

  RetailCart copyWith({
    List<RetailSkuItem>? products,
    List<RetailServiceItem>? services,
    List<RetailNonStandardItem>? nonStandards,
    RetailOrderType? orderType,
  }) {
    return RetailCart(
      products: products ?? this.products,
      services: services ?? this.services,
      nonStandards: nonStandards ?? this.nonStandards,
      orderType: orderType ?? this.orderType,
    );
  }

  /// 转换为代下单 API 的 products 参数
  List<Map<String, dynamic>> toOrderProducts() {
    final list = <Map<String, dynamic>>[];
    for (final p in products) {
      list.add({
        'skuID': p.skuId,
        'qty': p.qty,
        'discountPrice': p.discountPrice,
        'services': p.services.map((e) => e.toJson()).toList(),
      });
    }
    for (final s in services) {
      list.add({
        'serviceID': s.serviceId,
        'qty': s.qty,
        'discountPrice': s.effectivePrice,
      });
    }
    for (final n in nonStandards) {
      list.add({
        'itemID': n.itemId,
        'qty': n.qty,
        'discountPrice': n.effectivePrice,
        'services': n.services.map((e) => e.toJson()).toList(),
      });
    }
    return list;
  }
}

/// 会员等级信息
class MemberLevel extends Equatable {
  final int id;
  final String name;
  final int minExperience;
  final Color color;

  const MemberLevel({
    required this.id,
    required this.name,
    required this.minExperience,
    required this.color,
  });

  factory MemberLevel.fromJson(Map<String, dynamic> json) {
    return MemberLevel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      minExperience: json['minExperience'] as int? ?? 0,
      color: _parseColor(json['color'] as String?),
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF8E8E93);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8E8E93);
    }
  }

  /// 根据经验值获取对应等级
  static MemberLevel fromExperience(int exp) {
    if (exp >= 50000) return levels.last;
    for (final level in levels) {
      if (exp < level.minExperience) {
        final idx = levels.indexOf(level);
        return idx > 0 ? levels[idx - 1] : levels.first;
      }
    }
    return levels.first;
  }

  static const levels = [
    MemberLevel(id: 1, name: '普通', minExperience: 0, color: Color(0xFF8E8E93)),
    MemberLevel(id: 2, name: '青铜', minExperience: 1000, color: Color(0xFFCD7F32)),
    MemberLevel(id: 3, name: '白银', minExperience: 5000, color: Color(0xFFC0C0C0)),
    MemberLevel(id: 4, name: '黄金', minExperience: 15000, color: Color(0xFFFFD700)),
    MemberLevel(id: 5, name: '铂金', minExperience: 30000, color: Color(0xFFE5E4E2)),
    MemberLevel(id: 6, name: '钻石', minExperience: 50000, color: Color(0xFFB9F2FF)),
  ];

  @override
  List<Object?> get props => [id, name, minExperience];
}

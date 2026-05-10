import 'package:equatable/equatable.dart';

/// 标签类型
enum LabelType {
  member('member', '会员'),
  product('product', '商品'),
  supplier('supplier', '供应商');

  final String value;
  final String label;

  const LabelType(this.value, this.label);

  static LabelType? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 标签状态
enum LabelState {
  normal('normal', '正常'),
  disabled('disabled', '禁用');

  final String value;
  final String label;

  const LabelState(this.value, this.label);

  static LabelState? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 标签模型
class Label extends Equatable {
  final int id;
  final String name;
  final LabelType type;
  final String color;
  final int order;
  final int createdAt;
  final LabelState state;
  final List<int> items; // 标签关联的会员ID列表

  const Label({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.order,
    required this.createdAt,
    required this.state,
    this.items = const [],
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: LabelType.fromValue(json['type'] as String?) ?? LabelType.member,
      color: json['color'] as String? ?? '#7B3763',
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
      state: LabelState.fromValue(json['state'] as String?) ?? LabelState.normal,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'color': color,
      'order': order,
      'createdAt': createdAt,
      'state': state.value,
      'items': items,
    };
  }

  /// 标签是否已关联指定会员
  bool isAssociated(int userIdent) => items.contains(userIdent);

  @override
  List<Object?> get props => [id, name, type, color, order, createdAt, state, items];
}

/// 会员销售偏好数据
class MemberSalesPreference extends Equatable {
  /// 购买偏好列表
  final List<BuyPreference> buyPreference;
  /// 旧机回收次数
  final int recycleCount;

  const MemberSalesPreference({
    required this.buyPreference,
    required this.recycleCount,
  });

  factory MemberSalesPreference.fromJson(Map<String, dynamic> json) {
    return MemberSalesPreference(
      buyPreference: (json['buyPreference'] as List<dynamic>?)
              ?.map((e) => BuyPreference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recycleCount: json['recycleCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [buyPreference, recycleCount];
}

/// 购买偏好
class BuyPreference extends Equatable {
  /// 分类ID
  final int cate;
  /// 分类名称
  final String? cateName;
  /// 购买次数
  final int saleProductQuantity;
  /// 退换货次数
  final int refundsChangeOrderQuantity;

  const BuyPreference({
    required this.cate,
    this.cateName,
    required this.saleProductQuantity,
    required this.refundsChangeOrderQuantity,
  });

  factory BuyPreference.fromJson(Map<String, dynamic> json) {
    return BuyPreference(
      cate: json['cate'] as int? ?? 0,
      cateName: json['cateName'] as String?,
      saleProductQuantity: json['saleProductQuantity'] as int? ?? 0,
      refundsChangeOrderQuantity: json['refundsChangeOrderQuantity'] as int? ?? 0,
    );
  }

  /// 根据分类获取偏好数据
  static BuyPreference? findByCate(List<BuyPreference> list, int cate) {
    try {
      return list.firstWhere((p) => p.cate == cate);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [cate, cateName, saleProductQuantity, refundsChangeOrderQuantity];
}

/// 偏好分类枚举
enum PreferenceCate {
  手机(1, '手机'),
  配件(3696, '配件'),
  电脑(1518, '电脑'),
  平板(1943, '平板'),
  保护壳(26, '保护壳'),
  贴膜(27, '贴膜');

  final int id;
  final String label;

  const PreferenceCate(this.id, this.label);

  static PreferenceCate? fromId(int id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

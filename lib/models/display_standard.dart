import 'package:equatable/equatable.dart';

/// 展陈标准类型
enum DisplayStandardType {
  board('board', '展位'),
  desk('desk', '体验桌');

  const DisplayStandardType(this.value, this.label);
  final String value;
  final String label;

  static DisplayStandardType? fromValue(String? v) {
    if (v == null) return null;
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

/// 标准商品
class StandardProduct extends Equatable {
  final int spuID;
  final String sort;

  const StandardProduct({required this.spuID, required this.sort});

  factory StandardProduct.fromJson(Map<String, dynamic> json) {
    return StandardProduct(
      spuID: json['spuID'] as int? ?? 0,
      sort: json['sort'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [spuID, sort];
}

/// 展陈标准模型
/// 对应后端 display-standard 系列接口
class DisplayStandard extends Equatable {
  /// 标准ID
  final int standardID;
  /// 标准名称
  final String name;
  /// 分类ID
  final int cateID;
  /// 类型
  final String type;
  /// 标准商品列表
  final List<StandardProduct>? standardProducts;
  /// 适用门店
  final List<int>? departmentIDs;
  /// 长（毫米）
  final int length;
  /// 宽（毫米）
  final int width;
  /// 高（毫米）
  final int height;
  /// 商品数量
  final int productQty;
  /// 材质
  final String? material;
  /// 参考图
  final List<String>? imgs;
  /// 创建时间
  final int createdAt;
  /// 创建人
  final String createdBy;
  /// 更新时间
  final int updatedAt;
  /// 更新人
  final String updatedBy;
  /// 备注
  final String? remarks;

  const DisplayStandard({
    required this.standardID,
    required this.name,
    required this.cateID,
    required this.type,
    this.standardProducts,
    this.departmentIDs,
    required this.length,
    required this.width,
    required this.height,
    required this.productQty,
    this.material,
    this.imgs,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.remarks,
  });

  factory DisplayStandard.fromJson(Map<String, dynamic> json) {
    return DisplayStandard(
      standardID: json['standardID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      cateID: json['cateID'] as int? ?? 0,
      type: json['type'] as String? ?? 'board',
      standardProducts: (json['standardProducts'] as List<dynamic>?)
          ?.map((e) => StandardProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      departmentIDs: (json['departmentIDs'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      length: json['length'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      productQty: json['productQty'] as int? ?? 0,
      material: json['material'] as String?,
      imgs: (json['imgs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as String? ?? '',
      remarks: json['remarks'] as String?,
    );
  }

  /// 类型枚举
  DisplayStandardType? get typeEnum => DisplayStandardType.fromValue(type);

  /// 是否有参考图
  bool get hasImages => imgs != null && imgs!.isNotEmpty;

  /// 尺寸描述
  String get sizeDesc => '${length}×${width}×${height}mm';

  @override
  List<Object?> get props => [
        standardID,
        name,
        cateID,
        type,
        standardProducts,
        departmentIDs,
        length,
        width,
        height,
        productQty,
        material,
        imgs,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        remarks,
      ];
}

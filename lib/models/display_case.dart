import 'package:equatable/equatable.dart';

/// 展台展位模型
/// 对应后端 display-case 系列接口
class DisplayCase extends Equatable {
  /// 展台ID
  final int caseID;
  /// 名称（取自标准名称）
  final String name;
  /// 所属部门
  final int departmentID;
  /// 展陈标准ID
  final int standardID;
  /// 商品ID列表
  final List<int>? itemIDs;
  /// 当前陈列图片
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

  const DisplayCase({
    required this.caseID,
    required this.name,
    required this.departmentID,
    required this.standardID,
    this.itemIDs,
    this.imgs,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.remarks,
  });

  factory DisplayCase.fromJson(Map<String, dynamic> json) {
    return DisplayCase(
      caseID: json['caseID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      departmentID: json['departmentID'] as int? ?? 0,
      standardID: json['standardID'] as int? ?? 0,
      itemIDs: (json['itemIDs'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
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

  /// 是否有陈列图片
  bool get hasImages => imgs != null && imgs!.isNotEmpty;

  /// 图片数量
  int get imageCount => imgs?.length ?? 0;

  @override
  List<Object?> get props => [
        caseID,
        name,
        departmentID,
        standardID,
        itemIDs,
        imgs,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        remarks,
      ];
}

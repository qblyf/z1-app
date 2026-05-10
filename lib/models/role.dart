import 'package:equatable/equatable.dart';

/// 角色模型
class Role extends Equatable {
  final int id;
  final String name;
  final int? weight;
  final List<int>? usergroupAccess;
  final List<String>? productAccess;
  final List<int>? departmentAccess;

  const Role({
    required this.id,
    required this.name,
    this.weight,
    this.usergroupAccess,
    this.productAccess,
    this.departmentAccess,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      weight: json['weight'] as int?,
      usergroupAccess: (json['usergroupAccess'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      productAccess: (json['productAccess'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      departmentAccess: (json['departmentAccess'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, weight];
}

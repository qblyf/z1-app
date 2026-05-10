import 'package:equatable/equatable.dart';

/// 员工信息
class Employee extends Equatable {
  final int id;
  final String? name;
  final int userIdent;
  final List<int> departmentIds;
  final int? currentDepartmentId;
  /// 工号
  final String? number;
  /// 钉钉头像 URL
  final String? dingAvatar;
  /// 所属部门 ID
  final int? departmentId;

  const Employee({
    required this.id,
    this.name,
    required this.userIdent,
    this.departmentIds = const [],
    this.currentDepartmentId,
    this.number,
    this.dingAvatar,
    this.departmentId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      userIdent: json['userIdent'] as int? ?? 0,
      departmentIds: (json['departmentIds'] as List<dynamic>?)?.cast<int>() ?? [],
      currentDepartmentId: json['currentDepartmentId'] as int?,
      number: json['number'] as String?,
      dingAvatar: json['dingAvatar'] as String?,
      departmentId: json['departmentId'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, userIdent];
}

/// 部门信息
class Department extends Equatable {
  final int id;
  final String? name;
  final String? parentName;

  const Department({
    required this.id,
    this.name,
    this.parentName,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      parentName: json['parentName'] as String?,
    );
  }

  @override
  List<Object?> get props => [id];
}

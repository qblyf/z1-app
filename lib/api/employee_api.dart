import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/employee.dart';

/// 员工 API
/// 对接 z1-mid 后端
class EmployeeApi {
  final _client = ApiClient();

  /// 根据用户标识获取职员信息
  /// GET /employee/by-ident?idents=X
  Future<List<Employee>> getByUserIdents(List<int> userIdents) async {
    if (userIdents.isEmpty) return [];
    final response = await _client.get(
      '/employee/by-ident',
      queryParameters: {'idents': userIdents.join(',')},
    );
    final list = response.data['res'] as List<dynamic>? ?? [];
    return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 根据部门 ID 获取部门详情
  /// GET /department/detail?departmentIDs=X
  Future<List<Department>> getDepartmentDetail(List<int> departmentIds) async {
    if (departmentIds.isEmpty) return [];
    final response = await _client.get(
      '/department/detail',
      queryParameters: {'departmentIDs': departmentIds.join(',')},
    );
    final list = response.data['res'] as List<dynamic>? ?? [];
    return list.map((e) => Department.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 切换当前部门
  /// POST /employee/switch-department，body: {department: X}
  Future<bool> switchDepartment(int departmentId) async {
    final response = await _client.post(
      '/employee/switch-department',
      data: {'department': departmentId},
    );
    final code = response.data['code'];
    return code == 10000 || code == 0 || code == 200 || response.data['res'] == true;
  }
}

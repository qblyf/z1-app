import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/employee_api.dart';
import '../../models/employee.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 部门切换页面 Provider
final departmentSwitchProvider = FutureProvider<List<Department>>((ref) async {
  final user = ref.read(currentUserProvider).value;
  if (user == null) return [];

  final api = EmployeeApi();
  // 获取职员信息
  final employees = await api.getByUserIdents([user.userIdent]);
  if (employees.isEmpty) return [];

  final deptIds = employees.first.departmentIds;
  if (deptIds.isEmpty) return [];

  // 获取部门详情
  return api.getDepartmentDetail(deptIds);
});

/// 部门切换页面
class DepartmentSwitchPage extends ConsumerStatefulWidget {
  const DepartmentSwitchPage({super.key});

  @override
  ConsumerState<DepartmentSwitchPage> createState() => _DepartmentSwitchPageState();
}

class _DepartmentSwitchPageState extends ConsumerState<DepartmentSwitchPage> {
  int? _selectedId;
  bool _isSwitching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 默认选中当前部门
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final api = EmployeeApi();
        try {
          final employees = await api.getByUserIdents([user.userIdent]);
          if (employees.isNotEmpty && employees.first.currentDepartmentId != null) {
            setState(() => _selectedId = employees.first.currentDepartmentId);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _doSwitch(Department dept) async {
    if (_isSwitching) return;
    setState(() {
      _isSwitching = true;
      _error = null;
    });

    try {
      final success = await EmployeeApi().switchDepartment(dept.id);
      if (!mounted) return;
      if (success) {
        _showToast('切换成功');
        Navigator.pop(context);
      } else {
        setState(() => _error = '切换失败，请重试');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentSwitchProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('切换部门'),
      ),
      child: SafeArea(
        child: departmentsAsync.when(
          data: (departments) {
            if (departments.isEmpty) {
              return const Center(child: Text('暂无可用部门'));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: departments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dept = departments[index];
                      final isSelected = dept.id == _selectedId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedId = dept.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : CupertinoColors.systemGrey5,
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isSelected ? AppColors.accent : CupertinoColors.systemGrey3,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dept.name ?? '部门${dept.id}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                    if (dept.parentName != null)
                                      Text(
                                        dept.parentName!,
                                        style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_error!, style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isSwitching
                          ? null
                          : () {
                              if (_selectedId == null) return;
                              final dept = departments.firstWhere((d) => d.id == _selectedId);
                              _doSwitch(dept);
                            },
                      child: _isSwitching
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text('确认切换'),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemGrey),
                const SizedBox(height: 12),
                Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: () => ref.invalidate(departmentSwitchProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

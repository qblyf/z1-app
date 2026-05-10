import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/task_management_api.dart';
import '../../api/employee_api.dart';
import '../../api/role_api.dart';
import '../../models/task_management.dart';
import '../../models/employee.dart';
import '../../models/role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 任务分配详情/编辑页
/// 对应 PWA /pages/path-d/task-management/task-allocation-info.tsx
/// 支持查看详情和编辑角色/职员/时长/重复周期等
class TaskAllocationInfoPage extends ConsumerStatefulWidget {
  final int allocationId;

  const TaskAllocationInfoPage({super.key, required this.allocationId});

  @override
  ConsumerState<TaskAllocationInfoPage> createState() => _TaskAllocationInfoPageState();
}

class _TaskAllocationInfoPageState extends ConsumerState<TaskAllocationInfoPage> {
  final TaskManagementApi _api = TaskManagementApi();
  final EmployeeApi _employeeApi = EmployeeApi();
  final RoleApi _roleApi = RoleApi();

  TaskAllocationDetail? _data;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  // 编辑状态
  List<int>? _editRoles;
  List<int>? _editEmployees;
  int? _editDuration;
  String? _editRepeatCycle;
  int? _editFrequency;
  List<int>? _editGiveDays;
  int? _editRepeatNum;
  DateTime? _editEndDate;
  List<Employee>? _employeeList; // 职员列表
  bool _isLoadingEmployees = false;
  List<Role>? _roleList; // 角色列表
  bool _isLoadingRoles = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadEmployees();
    _loadRoles();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getTaskAllocationDetail(widget.allocationId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final list = await _employeeApi.listEmployees();
      if (!mounted) return;
      setState(() {
        _employeeList = list;
        _isLoadingEmployees = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final list = await _roleApi.list();
      if (!mounted) return;
      setState(() {
        _roleList = list;
        _isLoadingRoles = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _api.editTaskAllocation(
        id: widget.allocationId,
        responsibleRoles: _editRoles,
        responsibleEmployees: _editEmployees,
        duration: _editDuration,
        repeatCycle: _editRepeatCycle,
        frequency: _editFrequency,
        giveDays: _editGiveDays,
        repeatNum: _editRepeatNum,
        endAt: _editEndDate != null
            ? (_editEndDate!.millisecondsSinceEpoch / 1000).round()
            : null,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSuccess('保存成功');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('保存失败: $e');
    }
  }

  void _showSuccess(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.activeGreen),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  bool get _hasChanges {
    if (_data == null) return false;
    if (_editRoles != null) return true;
    if (_editEmployees != null) return true;
    if (_editDuration != null && _editDuration != _data!.duration) return true;
    if (_editRepeatCycle != null && _editRepeatCycle != _data!.repeatCycle) {
      return true;
    }
    if (_editFrequency != null && _editFrequency != _data!.frequency) return true;
    if (_editGiveDays != null) return true;
    if (_editRepeatNum != null && _editRepeatNum != _data!.repeatNum) return true;
    if (_editEndDate != null) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('分配任务详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('返回'),
          onPressed: () => context.pop(),
        ),
        trailing: _data != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _hasChanges && !_isSaving ? _save : null,
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : Text(
                        '保存',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _hasChanges
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                        ),
                      ),
              )
            : null,
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载中...');
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _loadData);
    }

    if (_data == null) {
      return const EmptyWidget(
          message: '未找到任务分配', icon: CupertinoIcons.doc_text);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('基础信息', [
            _InfoRow(label: '任务模板', value: _data!.taskName ?? '-'),
            _InfoRow(label: '任务分类', value: _data!.taskTemplateCate ?? '-'),
            _InfoRow(label: '分配类型', value: _data!.allocationTypeLabel),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('编辑设置', [
            _buildRolesSelector(),
            const SizedBox(height: AppSpacing.sm),
            _buildEmployeeSelector(),
            const SizedBox(height: AppSpacing.sm),
            _buildDurationSelector(),
            const SizedBox(height: AppSpacing.sm),
            _buildRepeatCycleSelector(),
            if (_data!.repeatCycle == 'week' ||
                _editRepeatCycle == 'week' ||
                _data!.repeatCycle == 'month' ||
                _editRepeatCycle == 'month')
              _buildGiveDaysSelector(),
            if (_data!.repeatCycle != 'no' || _editRepeatCycle != 'no')
              _buildFrequencyField(),
            const SizedBox(height: AppSpacing.sm),
            _buildEndDateSelector(),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('时间信息', [
            _InfoRow(label: '开始时间', value: _data!.formattedStartAt),
            _InfoRow(label: '结束时间', value: _data!.formattedEndAt),
            _InfoRow(label: '持续时长', value: _data!.formattedDuration),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('发起信息', [
            _InfoRow(label: '创建人', value: _data!.creatorName ?? '-'),
            _InfoRow(label: '创建时间', value: _data!.formattedCreatedAt),
          ]),
          if (_data!.introduction != null && _data!.introduction!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSection('任务简介', [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(_data!.introduction!, style: AppText.body),
              ),
            ]),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Text(title, style: AppText.label),
          ),
          ...children,
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    final employees = _editEmployees ?? _data!.responsibleEmployees;
    final employeeNames = employees.map((id) {
      final emp = _employeeList?.where((e) => e.userIdent == id).firstOrNull;
      return emp?.name ?? '职员#$id';
    }).toList();

    return _EditableRow(
      label: '责任职员',
      value: employees.isEmpty ? '全部' : employeeNames.join(', '),
      onTap: () => _showEmployeePicker(),
      isEditing: _editEmployees != null,
    );
  }

  Widget _buildRolesSelector() {
    final roles = _editRoles ?? _data!.responsibleRoles;
    final roleNames = roles.map((id) {
      final role = _roleList?.where((r) => r.id == id).firstOrNull;
      return role?.name ?? '角色#$id';
    }).toList();

    return _EditableRow(
      label: '责任角色',
      value: roles.isEmpty ? '全部' : roleNames.join(', '),
      onTap: () => _showRolesPicker(),
      isEditing: _editRoles != null,
    );
  }

  void _showRolesPicker() {
    final selected = List<int>.from(_editRoles ?? _data!.responsibleRoles);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Text('选择责任角色',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey3),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingRoles
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      itemCount: _roleList?.length ?? 0,
                      itemBuilder: (context, index) {
                        final role = _roleList![index];
                        final isSelected = selected.contains(role.id);
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(role.id);
                              } else {
                                selected.add(role.id);
                              }
                              _editRoles = List.from(selected);
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role.name,
                                        style: const TextStyle(
                                            color: CupertinoColors.black,
                                            fontSize: 15)),
                                    if (role.weight != null)
                                      Text('权重: ${role.weight}',
                                          style: const TextStyle(
                                              color:
                                                  CupertinoColors.systemGrey,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey4,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemGrey5,
                      onPressed: () {
                        setState(() => _editRoles = []);
                        Navigator.pop(ctx);
                      },
                      child: const Text('清空',
                          style: TextStyle(color: CupertinoColors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeePicker() {
    final selected = List<int>.from(_editEmployees ?? _data!.responsibleEmployees);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Text('选择责任职员',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey3),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingEmployees
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      itemCount: _employeeList?.length ?? 0,
                      itemBuilder: (context, index) {
                        final emp = _employeeList![index];
                        final isSelected = selected.contains(emp.userIdent);
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(emp.userIdent);
                              } else {
                                selected.add(emp.userIdent);
                              }
                              _editEmployees = List.from(selected);
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.name ?? '职员',
                                        style: const TextStyle(
                                            color: CupertinoColors.black,
                                            fontSize: 15)),
                                    if (emp.phone != null)
                                      Text(emp.phone!,
                                          style: const TextStyle(
                                              color:
                                                  CupertinoColors.systemGrey,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey4,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemGrey5,
                      onPressed: () {
                        setState(() => _editEmployees = []);
                        Navigator.pop(ctx);
                      },
                      child: const Text('清空',
                          style: TextStyle(color: CupertinoColors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final current = _editDuration ?? _data!.duration;
    return _EditableRow(
      label: '持续时长',
      value: _formatDuration(current),
      onTap: _showDurationPicker,
      isEditing: _editDuration != null,
    );
  }

  String _formatDuration(int hours) {
    if (hours >= 24) {
      return '${(hours / 24).toStringAsFixed(0)}天';
    }
    return '$hours小时';
  }

  void _showDurationPicker() {
    final hours = [1, 2, 4, 8, 12, 24, 48, 72, 120, 168];
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择持续时长'),
        actions: hours
            .map((h) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _editDuration = h);
                    Navigator.pop(ctx);
                  },
                  child: Text(_formatDuration(h)),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildRepeatCycleSelector() {
    final current = _editRepeatCycle ?? _data!.repeatCycle;
    final options = [
      ('no', '不重复'),
      ('day', '每天'),
      ('week', '每周'),
      ('month', '每月'),
    ];
    return _EditableRow(
      label: '重复周期',
      value: options
          .firstWhere((o) => o.$1 == current,
              orElse: () => ('no', '不重复'))
          .$2,
      onTap: _showRepeatCyclePicker,
      isEditing: _editRepeatCycle != null,
    );
  }

  void _showRepeatCyclePicker() {
    final options = [
      ('no', '不重复'),
      ('day', '每天'),
      ('week', '每周'),
      ('month', '每月'),
    ];
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择重复周期'),
        actions: options
            .map((o) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() {
                      _editRepeatCycle = o.$1;
                      if (o.$1 == 'no') {
                        _editGiveDays = null;
                        _editFrequency = null;
                        _editRepeatNum = null;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(o.$2),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildGiveDaysSelector() {
    final isWeek = (_editRepeatCycle ?? _data!.repeatCycle) == 'week';
    final current = _editGiveDays ?? _data!.giveDays ?? [];
    final labels = ['一', '二', '三', '四', '五', '六', '日'];
    final max = isWeek ? 7 : 31;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 80, child: Text('发放日', style: AppText.label)),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(max, (i) {
                    final day = i + 1;
                    final isSelected = current.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          final newDays = List<int>.from(current);
                          if (isSelected) {
                            newDays.remove(day);
                          } else {
                            newDays.add(day);
                            newDays.sort();
                          }
                          _editGiveDays = newDays;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            isWeek ? labels[i] : '$day',
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyField() {
    final current = _editFrequency ?? _data!.frequency ?? 1;
    final textController = TextEditingController(text: '$current');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('频率', style: AppText.label)),
          Expanded(
            child: CupertinoTextField(
              controller: textController,
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (v) {
                setState(() => _editFrequency = int.tryParse(v) ?? 1);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            (_editRepeatCycle ?? _data!.repeatCycle) == 'day'
                ? '天执行一次'
                : '次/周期',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildEndDateSelector() {
    DateTime? current;
    if (_editEndDate != null) {
      current = _editEndDate;
    } else if (_data!.endAt != null && _data!.endAt != 0) {
      current = DateTime.fromMillisecondsSinceEpoch(_data!.endAt! * 1000);
    }

    return _EditableRow(
      label: '结束日期',
      value: current != null
          ? '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}'
          : '无限期',
      onTap: _showEndDatePicker,
      isEditing: _editEndDate != null,
    );
  }

  void _showEndDatePicker() {
    DateTime initial = _editEndDate ??
        (_data!.endAt != null && _data!.endAt != 0
            ? DateTime.fromMillisecondsSinceEpoch(_data!.endAt! * 1000)
            : DateTime.now().add(const Duration(days: 365)));

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              children: [
                CupertinoButton(
                  child: const Text('清空'),
                  onPressed: () {
                    setState(() => _editEndDate = null);
                    Navigator.pop(ctx);
                  },
                ),
                const Spacer(),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 3650)),
                onDateTimeChanged: (dt) {
                  setState(() => _editEndDate = dt);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppText.label)),
          Expanded(child: Text(value, style: AppText.body)),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isEditing;

  const _EditableRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label, style: AppText.label)),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color:
                      isEditing ? CupertinoColors.activeBlue : CupertinoColors.black,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }
}

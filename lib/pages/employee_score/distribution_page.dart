import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_score_providers.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';

/// 员工选择器
class _Employee {
  final int employeeId;
  final String name;
  final String? avatar;
  final int? departmentId;
  final String? departmentName;

  const _Employee({
    required this.employeeId,
    required this.name,
    this.avatar,
    this.departmentId,
    this.departmentName,
  });

  // ignore: unused_element
  factory _Employee.fromJson(Map<String, dynamic> json) {
    return _Employee(
      employeeId: json['employeeID'] as int? ?? json['employeeId'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      departmentId: json['departmentID'] as int?,
      departmentName: json['departmentName'] as String?,
    );
  }
}

/// 员工积分发放页面
class DistributionPage extends ConsumerStatefulWidget {
  const DistributionPage({super.key});

  @override
  ConsumerState<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends ConsumerState<DistributionPage> {
  final _searchController = TextEditingController();
  List<_Employee> _searchResults = [];
  bool _isSearching = false;

  _Employee? _selectedEmployee;
  ScoreClass? _selectedClass;
  final _scoreController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _isSubmitting = false;

  int _step = 0; // 0=选员工 1=选分类 2=填积分

  @override
  void dispose() {
    _searchController.dispose();
    _scoreController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _searchEmployee(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final api = ref.read(employeeScoreApiProvider);
      await api.getEmployeeByIdents([]);
      // fallback: use empty search - employee search is typically done via
      // a different endpoint; for now show placeholder
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _onEmployeeSelected(_Employee emp) {
    setState(() {
      _selectedEmployee = emp;
      _step = 1;
    });
  }

  void _onClassSelected(ScoreClass cls) {
    setState(() {
      _selectedClass = cls;
      _step = 2;
    });
  }

  Future<void> _submit() async {
    final score = int.tryParse(_scoreController.text);
    if (_selectedEmployee == null || _selectedClass == null || score == null || score <= 0) {
      _showError('请完整填写发放信息');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(employeeScoreApiProvider);
      final ok = await api.giveScore(
        employeeId: _selectedEmployee!.employeeId,
        score: score,
        classId: _selectedClass!.id,
        remark: _remarkController.text.isNotEmpty ? _remarkController.text : null,
      );
      if (ok) {
        _showSuccess('积分发放成功');
        context.pop();
      } else {
        _showError('发放失败，请重试');
      }
    } catch (e) {
      _showError('发放失败：$e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  void _showSuccess(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('成功'),
        content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('积分发放'),
        leading: _step > 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 进度指示器
            _StepIndicator(currentStep: _step),

            Expanded(
              child: _step == 0
                  ? _buildStep0Employee()
                  : _step == 1
                      ? _buildStep1Class()
                      : _buildStep2Score(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0Employee() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: '搜索员工姓名或手机号',
            onChanged: _searchEmployee,
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CupertinoActivityIndicator())
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_2, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('输入关键词搜索员工', style: AppText.caption),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) => _EmployeeTile(
                        employee: _searchResults[i],
                        onTap: () => _onEmployeeSelected(_searchResults[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStep1Class() {
    final classList = ref.watch(scoreClassListProvider);
    return classList.when(
      data: (classes) => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: classes.length,
        itemBuilder: (_, i) => _ClassTile(
          cls: classes[i],
          onTap: () => _onClassSelected(classes[i]),
        ),
      ),
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => Center(child: Text('加载失败', style: AppText.body)),
    );
  }

  Widget _buildStep2Score() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 员工信息卡片
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmployee!.name.substring(0, 1),
                      style: const TextStyle(
                        color: Color(0xFF0A84FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedEmployee!.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                    Text(_selectedClass!.name, style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 积分输入
          Text('发放积分', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.star_fill, color: Color(0xFFFF9500)),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoTextField(
                    controller: _scoreController,
                    placeholder: '请输入积分数量',
                    keyboardType: TextInputType.number,
                    decoration: const BoxDecoration(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('分', style: AppText.body),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 备注
          Text('备注（可选）', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: CupertinoTextField(
              controller: _remarkController,
              placeholder: '填写发放原因或备注',
              maxLines: 3,
              decoration: const BoxDecoration(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 提交按钮
          CupertinoButton.filled(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('确认发放'),
          ),
        ],
      ),
    );
  }
}

/// 进度指示器
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _StepDot(label: '选择员工', isActive: currentStep >= 0, isDone: currentStep > 0),
          Expanded(child: _StepLine(isActive: currentStep > 0)),
          _StepDot(label: '选择分类', isActive: currentStep >= 1, isDone: currentStep > 1),
          Expanded(child: _StepLine(isActive: currentStep > 1)),
          _StepDot(label: '填写积分', isActive: currentStep >= 2, isDone: currentStep > 2),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({required this.label, required this.isActive, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey4,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(CupertinoIcons.checkmark, color: CupertinoColors.white, size: 14)
                : Text('${label.substring(0, 1)}', style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF0A84FF) : AppColors.textTertiary)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isActive ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey4,
    );
  }
}

/// 员工项
class _EmployeeTile extends StatelessWidget {
  final _Employee employee;
  final VoidCallback onTap;

  const _EmployeeTile({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  employee.name.substring(0, 1),
                  style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  if (employee.departmentName != null)
                    Text(employee.departmentName!, style: AppText.caption),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 分类项
class _ClassTile extends StatelessWidget {
  final ScoreClass cls;
  final VoidCallback onTap;

  const _ClassTile({required this.cls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(CupertinoIcons.star, color: Color(0xFFFF9500)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  if (cls.maxScore != null)
                    Text('单次上限 ${cls.maxScore} 分', style: AppText.caption),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

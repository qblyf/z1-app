import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/return_visit_api.dart';
import '../../api/member_api.dart';
import '../../api/employee_api.dart';
import '../../models/return_visit.dart';
import '../../models/user.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 客户回访详情页
class ReturnVisitDetailPage extends ConsumerStatefulWidget {
  final String number;

  const ReturnVisitDetailPage({super.key, required this.number});

  @override
  ConsumerState<ReturnVisitDetailPage> createState() => _ReturnVisitDetailPageState();
}

class _ReturnVisitDetailPageState extends ConsumerState<ReturnVisitDetailPage> {
  ReturnVisit? _item;
  bool _isLoading = true;
  String? _error;
  String _customerName = '';
  String _employeeName = '';
  String _customerPhone = '';
  String _selectedMethod = 'phone';
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ReturnVisitApi();
      final item = await api.detail(widget.number);
      if (mounted) {
        setState(() {
          _item = item;
          _isLoading = false;
        });
        if (item != null) {
          _loadNames(item);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNames(ReturnVisit item) async {
    try {
      final memberApi = MemberApi();
      final employeeApi = EmployeeApi();
      final memberFuture = memberApi.getByIdent(item.customer);
      final employeeFuture = employeeApi.getByUserIdents([item.employee]);

      final results = await Future.wait([memberFuture, employeeFuture]);
      if (mounted) {
        setState(() {
          final member = results[0] as Member?;
          _customerName = member?.realName ?? '会员 #${item.customer}';
          _customerPhone = member?.mobilePhone ?? '';

          final employees = results[1] as List<Employee>;
          final employee = employees.isNotEmpty ? employees.first : null;
          _employeeName = employee?.name ?? '员工 #${item.employee}';
        });
      }
    } catch (e) {
      // 忽略名称加载错误
    }
  }

  Future<void> _submitRecord() async {
    if (_contentController.text.trim().isEmpty) {
      _showToast('请输入回访内容');
      return;
    }

    if (_item == null) return;

    setState(() => _isSubmitting = true);
    try {
      final api = ReturnVisitApi();
      // 如果状态是待回访，先改为进行中
      if (_item!.status == ReturnVisitStatus.todo) {
        await api.editStatus(id: _item!.id, status: 'doing');
      }
      final success = await api.addRecord(
        id: _item!.id,
        content: _contentController.text.trim(),
        method: _selectedMethod,
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _contentController.clear();
          _showToast('记录添加成功');
          _loadDetail();
        } else {
          _showToast('添加失败');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast('添加失败: $e');
      }
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('好的'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(String status) async {
    if (_item == null) return;
    setState(() => _isSubmitting = true);
    try {
      final api = ReturnVisitApi();
      final success = await api.editStatus(id: _item!.id, status: status);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _showToast('状态更新成功');
          _loadDetail();
        } else {
          _showToast('更新失败');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast('更新失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
        middle: const Text('回访详情'),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _error != null
              ? Center(child: Text('加载失败: $_error'))
              : _item == null
                  ? const Center(child: Text('未找到回访记录'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final item = _item!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息卡片
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.number, style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(item.status.colorValue).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item.status.label, style: TextStyle(fontSize: 12, color: Color(item.status.colorValue), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow('类型', item.type.label),
                  _InfoRow('关联订单', item.orderNumber),
                  _InfoRow('被回访人', _customerName.isNotEmpty ? '$_customerName ${_customerPhone.isNotEmpty ? _customerPhone : ""}' : '会员 #${item.customer}'),
                  _InfoRow('回访人', _employeeName.isNotEmpty ? _employeeName : '员工 #${item.employee}'),
                  _InfoRow('创建时间', item.formattedCreatedTime),
                  if (item.lastUpdatedAt > 0) _InfoRow('最后更新时间', item.formattedLastUpdatedTime),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 状态操作
            if (item.status != ReturnVisitStatus.success && item.status != ReturnVisitStatus.abort) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('状态操作', style: AppText.label),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        if (item.status == ReturnVisitStatus.todo || item.status == ReturnVisitStatus.doing)
                          _ActionBtn(label: '标记成功', color: const Color(0xFF30D158), onTap: () => _changeStatus('success')),
                        if (item.status == ReturnVisitStatus.doing)
                          _ActionBtn(label: '标记失败', color: const Color(0xFFFF3B30), onTap: () => _changeStatus('failed')),
                        if (item.status != ReturnVisitStatus.abort)
                          _ActionBtn(label: '中止回访', color: const Color(0xFF8E8E93), onTap: () => _changeStatus('abort')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 添加回访记录
            if (item.status != ReturnVisitStatus.success && item.status != ReturnVisitStatus.abort) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('添加回访记录', style: AppText.label),
                    const SizedBox(height: 12),
                    Text('回访方式', style: AppText.caption),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: ReturnVisitMethod.values.map((m) =>
                        GestureDetector(
                          onTap: () => setState(() => _selectedMethod = m.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedMethod == m.name ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedMethod == m.name ? CupertinoColors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _contentController,
                      placeholder: '请输入回访内容...',
                      maxLines: 4,
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: _isSubmitting ? null : _submitRecord,
                        child: _isSubmitting
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : const Text('提交记录'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 回访记录列表
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('回访记录', style: AppText.label),
                      const Spacer(),
                      Text('${item.record.length} 条', style: AppText.caption),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (item.record.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('暂无回访记录', style: AppText.caption),
                      ),
                    )
                  else
                    ...item.record.map((r) => _RecordItem(record: r)),
                ],
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

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption),
          ),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final ReturnVisitRecord record;

  const _RecordItem({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(record.method.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(record.method.label, style: TextStyle(fontSize: 11, color: Color(record.method.colorValue))),
              ),
              const Spacer(),
              Text(record.formattedTime, style: AppText.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(record.content, style: AppText.body),
        ],
      ),
    );
  }
}

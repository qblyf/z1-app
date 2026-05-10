import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/employee_score_providers.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';

/// 积分申报页面（员工提交申报）
class ApplyPage extends ConsumerStatefulWidget {
  const ApplyPage({super.key});

  @override
  ConsumerState<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends ConsumerState<ApplyPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ScoreClass? _selectedClass;
  DateTime _happenedAt = DateTime.now();

  // 申报明细
  final List<_ApplyItemEntry> _items = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addItem() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _AddItemSheet(
        onAdd: (entry) => setState(() => _items.add(entry)),
      ),
    );
  }

  Future<void> _selectDate() async {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _happenedAt,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (dt) => setState(() => _happenedAt = dt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) {
      _showError('请填写申报标题');
      return;
    }
    if (_selectedClass == null) {
      _showError('请选择积分分类');
      return;
    }
    if (_items.isEmpty) {
      _showError('请添加至少一项申报明细');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(employeeScoreApiProvider);
      final timestamp = (_happenedAt.millisecondsSinceEpoch / 1000).round();
      final id = await api.addApply(
        title: _titleController.text,
        classId: _selectedClass!.id,
        happenedAt: timestamp,
        description: _descController.text.isNotEmpty ? _descController.text : null,
        items: _items.map((e) => {
          'user': e.userId,
          'userName': e.userName,
          'score': e.score,
          if (e.remark != null) 'remark': e.remark,
        }).toList(),
      );
      if (id > 0) {
        _showSuccess('申报提交成功');
        if (mounted) Navigator.pop(context);
      } else {
        _showError('提交失败，请重试');
      }
    } catch (e) {
      _showError('提交失败：$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    final classList = ref.watch(scoreClassListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('积分申报'),
        trailing: _isSubmitting
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('提交', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _submit,
              ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              _SectionLabel('申报标题'),
              const SizedBox(height: 8),
              _CardWrapper(
                child: CupertinoTextField(
                  controller: _titleController,
                  placeholder: '简述本次申报内容',
                  decoration: const BoxDecoration(),
                  maxLines: 1,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 分类
              _SectionLabel('积分分类'),
              const SizedBox(height: 8),
              classList.when(
                data: (classes) => _CardWrapper(
                  child: GestureDetector(
                    onTap: () => _showClassPicker(classes),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.star_fill, color: Color(0xFFFF9500), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selectedClass?.name ?? '请选择分类',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedClass != null ? AppColors.textSecondary : AppColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                loading: () => _CardWrapper(child: Container(height: 44, alignment: Alignment.center, child: const CupertinoActivityIndicator())),
                error: (_, __) => _CardWrapper(child: Text('加载失败', style: AppText.caption)),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 发生时间
              _SectionLabel('发生时间'),
              const SizedBox(height: 8),
              _CardWrapper(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, color: Color(0xFF0A84FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_happenedAt.year}-${_happenedAt.month.toString().padLeft(2, '0')}-${_happenedAt.day.toString().padLeft(2, '0')}',
                          style: AppText.body,
                        ),
                        const Spacer(),
                        Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 描述
              _SectionLabel('事件描述（可选）'),
              const SizedBox(height: 8),
              _CardWrapper(
                child: CupertinoTextField(
                  controller: _descController,
                  placeholder: '详细描述申报事由',
                  decoration: const BoxDecoration(),
                  maxLines: 3,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 申报明细
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel('申报明细'),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _addItem,
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFF0A84FF), size: 18),
                        SizedBox(width: 4),
                        Text('添加成员', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_items.isEmpty)
                _CardWrapper(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.person_2, size: 32, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('点击上方"添加成员"添加申报明细', style: AppText.caption),
                      ],
                    ),
                  ),
                )
              else
                ..._items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CardWrapper(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  item.userName.substring(0, 1),
                                  style: const TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.userName, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                                  if (item.remark != null)
                                    Text(item.remark!, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Text(
                              '+${item.score}分',
                              style: const TextStyle(
                                color: Color(0xFFFF9500),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _items.removeAt(idx)),
                              child: const Icon(CupertinoIcons.minus_circle_fill, color: Color(0xFFFF3B30), size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: AppSpacing.xl),

              // 总计
              if (_items.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('本次申报合计：', style: TextStyle(color: Color(0xFFFF9500))),
                      Text(
                        '${_items.fold<int>(0, (sum, e) => sum + e.score)} 分',
                        style: const TextStyle(
                          color: Color(0xFFFF9500),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              CupertinoButton.filled(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('提交申报'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClassPicker(List<ScoreClass> classes) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(context)),
                CupertinoButton(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                onSelectedItemChanged: (i) => setState(() => _selectedClass = classes[i]),
                children: classes.map((c) => Center(child: Text(c.name))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.label);
  }
}

class _CardWrapper extends StatelessWidget {
  final Widget child;
  const _CardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// 申报明细条目
class _ApplyItemEntry {
  final int userId;
  final String userName;
  final int score;
  final String? remark;

  const _ApplyItemEntry({
    required this.userId,
    required this.userName,
    required this.score,
    this.remark,
  });
}

/// 添加成员 Sheet
class _AddItemSheet extends StatefulWidget {
  final ValueChanged<_ApplyItemEntry> onAdd;

  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameController = TextEditingController();
  final _scoreController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;
    final score = int.tryParse(_scoreController.text);
    if (score == null || score <= 0) return;
    widget.onAdd(_ApplyItemEntry(
      userId: _nameController.text.hashCode.abs(),
      userName: _nameController.text,
      score: score,
      remark: _remarkController.text.isNotEmpty ? _remarkController.text : null,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('添加成员', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CupertinoTextField(
            controller: _nameController,
            placeholder: '成员姓名',
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: AppSpacing.sm),
          CupertinoTextField(
            controller: _scoreController,
            placeholder: '积分数量',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: AppSpacing.sm),
          CupertinoTextField(
            controller: _remarkController,
            placeholder: '备注（可选）',
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: AppSpacing.md),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _submit,
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

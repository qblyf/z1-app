import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';

/// 业务类型数据
class BusinessType {
  final String name;
  final int typeValue;
  final String typeName;

  const BusinessType({
    required this.name,
    required this.typeValue,
    required this.typeName,
  });
}

/// 款项信息
class JournalEntry {
  final String key;
  final String payAccountName;
  final int amount;
  final String? remark;

  const JournalEntry({
    required this.key,
    required this.payAccountName,
    required this.amount,
    this.remark,
  });
}

final _businessTypesProvider = FutureProvider<List<BusinessType>>((ref) async {
  // 从后端获取业务类型列表
  // 这里使用模拟数据，实际应从 API 获取
  return [
    const BusinessType(name: '日常费用', typeValue: 1, typeName: '日常费用'),
    const BusinessType(name: '差旅费', typeValue: 2, typeName: '差旅费'),
    const BusinessType(name: '招待费', typeValue: 3, typeName: '招待费'),
    const BusinessType(name: '采购款', typeValue: 4, typeName: '采购款'),
    const BusinessType(name: '其他', typeValue: 99, typeName: '其他'),
  ];
});

class FinancialExpenseCreatePage extends ConsumerStatefulWidget {
  const FinancialExpenseCreatePage({super.key});

  @override
  ConsumerState<FinancialExpenseCreatePage> createState() =>
      _FinancialExpenseCreatePageState();
}

class _FinancialExpenseCreatePageState
    extends ConsumerState<FinancialExpenseCreatePage> {
  BusinessType? _selectedBusiness;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAdvance = false;
  final List<JournalEntry> _entries = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int get _totalAmount =>
      _entries.fold(0, (sum, e) => sum + e.amount);

  String get _amountDisplay {
    if (_amountController.text.isEmpty) return '¥0.00';
    final amount = double.tryParse(_amountController.text) ?? 0;
    return '¥${amount.toStringAsFixed(2)}';
  }

  Future<void> _submit() async {
    // 表单验证
    if (_selectedBusiness == null) {
      _showToast('请选择业务类型');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showToast('请输入申请标题');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showToast('请输入有效的申请金额');
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      _showToast('请输入申请内容');
      return;
    }
    if (_entries.isEmpty) {
      _showToast('请添加至少一项款项');
      return;
    }

    // 金额校验：手动输入的申请金额 = 添加的款项应付金额合计值
    final inputAmountFen = (amount * 100).round();
    if (inputAmountFen != _totalAmount) {
      _showToast('申请金额与添加款项金额不符，请检查！');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final client = ApiClient();
      await client.post('/financial-expenses/create', data: {
        'financialExpensesType': _selectedBusiness!.typeValue,
        'businessType': _selectedBusiness!.name,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'isAdvance': _isAdvance,
        'infos': _entries.map((e) => {
          'payAccountName': e.payAccountName,
          'amount': e.amount,
          if (e.remark != null) 'remark': e.remark,
        }).toList(),
      });

      if (mounted) {
        _showToast('提交成功');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showToast('提交失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showBusinessTypeSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _BusinessTypeSheet(
        onSelected: (bt) {
          setState(() => _selectedBusiness = bt);
        },
      ),
    );
  }

  void _showTitleInput() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _TextInputModal(
        title: '申请标题',
        controller: _titleController,
        placeholder: '请输入申请标题',
        maxLength: 50,
        rows: 2,
        onConfirm: () {
          setState(() {});
        },
      ),
    );
  }

  void _showAmountInput() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _AmountInputModal(
        controller: _amountController,
        onConfirm: () {
          setState(() {});
        },
      ),
    );
  }

  void _showContentInput() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _TextInputModal(
        title: '申请内容',
        controller: _contentController,
        placeholder: '请输入申请内容',
        maxLength: 500,
        rows: 4,
        onConfirm: () {
          setState(() {});
        },
      ),
    );
  }

  void _showAdvanceSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('是否预支'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _isAdvance = true);
              Navigator.pop(context);
            },
            child: const Text('是'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _isAdvance = false);
              Navigator.pop(context);
            },
            child: const Text('否'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _addEntry() {
    if (_selectedBusiness == null) {
      _showToast('请先选择业务类型');
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _AddEntrySheet(
        onAdd: (entry) {
          setState(() {
            _entries.add(entry);
          });
        },
      ),
    );
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 订阅业务类型列表，确保数据加载
    ref.watch(_businessTypesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('新建支出单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const CupertinoActivityIndicator()
              : const Text('提交'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 基础信息
                    _SectionHeader('基础信息'),
                    const SizedBox(height: AppSpacing.sm),
                    _FormCard(
                      children: [
                        _FormRow(
                          label: '业务类型',
                          value: _selectedBusiness?.name ?? '请选择',
                          valueColor: _selectedBusiness == null
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _entries.isEmpty ? _showBusinessTypeSheet : null,
                          showArrow: _entries.isEmpty,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '申请标题',
                          value: _titleController.text.isEmpty
                              ? '请输入'
                              : _titleController.text,
                          valueColor: _titleController.text.isEmpty
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showTitleInput,
                          showArrow: true,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '申请金额',
                          value: _amountController.text.isEmpty
                              ? '请输入'
                              : _amountDisplay,
                          valueColor: _amountController.text.isEmpty
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showAmountInput,
                          showArrow: true,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '申请内容',
                          value: _contentController.text.isEmpty
                              ? '请输入'
                              : _contentController.text,
                          valueColor: _contentController.text.isEmpty
                              ? CupertinoColors.placeholderText
                              : null,
                          onTap: _showContentInput,
                          showArrow: true,
                        ),
                        _Divider(),
                        _FormRow(
                          label: '是否预支',
                          value: _isAdvance ? '是' : '否',
                          onTap: _showAdvanceSheet,
                          showArrow: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 新增款项按钮
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                      onPressed: _addEntry,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.plus_circle_fill,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('新增款项',
                              style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),

                    if (_entries.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SectionHeader('款项内容'),
                      const SizedBox(height: AppSpacing.sm),
                      ...List.generate(_entries.length, (index) {
                        final entry = _entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _EntryCard(
                            entry: entry,
                            index: index + 1,
                            onDelete: () => _removeEntry(index),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // 底部金额栏
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('申请金额:',
                          style: AppText.caption.copyWith(
                              color: CupertinoColors.secondaryLabel)),
                      Text(
                        _amountDisplay,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CupertinoButton.filled(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    borderRadius: BorderRadius.circular(25),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white)
                        : const Text('提交'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppText.label.copyWith(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showArrow;

  const _FormRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: AppText.body),
            ),
            Expanded(
              child: Text(
                value,
                style: AppText.body.copyWith(
                  color: valueColor ??
                      CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.lg),
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final int index;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.payAccountName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '¥${(entry.amount / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.destructiveRed,
                  size: 18,
                ),
              ),
            ],
          ),
          if (entry.remark != null && entry.remark!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.remark!,
              style: AppText.caption.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 业务类型选择弹窗
class _BusinessTypeSheet extends ConsumerWidget {
  final void Function(BusinessType) onSelected;

  const _BusinessTypeSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessTypes = ref.watch(_businessTypesProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择业务类型',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  ),
                ],
              ),
            ),
            businessTypes.when(
              data: (list) => Column(
                children: list.map((bt) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onSelected(bt);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Text(bt.typeName,
                              style: AppText.body),
                          const Spacer(),
                          Text(bt.name,
                              style: AppText.caption.copyWith(
                                  color: CupertinoColors.secondaryLabel)),
                          const SizedBox(width: 8),
                          Icon(CupertinoIcons.chevron_right,
                              size: 14,
                              color:
                                  CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CupertinoActivityIndicator(),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('加载失败'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 文本输入弹窗
class _TextInputModal extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final String placeholder;
  final int maxLength;
  final int rows;
  final VoidCallback onConfirm;

  const _TextInputModal({
    required this.title,
    required this.controller,
    required this.placeholder,
    required this.maxLength,
    required this.rows,
    required this.onConfirm,
  });

  @override
  State<_TextInputModal> createState() => _TextInputModalState();
}

class _TextInputModalState extends State<_TextInputModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  Text(widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      widget.controller.text = _controller.text;
                      widget.onConfirm();
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: widget.placeholder,
                maxLines: widget.rows,
                maxLength: widget.maxLength,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 金额输入弹窗
class _AmountInputModal extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _AmountInputModal({
    required this.controller,
    required this.onConfirm,
  });

  @override
  State<_AmountInputModal> createState() => _AmountInputModalState();
}

class _AmountInputModalState extends State<_AmountInputModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text('申请金额',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      widget.controller.text = _controller.text;
                      widget.onConfirm();
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: '请输入金额（元）',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('¥', style: TextStyle(fontSize: 18)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加款项弹窗
class _AddEntrySheet extends StatefulWidget {
  final void Function(JournalEntry) onAdd;

  const _AddEntrySheet({required this.onAdd});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      _showToast('请输入付款账户');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showToast('请输入有效的付款金额');
      return;
    }

    final entry = JournalEntry(
      key: DateTime.now().millisecondsSinceEpoch.toString(),
      payAccountName: _nameController.text.trim(),
      amount: (amount * 100).round(),
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
    );
    widget.onAdd(entry);
    Navigator.pop(context);
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text('新增款项',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _submit,
                    child: const Text('添加'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('付款账户',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: '请输入付款账户名称',
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('付款金额',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: '请输入金额（元）',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('¥'),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('备注（可选）',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _remarkController,
                    placeholder: '请输入备注信息',
                    maxLines: 2,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(AppRadius.md),
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
}

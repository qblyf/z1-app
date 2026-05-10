import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/cashier_daily_report_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 收银日报创建页
class CashierDailyReportCreatePage extends ConsumerStatefulWidget {
  const CashierDailyReportCreatePage({super.key});

  @override
  ConsumerState<CashierDailyReportCreatePage> createState() =>
      _CashierDailyReportCreatePageState();
}

class _CashierDailyReportCreatePageState
    extends ConsumerState<CashierDailyReportCreatePage> {
  DateTime _selectedDate = DateTime.now();
  final _remarkController = TextEditingController();

  // POS进账
  final List<_PosEntry> _posEntries = [];

  // 其他收入
  final List<_OtherIncomeEntry> _otherEntries = [];

  // 银行存款
  final List<_BankEntry> _bankEntries = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  int get _totalIncome {
    int pos = _posEntries.fold(0, (sum, e) => sum + (e.amount * 100).round());
    int other = _otherEntries.fold(0, (sum, e) => sum + (e.amount * 100).round());
    int bank = _bankEntries.fold(0, (sum, e) => sum + (e.amount * 100).round());
    return pos + other + bank;
  }

  Future<void> _submit() async {
    if (_posEntries.isEmpty && _otherEntries.isEmpty && _bankEntries.isEmpty) {
      _showMsg('请至少填写一项收入');
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('确认提交'),
        content: const Text('确认提交此收银日报表？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text('确认'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final api = CashierDailyReportApi();
      final date =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final posIncome = _posEntries
          .map((e) => {
                'posClientID': e.posId,
                'amount': (e.amount * 100).round(),
                'images': <String>[],
              })
          .toList();

      final otherIncome = _otherEntries
          .map((e) => {
                'paymentTypeID': e.paymentTypeId,
                'amount': (e.amount * 100).round(),
                'remarks': e.remarks ?? '',
                'images': <String>[],
              })
          .toList();

      final bankAccountIncome = _bankEntries
          .map((e) => {
                'bankAccountID': e.bankAccountId,
                'amount': (e.amount * 100).round(),
                'images': <String>[],
                'remarks': e.remarks ?? '',
              })
          .toList();

      final id = await api.add(
        date: date,
        posIncome: posIncome,
        otherIncome: otherIncome,
        bankAccountIncome: bankAccountIncome.isNotEmpty ? bankAccountIncome : null,
        remarks: _remarkController.text.isNotEmpty ? _remarkController.text : null,
      );

      if (id > 0) {
        _showMsg('提交成功');
        if (mounted) context.pop();
      } else {
        _showMsg('提交失败，请重试');
      }
    } catch (e) {
      _showMsg('提交失败：$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMsg(String msg) {
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

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                    child: const Text('确定'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (dt) => setState(() => _selectedDate = dt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addPosEntry() {
    _showEntrySheet(
      title: '添加POS进账',
      fields: [
        ('POS终端ID', TextInputType.number, (v) {}),
        ('金额（元）', TextInputType.number, (v) {}),
      ],
      onSubmit: (values) {
        final posId = int.tryParse(values[0]);
        final amount = double.tryParse(values[1]);
        if (posId == null || amount == null || amount <= 0) return;
        setState(() => _posEntries.add(_PosEntry(posId, amount)));
      },
    );
  }

  void _addOtherEntry() {
    _showEntrySheet(
      title: '添加其他收入',
      fields: [
        ('支付方式ID', TextInputType.number, (v) {}),
        ('金额（元）', TextInputType.number, (v) {}),
        ('备注（可选）', TextInputType.text, (v) {}),
      ],
      onSubmit: (values) {
        final typeId = int.tryParse(values[0]);
        final amount = double.tryParse(values[1]);
        if (typeId == null || amount == null || amount <= 0) return;
        setState(() => _otherEntries.add(_OtherIncomeEntry(typeId, amount, values.length > 2 ? values[2] : null)));
      },
    );
  }

  void _addBankEntry() {
    _showEntrySheet(
      title: '添加银行存款',
      fields: [
        ('银行账户ID', TextInputType.number, (v) {}),
        ('金额（元）', TextInputType.number, (v) {}),
        ('备注（可选）', TextInputType.text, (v) {}),
      ],
      onSubmit: (values) {
        final bankId = int.tryParse(values[0]);
        final amount = double.tryParse(values[1]);
        if (bankId == null || amount == null || amount <= 0) return;
        setState(() => _bankEntries.add(_BankEntry(bankId, amount, values.length > 2 ? values[2] : null)));
      },
    );
  }

  void _showEntrySheet({
    required String title,
    required List<(String, TextInputType, ValueChanged<String>)> fields,
    required void Function(List<String>) onSubmit,
  }) {
    final controllers = fields.map((f) => TextEditingController()).toList();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
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
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(CupertinoIcons.xmark_circle_fill,
                      color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...fields.asMap().entries.map((entry) {
              final idx = entry.key;
              final label = entry.value.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: CupertinoTextField(
                  controller: controllers[idx],
                  placeholder: label,
                  keyboardType: fields[idx].$2,
                  padding: const EdgeInsets.all(12),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                onSubmit(controllers.map((c) => c.text.trim()).toList());
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
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
        middle: const Text('创建收银日报'),
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
              // 日期选择
              _SectionLabel('收银日期'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar,
                          color: Color(0xFF0A84FF)),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: AppText.body,
                      ),
                      const Spacer(),
                      Icon(CupertinoIcons.chevron_right,
                          color: AppColors.textTertiary, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // POS进账
              _SectionLabelRow(
                label: 'POS进账',
                onAdd: _addPosEntry,
              ),
              const SizedBox(height: 8),
              if (_posEntries.isEmpty)
                _EmptyHint(text: '暂无POS进账记录，点击上方"+"添加')
              else
                ..._posEntries.asMap().entries.map((e) => _EntryCard(
                      index: e.key,
                      title: 'POS终端 ${e.value.posId}',
                      amount: '¥${e.value.amount.toStringAsFixed(2)}',
                      color: const Color(0xFF0A84FF),
                      onRemove: () =>
                          setState(() => _posEntries.removeAt(e.key)),
                    )),

              const SizedBox(height: AppSpacing.lg),

              // 银行存款
              _SectionLabelRow(
                label: '银行存款',
                onAdd: _addBankEntry,
              ),
              const SizedBox(height: 8),
              if (_bankEntries.isEmpty)
                _EmptyHint(text: '暂无银行存款记录，点击上方"+"添加')
              else
                ..._bankEntries.asMap().entries.map((e) => _EntryCard(
                      index: e.key,
                      title: '银行账户 ${e.value.bankAccountId}',
                      amount: '¥${e.value.amount.toStringAsFixed(2)}',
                      color: const Color(0xFF30D158),
                      onRemove: () =>
                          setState(() => _bankEntries.removeAt(e.key)),
                    )),

              const SizedBox(height: AppSpacing.lg),

              // 其他收入
              _SectionLabelRow(
                label: '其他收入',
                onAdd: _addOtherEntry,
              ),
              const SizedBox(height: 8),
              if (_otherEntries.isEmpty)
                _EmptyHint(text: '暂无其他收入记录，点击上方"+"添加')
              else
                ..._otherEntries.asMap().entries.map((e) => _EntryCard(
                      index: e.key,
                      title: '支付方式 ${e.value.paymentTypeId}${e.value.remarks != null ? ' · ${e.value.remarks}' : ''}',
                      amount: '¥${e.value.amount.toStringAsFixed(2)}',
                      color: const Color(0xFFFF9500),
                      onRemove: () =>
                          setState(() => _otherEntries.removeAt(e.key)),
                    )),

              const SizedBox(height: AppSpacing.lg),

              // 备注
              _SectionLabel('备注（可选）'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: CupertinoTextField(
                  controller: _remarkController,
                  placeholder: '填写备注信息',
                  maxLines: 3,
                  decoration: const BoxDecoration(),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 总计
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0A84FF).withValues(alpha: 0.1),
                      const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Text('本次收入合计',
                        style: TextStyle(color: Color(0xFF0A84FF))),
                    const SizedBox(height: 4),
                    Text(
                      '¥${(_totalIncome / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF0A84FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              CupertinoButton.filled(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white)
                    : const Text('提交日报表'),
              ),
            ],
          ),
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

class _SectionLabelRow extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;

  const _SectionLabelRow({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.label),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onAdd,
          child: const Row(
            children: [
              Icon(CupertinoIcons.plus_circle_fill,
                  color: Color(0xFF0A84FF), size: 18),
              SizedBox(width: 4),
              Text('添加',
                  style: TextStyle(color: Color(0xFF0A84FF), fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.doc, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(text, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final int index;
  final String title;
  final String amount;
  final Color color;
  final VoidCallback onRemove;

  const _EntryCard({
    required this.index,
    required this.title,
    required this.amount,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppText.body)),
          Text(amount,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(CupertinoIcons.minus_circle_fill,
                color: Color(0xFFFF3B30), size: 22),
          ),
        ],
      ),
    );
  }
}

class _PosEntry {
  final int posId;
  final double amount;

  _PosEntry(this.posId, this.amount);
}

class _OtherIncomeEntry {
  final int paymentTypeId;
  final double amount;
  final String? remarks;

  _OtherIncomeEntry(this.paymentTypeId, this.amount, this.remarks);
}

class _BankEntry {
  final int bankAccountId;
  final double amount;
  final String? remarks;

  _BankEntry(this.bankAccountId, this.amount, this.remarks);
}

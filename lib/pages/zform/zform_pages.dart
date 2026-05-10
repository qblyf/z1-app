import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/zform_api.dart';
import '../../models/zform.dart';
import '../../theme/app_theme.dart';

/// 动态表单页 Provider
final zFormDetailProvider =
    FutureProvider.family<ZForm, int>((ref, tableId) async {
  return ZFormApi().getFormDetail(tableId);
});

/// 已提交记录列表 Provider
final zFormSubmittedListProvider =
    FutureProvider.family<List<ZFormRecord>, int>((ref, tableId) async {
  return ZFormApi().getSubmittedRecords(tableId);
});

/// ════════════════════════════════════════════════════════════════════════
/// 已提交表单列表页
/// ════════════════════════════════════════════════════════════════════════
class ZFormSubmittedListPage extends ConsumerWidget {
  final int tableId;

  const ZFormSubmittedListPage({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(zFormSubmittedListProvider(tableId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('我的提交记录'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.push('/zform/edit/$tableId'),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey3),
                    const SizedBox(height: 12),
                    const Text('暂无提交记录', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () => context.push('/zform/edit/$tableId'),
                      child: const Text('新建表单'),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = records[index];
                return GestureDetector(
                  onTap: () => context.push('/zform/edit/$tableId?recordId=${record.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              record.tableName ?? '表单记录 #${record.id}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _formatDate(record.createdAt),
                              style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                            ),
                          ],
                        ),
                        if (record.fields.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            record.fields
                                .where((f) => f.value != null && f.value!.isNotEmpty)
                                .take(3)
                                .map((f) => f.value)
                                .join(' | '),
                            style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.destructiveRed)),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => ref.invalidate(zFormSubmittedListProvider(tableId)),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(int? unix) {
    if (unix == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// ════════════════════════════════════════════════════════════════════════
/// 动态表单填写/编辑页
/// ════════════════════════════════════════════════════════════════════════
class ZFormEditPage extends ConsumerStatefulWidget {
  final int tableId;
  final int? recordId;

  const ZFormEditPage({super.key, required this.tableId, this.recordId});

  @override
  ConsumerState<ZFormEditPage> createState() => _ZFormEditPageState();
}

class _ZFormEditPageState extends ConsumerState<ZFormEditPage> {
  final ZFormApi _api = ZFormApi();
  final Map<int, dynamic> _fieldValues = {}; // columnId -> value
  bool _isLoading = true;
  bool _isSaving = false;
  ZForm? _form;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final form = await _api.getFormDetail(widget.tableId);
      _form = form;

      // 如果是编辑模式，加载已有数据
      if (widget.recordId != null) {
        final record = await _api.getRecordDetail(widget.recordId!);
        if (record != null) {
          for (final f in record.fields) {
            if (f.columnId != null) {
              _fieldValues[f.columnId!] = f.value ?? f.values;
            }
          }
        }
      } else {
        // 新建模式：用默认值初始化
        for (final col in form.columns) {
          if (col.defaultValue != null) {
            _fieldValues[col.id] = col.defaultValue;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 构建 fields 参数
      final fields = _fieldValues.entries.map((e) {
        final value = e.value;
        if (value is List) {
          return {'columnID': e.key, 'values': value};
        }
        return {'columnID': e.key, 'value': value?.toString() ?? ''};
      }).toList();

      bool success;
      if (widget.recordId != null) {
        success = await _api.editRecord(widget.recordId!, fields);
      } else {
        success = await _api.addRecord(widget.tableId, fields);
      }

      if (!mounted) return;
      if (success) {
        _showToast(widget.recordId != null ? '保存成功' : '提交成功');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.pop();
      } else {
        _showToast('操作失败，请重试');
      }
    } catch (e) {
      if (mounted) _showToast('操作失败：$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    final formAsync = ref.watch(zFormDetailProvider(widget.tableId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.recordId != null ? '编辑表单' : '新建表单'),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: const Text('保存', style: TextStyle(fontSize: 16)),
              ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? Center(child: _buildError(_error!))
                : formAsync.when(
                    data: (form) => _buildForm(form),
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (e, _) => Center(child: _buildError(e.toString())),
                  ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemGrey),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: _loadData,
          child: const Text('重试'),
        ),
      ],
    );
  }

  Widget _buildForm(ZForm form) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 表单名称
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.doc_text_fill, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(form.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    if (form.desc != null)
                      Text(form.desc!, style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 字段列表
        ...form.columns.map((col) => _buildField(col)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildField(ZFormColumn col) {
    final type = col.fieldTypeInfo;
    final currentValue = _fieldValues[col.id];
    final isRequired = col.isRequired ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(col.name ?? col.field ?? '字段', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              if (isRequired) const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          _buildFieldInput(col, type, currentValue, isRequired),
        ],
      ),
    );
  }

  Widget _buildFieldInput(ZFormColumn col, ZFormFieldType type, dynamic value, bool isRequired) {
    switch (type) {
      case ZFormFieldType.singleLineText:
      case ZFormFieldType.integer:
      case ZFormFieldType.decimal:
      case ZFormFieldType.amount:
        return CupertinoTextField(
          placeholder: col.placeholder ?? '请输入',
          controller: TextEditingController(text: value?.toString() ?? ''),
          keyboardType: type == ZFormFieldType.integer
              ? TextInputType.number
              : (type == ZFormFieldType.decimal || type == ZFormFieldType.amount)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          onChanged: (v) => _fieldValues[col.id] = v,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
        );

      case ZFormFieldType.multipleLinesText:
        return CupertinoTextField(
          placeholder: col.placeholder ?? '请输入',
          controller: TextEditingController(text: value?.toString() ?? ''),
          maxLines: 3,
          onChanged: (v) => _fieldValues[col.id] = v,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
        );

      case ZFormFieldType.date:
      case ZFormFieldType.dateTime:
        return _DateTimeField(
          value: value?.toString(),
          mode: type == ZFormFieldType.date ? CupertinoDatePickerMode.date : CupertinoDatePickerMode.dateAndTime,
          onChanged: (v) => _fieldValues[col.id] = v,
          placeholder: col.placeholder ?? '请选择',
        );

      case ZFormFieldType.singleChoice:
      case ZFormFieldType.spuSingleChoice:
      case ZFormFieldType.skuSingleChoice:
      case ZFormFieldType.cateSingleChoice:
      case ZFormFieldType.deptSingleChoice:
      case ZFormFieldType.emplSingleChoice:
        return _SingleChoiceField(
          value: value?.toString(),
          options: col.options,
          onChanged: (v) => _fieldValues[col.id] = v,
          placeholder: col.placeholder ?? '请选择',
        );

      case ZFormFieldType.multipleChoices:
      case ZFormFieldType.spuMultipleChoices:
      case ZFormFieldType.skuMultipleChoices:
      case ZFormFieldType.cateMultipleChoices:
      case ZFormFieldType.deptMultipleChoices:
      case ZFormFieldType.emplMultipleChoices:
      case ZFormFieldType.vendorMultipleChoices:
        return _MultipleChoiceField(
          values: (value as List?)?.cast<String>() ?? [],
          options: col.options,
          onChanged: (v) => _fieldValues[col.id] = v,
        );

      case ZFormFieldType.attachments:
        return _AttachmentField(
          values: (value as List?)?.cast<String>() ?? [],
          onChanged: (v) => _fieldValues[col.id] = v,
        );

      default:
        return CupertinoTextField(
          placeholder: '不支持的字段类型: ${type.value}',
          controller: TextEditingController(text: value?.toString() ?? ''),
          onChanged: (v) => _fieldValues[col.id] = v,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// 字段组件
// ════════════════════════════════════════════════════════════════════════

/// 日期时间选择
class _DateTimeField extends StatelessWidget {
  final String? value;
  final CupertinoDatePickerMode mode;
  final ValueChanged<String> onChanged;
  final String placeholder;

  const _DateTimeField({
    this.value,
    required this.mode,
    required this.onChanged,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? initial;
    if (value != null && value!.isNotEmpty) {
      try {
        initial = DateTime.parse(value!);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? placeholder,
              style: TextStyle(
                color: value == null ? CupertinoColors.placeholderText : CupertinoColors.label,
              ),
            ),
            const Icon(CupertinoIcons.calendar, size: 18, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    DateTime initial = this.initial ?? DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(child: const Text('确定'), onPressed: () {
                  onChanged(initial.toIso8601String().substring(0, 19));
                  Navigator.pop(ctx);
                }),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: mode,
                initialDateTime: initial,
                onDateTimeChanged: (dt) => initial = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单选字段
class _SingleChoiceField extends StatelessWidget {
  final String? value;
  final List<Map<String, dynamic>>? options;
  final ValueChanged<String?> onChanged;
  final String placeholder;

  const _SingleChoiceField({
    this.value,
    this.options,
    required this.onChanged,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? placeholder,
              style: TextStyle(
                color: value == null ? CupertinoColors.placeholderText : CupertinoColors.label,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 18, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final opts = options ?? [];
    int initIdx = 0;
    if (value != null) {
      final idx = opts.indexWhere((e) => e['value']?.toString() == value);
      if (idx >= 0) initIdx = idx;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(child: const Text('确定'), onPressed: () {
                  if (opts.isNotEmpty) {
                    onChanged(opts[initIdx]['value']?.toString());
                  }
                  Navigator.pop(ctx);
                }),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(initialItem: initIdx),
                onSelectedItemChanged: (idx) => initIdx = idx,
                children: opts.map((e) => Center(
                  child: Text(e['label']?.toString() ?? e['value']?.toString() ?? ''),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 多选字段
class _MultipleChoiceField extends StatefulWidget {
  final List<String> values;
  final List<Map<String, dynamic>>? options;
  final ValueChanged<List<String>> onChanged;

  const _MultipleChoiceField({
    required this.values,
    this.options,
    required this.onChanged,
  });

  @override
  State<_MultipleChoiceField> createState() => _MultipleChoiceFieldState();
}

class _MultipleChoiceFieldState extends State<_MultipleChoiceField> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.values);
  }

  @override
  Widget build(BuildContext context) {
    final opts = widget.options ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((e) {
        final v = e['value']?.toString() ?? '';
        final isSelected = _selected.contains(v);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(v);
              } else {
                _selected.add(v);
              }
            });
            widget.onChanged(_selected);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withOpacity(0.15) : CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: AppColors.accent) : null,
            ),
            child: Text(
              e['label']?.toString() ?? v,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.accent : CupertinoColors.label,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 附件字段
class _AttachmentField extends StatelessWidget {
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  const _AttachmentField({
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // TODO: 接入 image_picker 实现文件上传
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoActionSheet(
                title: const Text('添加附件'),
                actions: [
                  CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('拍照'),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('相册'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.plus_circle, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  '添加附件（${values.length}）',
                  style: const TextStyle(fontSize: 14, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...values.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.paperclip, size: 14, color: CupertinoColors.secondaryLabel),
                const SizedBox(width: 6),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () {
                    final updated = List<String>.from(values);
                    updated.removeAt(e.key);
                    onChanged(updated);
                  },
                  child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: CupertinoColors.destructiveRed),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

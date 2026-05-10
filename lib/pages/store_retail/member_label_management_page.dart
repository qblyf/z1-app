import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/label_api.dart';
import '../../models/label.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 会员标签管理页
/// 显示指定会员的标签列表，支持添加/移除标签，自定义新建标签
class MemberLabelManagementPage extends ConsumerStatefulWidget {
  final int memberIdent;
  final String memberName;

  const MemberLabelManagementPage({
    super.key,
    required this.memberIdent,
    required this.memberName,
  });

  @override
  ConsumerState<MemberLabelManagementPage> createState() =>
      _MemberLabelManagementPageState();
}

class _MemberLabelManagementPageState
    extends ConsumerState<MemberLabelManagementPage> {
  List<Label> _labels = [];
  bool _isLoading = true;
  bool _isOperating = false; // 添加/删除操作中

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    setState(() => _isLoading = true);
    try {
      final api = LabelApi();
      // 查询所有会员标签（type=member），并包含当前会员的关联
      final labels = await api.listByCondition(
        type: LabelType.member,
        state: LabelState.normal,
        limit: 10000,
      );
      // 按创建时间排序（时间早的在前）
      labels.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (mounted) {
        setState(() {
          _labels = labels;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 切换标签关联状态
  Future<void> _toggleLabel(Label label) async {
    if (_isOperating) return;
    setState(() => _isOperating = true);

    try {
      final api = LabelApi();
      final isAssociated = label.isAssociated(widget.memberIdent);

      bool success;
      if (isAssociated) {
        // 移除关联
        final count = await api.deleteItem(
          labelID: label.id,
          labelItemIDs: [widget.memberIdent],
        );
        success = count > 0;
      } else {
        // 添加关联
        success = await api.addItem(
          labelID: label.id,
          labelItemIDs: [widget.memberIdent],
        );
      }

      if (success) {
        // 更新本地状态
        if (mounted) {
          setState(() {
            final index = _labels.indexWhere((l) => l.id == label.id);
            if (index != -1) {
              final currentLabel = _labels[index];
              final newItems = isAssociated
                  ? currentLabel.items
                      .where((i) => i != widget.memberIdent)
                      .toList()
                  : [...currentLabel.items, widget.memberIdent];
              _labels[index] = Label(
                id: currentLabel.id,
                name: currentLabel.name,
                type: currentLabel.type,
                color: currentLabel.color,
                order: currentLabel.order,
                createdAt: currentLabel.createdAt,
                state: currentLabel.state,
                items: newItems,
              );
            }
          });
        }
      }
    } catch (_) {
      // 操作失败，不做处理
    } finally {
      if (mounted) {
        setState(() => _isOperating = false);
      }
    }
  }

  /// 显示新建标签弹框
  void _showAddLabelSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _AddLabelSheet(
        onAdded: () => _loadLabels(),
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
        middle: const Text('会员标签'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddLabelSheet,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 会员信息头部
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: Color(0xFF0A84FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberName.isNotEmpty
                              ? widget.memberName
                              : '会员',
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${widget.memberIdent}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '共 ${_labels.length} 个标签',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 标签列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _labels.isEmpty
                      ? _buildEmptyState()
                      : _buildLabelList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.tag,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('暂无标签', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _showAddLabelSheet,
            child: const Text('新建标签'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('点击标签切换关联状态', style: AppText.caption),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._labels.map((label) => _LabelChip(
                    label: label,
                    isSelected: label.isAssociated(widget.memberIdent),
                    onTap: _isOperating ? null : () => _toggleLabel(label),
                  )),
              // 新建标签按钮
              _AddLabelChip(onTap: _showAddLabelSheet),
            ],
          ),
        ],
      ),
    );
  }
}

/// 标签 Chip
class _LabelChip extends StatelessWidget {
  final Label label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LabelChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color chipBgColor;
    Color chipTextColor;

    if (isSelected) {
      chipBgColor = const Color(0xFFEAF3FF);
      chipTextColor = const Color(0xFF2A94F4);
    } else {
      chipBgColor = const Color(0xFFF2F2F2);
      chipTextColor = const Color(0xFF9FA2A5);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 14,
                  color: chipTextColor,
                ),
              ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? chipTextColor : const Color(0xFF7B3763),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: chipTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加标签按钮 Chip
class _AddLabelChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddLabelChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.plus,
              size: 14,
              color: const Color(0xFF9FA2A5),
            ),
            const SizedBox(width: 4),
            const Text(
              '自定义',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9FA2A5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 新建标签弹框
class _AddLabelSheet extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddLabelSheet({required this.onAdded});

  @override
  State<_AddLabelSheet> createState() => _AddLabelSheetState();
}

class _AddLabelSheetState extends State<_AddLabelSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String _textValue = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _textValue = _controller.text.trim();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _textValue;
    if (name.isEmpty) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final api = LabelApi();
      final success = await api.add(
        name: name,
        type: LabelType.member,
        color: '#7B3763',
        order: 1,
        state: LabelState.normal,
      );
      if (success && mounted) {
        widget.onAdded();
        Navigator.pop(context);
      }
    } catch (_) {
      // 失败不做处理
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '自定义添加',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CupertinoTextField(
            controller: _controller,
            placeholder: '请输入自定义标签名称',
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            maxLength: 20,
          ),
          const SizedBox(height: 120),
          CupertinoButton(
            color: const Color(0xFF0A84FF),
            borderRadius: BorderRadius.circular(20),
            onPressed: _textValue.isEmpty ? null : _handleSubmit,
            child: _isSubmitting
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('确认'),
          ),
        ],
      ),
    );
  }
}

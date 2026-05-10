import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/display_case_api.dart';
import '../../api/display_standard_api.dart';
import '../../models/display_case.dart';
import '../../models/display_standard.dart';
import '../../theme/app_theme.dart';

/// 展位操作页（新增/编辑）
class BoothOperatePage extends ConsumerStatefulWidget {
  /// null = 新增, int = 编辑
  final int? caseId;

  const BoothOperatePage({super.key, this.caseId});

  @override
  ConsumerState<BoothOperatePage> createState() => _BoothOperatePageState();
}

class _BoothOperatePageState extends ConsumerState<BoothOperatePage> {
  final DisplayCaseApi _api = DisplayCaseApi();
  final DisplayStandardApi _standardApi = DisplayStandardApi();

  DisplayCase? _caseInfo;
  DisplayStandard? _selectedStandard;
  List<String> _images = [];
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEdit => widget.caseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _api.detail(widget.caseId!);
      if (detail != null && mounted) {
        _caseInfo = detail;
        _remarksController.text = detail.remarks ?? '';
        _images = detail.imgs?.toList() ?? [];
        // 加载标准信息
        final standard = await _standardApi.detail(detail.standardID);
        if (mounted) {
          setState(() {
            _selectedStandard = standard;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedStandard == null) {
      _showError('请选择展位标准');
      return;
    }
    if (_images.isEmpty) {
      _showError('请上传当前陈列图片');
      return;
    }

    setState(() => _isSaving = true);
    try {
      bool success;
      if (_isEdit) {
        success = await _api.edit(
          id: widget.caseId!,
          standardID: _selectedStandard!.standardID,
          imgs: _images,
          remarks: _remarksController.text,
        );
      } else {
        success = await _api.add(
          name: _selectedStandard!.name,
          departmentID: _caseInfo?.departmentID ?? 0,
          standardID: _selectedStandard!.standardID,
          imgs: _images,
          remarks: _remarksController.text,
        );
      }

      if (success && mounted) {
        context.pop();
      } else if (mounted) {
        _showError(_isEdit ? '更新失败' : '创建失败');
        setState(() => _isSaving = false);
      }
    } catch (_) {
      if (mounted) {
        _showError(_isEdit ? '更新失败' : '创建失败');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStandard() async {
    final result = await showCupertinoModalPopup<DisplayStandard>(
      context: context,
      builder: (context) => _StandardSelectSheet(
        selectedId: _selectedStandard?.standardID,
      ),
    );
    if (result != null) {
      setState(() => _selectedStandard = result);
    }
  }

  void _addImageUrl() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('添加图片URL'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '请输入图片URL',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                setState(() => _images.add(url));
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEdit ? '编辑展位' : '添加展位'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : const Text(
                  '保存',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 展位选择
                    _SectionCard(
                      title: '${_isEdit ? '编辑' : '添加'}展位信息',
                      children: [
                        _SelectRow(
                          label: '展位',
                          value: _selectedStandard?.name,
                          placeholder: '请选择展位',
                          isRequired: true,
                          onTap: _selectStandard,
                        ),
                        _Divider(),
                        // 标准展陈图片
                        _StandardImagesSection(standard: _selectedStandard),
                        _Divider(),
                        // 当前陈列
                        _CurrentImagesSection(
                          images: _images,
                          onAdd: _addImageUrl,
                          onRemove: _removeImage,
                        ),
                        _Divider(),
                        // 备注
                        _RemarksSection(controller: _remarksController),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppText.body.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C1E),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    color: AppColors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool isRequired;
  final VoidCallback onTap;

  const _SelectRow({
    required this.label,
    this.value,
    required this.placeholder,
    this.isRequired = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Text(label, style: AppText.body),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: const Color(0xFFFF3B30)),
              ),
            const Spacer(),
            Text(
              value ?? placeholder,
              style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? const Color(0xFF636366)
                    : const Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandardImagesSection extends StatelessWidget {
  final DisplayStandard? standard;

  const _StandardImagesSection({this.standard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('标准展陈', style: AppText.body),
              const SizedBox(width: 4),
              Text(
                '(仅供参考)',
                style: AppText.caption.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (standard?.hasImages == true)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: standard!.imgs!.map((url) => _buildThumb(url)).toList(),
            )
          else
            Text(
              '无标准图片',
              style: AppText.caption.copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _buildThumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: const Color(0xFFF2F2F7),
          child: const Icon(
            CupertinoIcons.photo,
            size: 20,
            color: Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

class _CurrentImagesSection extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _CurrentImagesSection({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('当前陈列', style: AppText.body),
              const SizedBox(width: 4),
              Text(
                ' *',
                style: TextStyle(color: const Color(0xFFFF3B30)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (images.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < images.length; i++)
                  _ImageWithDelete(
                    url: images[i],
                    onDelete: () => onRemove(i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.plus,
                    size: 20,
                    color: Color(0xFF8E8E93),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '添加',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageWithDelete extends StatelessWidget {
  final String url;
  final VoidCallback onDelete;

  const _ImageWithDelete({required this.url, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            url,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 60,
              color: const Color(0xFFF2F2F7),
              child: const Icon(
                CupertinoIcons.photo,
                size: 20,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 10,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RemarksSection extends StatelessWidget {
  final TextEditingController controller;

  const _RemarksSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('备注', style: AppText.body),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: '请输入备注',
            maxLines: 4,
            minLines: 2,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 展陈标准选择底部弹窗
class _StandardSelectSheet extends ConsumerStatefulWidget {
  final int? selectedId;

  const _StandardSelectSheet({this.selectedId});

  @override
  ConsumerState<_StandardSelectSheet> createState() =>
      _StandardSelectSheetState();
}

class _StandardSelectSheetState extends ConsumerState<_StandardSelectSheet> {
  final DisplayStandardApi _api = DisplayStandardApi();
  List<DisplayStandard> _standards = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadStandards();
  }

  Future<void> _loadStandards() async {
    setState(() => _isLoading = true);
    try {
      final standards = await _api.list(
        type: 'board',
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _standards = standards;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DisplayStandard> get _filteredStandards {
    if (_searchText.isEmpty) return _standards;
    return _standards
        .where((s) => s.name.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5EA)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '选择展位',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '关闭',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(12),
            child: CupertinoSearchTextField(
              placeholder: '搜索展位名称',
              onChanged: (value) {
                setState(() => _searchText = value);
              },
            ),
          ),
          // 列表
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredStandards.isEmpty
                    ? Center(
                        child: Text(
                          '暂无展位标准',
                          style: AppText.caption,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStandards.length,
                        itemBuilder: (context, index) {
                          final standard = _filteredStandards[index];
                          final isSelected =
                              standard.standardID == widget.selectedId;
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, standard),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE8F4FF)
                                    : CupertinoColors.white,
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFE5E5EA),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      standard.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF007AFF)
                                            : const Color(0xFF1C1C1E),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      CupertinoIcons.checkmark,
                                      size: 18,
                                      color: Color(0xFF007AFF),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

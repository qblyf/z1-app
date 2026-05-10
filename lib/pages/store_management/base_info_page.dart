import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 门店基础信息页
/// 对应 PWA /pages/path-d/store-management/base-info.tsx
class StoreBaseInfoPage extends ConsumerStatefulWidget {
  const StoreBaseInfoPage({super.key});

  @override
  ConsumerState<StoreBaseInfoPage> createState() => _StoreBaseInfoPageState();
}

class _StoreBaseInfoPageState extends ConsumerState<StoreBaseInfoPage> {
  final StoreApi _api = StoreApi();

  StoreInfo? _storeInfo;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAddMode = false;

  // 表单数据
  String _storeName = '';
  String _manager = '';
  String _telephone = '';
  String _longitude = '';
  String _latitude = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      final deptId = user?.deptId ?? 0;

      if (deptId == 0) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final info = await _api.detail(departmentIDs: [deptId]);
      if (mounted) {
        setState(() {
          _storeInfo = info;
          if (info != null) {
            _isAddMode = false;
            _storeName = info.name ?? '';
            _manager = info.manager ?? '';
            _telephone = info.telephone ?? '';
            _longitude = info.longitude?.toString() ?? '';
            _latitude = info.latitude?.toString() ?? '';
            _address = info.address ?? '';
          } else {
            _isAddMode = true;
            // 从部门信息初始化名称
            _storeName = user?.deptName ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    // 验证
    if (_storeName.isEmpty) {
      _showError('请输入门店名称');
      return;
    }
    if (_telephone.isEmpty) {
      _showError('请输入门店电话');
      return;
    }
    if (!_isValidPhone(_telephone)) {
      _showError('请输入正确的手机号');
      return;
    }
    if (_longitude.isEmpty || double.tryParse(_longitude) == null) {
      _showError('请输入有效的经度');
      return;
    }
    if (_latitude.isEmpty || double.tryParse(_latitude) == null) {
      _showError('请输入有效的纬度');
      return;
    }
    if (_address.isEmpty) {
      _showError('请输入门店地址');
      return;
    }

    final lng = double.parse(_longitude);
    if (lng < -180 || lng > 180) {
      _showError('经度必须在-180到180之间');
      return;
    }
    final lat = double.parse(_latitude);
    if (lat < -90 || lat > 90) {
      _showError('纬度必须在-90到90之间');
      return;
    }

    final user = ref.read(currentUserProvider).value;
    final deptId = user?.deptId ?? 0;
    if (deptId == 0) return;

    setState(() => _isSaving = true);
    try {
      bool success;
      if (_isAddMode) {
        success = await _api.add(
          departmentID: deptId,
          name: _storeName,
          telephone: _telephone,
          address: _address,
          gis: '$_longitude,$_latitude',
          manager: _manager,
        );
      } else {
        success = await _api.edit(
          departmentID: deptId,
          name: _storeName,
          telephone: _telephone,
          address: _address,
          gis: '$_longitude,$_latitude',
          manager: _manager,
        );
      }

      if (success && mounted) {
        _showSuccess(_isAddMode ? '添加成功' : '保存成功');
        _loadData();
      } else if (mounted) {
        _showError(_isAddMode ? '添加失败' : '保存失败');
      }
    } catch (_) {
      if (mounted) _showError(_isAddMode ? '添加失败' : '保存失败');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
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

  void _showSuccess(String message) {
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

  void _showEditField({
    required String title,
    required String hint,
    required String initialValue,
    required int maxLength,
    required void Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.pop(ctx);
                    onSave(controller.text.trim());
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: controller,
              placeholder: hint,
              autofocus: true,
              maxLength: maxLength,
              padding: const EdgeInsets.all(12),
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
        middle: const Text('门店信息'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: const Text(
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
                    _SectionTitle(title: '基础信息'),
                    _InfoCard(
                      children: [
                        _EditableRow(
                          label: '门店名称',
                          value: _storeName,
                          isRequired: true,
                          onTap: () => _showEditField(
                            title: '门店名称',
                            hint: '请输入门店名称',
                            initialValue: _storeName,
                            maxLength: 50,
                            onSave: (v) => setState(() => _storeName = v),
                          ),
                        ),
                        _EditableRow(
                          label: '门店负责人',
                          value: _manager,
                          isRequired: true,
                          placeholder: '请输入负责人工号',
                          onTap: () => _showEditField(
                            title: '门店负责人',
                            hint: '请输入负责人工号',
                            initialValue: _manager,
                            maxLength: 20,
                            onSave: (v) => setState(() => _manager = v),
                          ),
                        ),
                        _EditableRow(
                          label: '门店电话',
                          value: _telephone,
                          isRequired: true,
                          placeholder: '请输入手机号',
                          onTap: () => _showEditField(
                            title: '门店电话',
                            hint: '请输入手机号',
                            initialValue: _telephone,
                            maxLength: 11,
                            onSave: (v) => setState(() => _telephone = v),
                          ),
                        ),
                        _EditableRow(
                          label: '经度',
                          value: _longitude,
                          isRequired: true,
                          placeholder: '请输入经度',
                          onTap: () => _showEditField(
                            title: '经度',
                            hint: '请输入经度（如：116.404）',
                            initialValue: _longitude,
                            maxLength: 20,
                            onSave: (v) => setState(() => _longitude = v),
                          ),
                        ),
                        _EditableRow(
                          label: '纬度',
                          value: _latitude,
                          isRequired: true,
                          placeholder: '请输入纬度',
                          onTap: () => _showEditField(
                            title: '纬度',
                            hint: '请输入纬度（如：39.915）',
                            initialValue: _latitude,
                            maxLength: 20,
                            onSave: (v) => setState(() => _latitude = v),
                          ),
                        ),
                        _EditableRow(
                          label: '门店地址',
                          value: _address,
                          isRequired: true,
                          placeholder: '请输入门店详细地址',
                          onTap: () => _showEditField(
                            title: '门店地址',
                            hint: '请输入门店详细地址',
                            initialValue: _address,
                            maxLength: 50,
                            onSave: (v) => setState(() => _address = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
        top: 8,
      ),
      child: Text(
        title,
        style: AppText.body.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRequired;
  final String placeholder;
  final VoidCallback onTap;

  const _EditableRow({
    required this.label,
    required this.value,
    this.isRequired = false,
    this.placeholder = '请输入',
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
              const Text(
                ' *',
                style: TextStyle(color: Color(0xFFFF3B30)),
              ),
            const Spacer(),
            Flexible(
              child: Text(
                value.isNotEmpty ? value : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  color: value.isNotEmpty
                      ? const Color(0xFF636366)
                      : const Color(0xFFC7C7CC),
                ),
                textAlign: TextAlign.right,
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

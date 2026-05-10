import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../api/task_management_api.dart';
import '../../api/employee_api.dart';
import '../../api/label_api.dart';
import '../../models/task_management.dart';
import '../../models/employee.dart';
import '../../models/label.dart';
import '../../config/api_config.dart';
import '../../services/token_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 任务模板编辑页
/// 对应 PWA /pages/path-d/task-management/task-template-edit.tsx
/// 支持新建和编辑任务模板
class TaskTemplateEditPage extends ConsumerStatefulWidget {
  /// 模板ID（null 表示新建）
  final String? templateId;

  const TaskTemplateEditPage({super.key, this.templateId});

  @override
  ConsumerState<TaskTemplateEditPage> createState() => _TaskTemplateEditPageState();
}

class _TaskTemplateEditPageState extends ConsumerState<TaskTemplateEditPage> {
  final TaskManagementApi _api = TaskManagementApi();
  final EmployeeApi _employeeApi = EmployeeApi();
  final LabelApi _labelApi = LabelApi();
  final TokenService _tokenService = TokenService();
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  TaskTemplateDetail? _original;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  // 表单状态
  late TextEditingController _nameController;
  late TextEditingController _introController;
  late TextEditingController _descController;
  late TextEditingController _selfEvalDescController;
  late TextEditingController _weightController;

  String? _editCate;
  List<int>? _editLabelIDs;
  String? _editStatus;
  int? _editWeight;
  String? _editAllowCheckType;
  List<int>? _editAllowCheckEmployees;
  bool? _editIsNeedSelfEvaluation;
  List<String>? _editAccessoriesUrls;
  List<int>? _editSendUser;
  int? _editResponsibleStartRemind;
  int? _editResponsibleEndRemind;
  int? _editCheckStartRemind;

  List<Employee>? _employeeList;
  bool _isLoadingEmployees = false;

  // 标签相关
  List<Label>? _labels;
  bool _isLoadingLabels = false;
  /// 标签ID → 名称缓存（用于显示）
  final Map<int, String> _labelNameCache = {};

  // 附件上传相关（待上传的本地路径，UI用）
  final List<String> _pendingLocalPaths = [];

  bool get _isNew => widget.templateId == null;
  bool get _hasChanges {
    if (_isNew) return _nameController.text.isNotEmpty;
    if (_original == null) return false;
    if (_editCate != null && _editCate != _original!.taskTemplateCate) return true;
    if (_editLabelIDs != null && !_listEquals(_editLabelIDs!, (_original!.labelIDs).toList())) return true;
    if (_editStatus != null && _editStatus != _original!.status) return true;
    if (_editWeight != null && _editWeight != _original!.taskWeight) return true;
    if (_introController.text != (_original!.introduction)) return true;
    if (_descController.text != (_original!.description)) return true;
    if (_editAllowCheckType != null && _editAllowCheckType != _original!.allowCheckType) return true;
    if (_editAllowCheckEmployees != null && !_listEquals(_editAllowCheckEmployees!, (_original!.allowCheckEmployees).toList())) return true;
    if (_editIsNeedSelfEvaluation != null && _editIsNeedSelfEvaluation != _original!.isNeedSelfEvaluation) return true;
    if (_editAccessoriesUrls != null && !_listEquals(_editAccessoriesUrls!, (_original!.accessoriesUrls).toList())) return true;
    if (_editSendUser != null && !_listEquals(_editSendUser!, (_original!.sendUser).toList())) return true;
    if (_editResponsibleStartRemind != null && _editResponsibleStartRemind != _original!.responsibleStartRemind) return true;
    if (_editResponsibleEndRemind != null && _editResponsibleEndRemind != _original!.responsibleEndRemind) return true;
    if (_editCheckStartRemind != null && _editCheckStartRemind != _original!.checkStartRemind) return true;
    if (_selfEvalDescController.text != (_original!.selfEvaluationDesc)) return true;
    return false;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _introController = TextEditingController();
    _descController = TextEditingController();
    _selfEvalDescController = TextEditingController();
    _weightController = TextEditingController(text: '100');
    _loadData();
    _loadEmployees();
    _loadLabels();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _descController.dispose();
    _selfEvalDescController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isNew) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getTaskTemplateDetail(widget.templateId!);
      if (!mounted) return;
      if (data == null) {
        setState(() { _error = '未找到任务模板'; _isLoading = false; });
        return;
      }
      setState(() {
        _original = data;
        _nameController.text = data.name;
        _introController.text = data.introduction;
        _descController.text = data.description;
        _weightController.text = '${data.taskWeight}';
        _selfEvalDescController.text = data.selfEvaluationDesc;
        _editAccessoriesUrls = List<String>.from(data.accessoriesUrls);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final list = await _employeeApi.listEmployees();
      if (!mounted) return;
      setState(() { _employeeList = list; _isLoadingEmployees = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _loadLabels() async {
    setState(() => _isLoadingLabels = true);
    try {
      // 任务模板标签使用 'taskTemplate' 类型
      final list = await _labelApi.listByCondition(type: LabelType.member);
      if (!mounted) return;
      // 过滤出与任务模板相关的标签（这里获取全部再过滤）
      setState(() { _labels = list; _isLoadingLabels = false; });
      // 填充名称缓存
      for (final label in list) {
        _labelNameCache[label.id] = label.name;
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLabels = false);
    }
  }

  /// 添加图片附件
  Future<void> _addAttachment() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image == null || !mounted) return;

    setState(() => _pendingLocalPaths.add(image.path));

    try {
      final url = await _uploadAttachment(image);
      if (mounted) {
        // 上传成功后，将URL加入附件列表
        final current = _editAccessoriesUrls ?? List<String>.from(_original?.accessoriesUrls ?? []);
        setState(() {
          _pendingLocalPaths.remove(image.path);
          _editAccessoriesUrls = [...current, url];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingLocalPaths.remove(image.path));
        _showError('上传失败: $e');
      }
    }
  }

  Future<String> _uploadAttachment(XFile image) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final token = await _tokenService.getToken();
    final resp = await _dio.post(
      '${ApiConfig.baseUrl}upload',
      data: formData,
      options: Options(headers: {'Authorization': token ?? ''}),
    );
    final url = resp.data['res']?['url'] as String? ??
        resp.data['res']?['path'] as String? ?? '';
    if (url.isEmpty) throw Exception('上传返回路径为空');
    return url;
  }

  void _removeAttachment(String url) {
    setState(() {
      // 从当前编辑列表中移除
      final current = _editAccessoriesUrls ?? List<String>.from(_original?.accessoriesUrls ?? []);
      _editAccessoriesUrls = current.where((u) => u != url).toList();
    });
  }

  Future<void> _save() async {
    // 验证
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('请输入任务模板名称');
      return;
    }
    if (name.length > 30) {
      _showError('任务模板名称不可大于 30 个字符');
      return;
    }
    final weight = int.tryParse(_weightController.text);
    if (weight == null) {
      _showError('请填写权重');
      return;
    }
    if (weight < 0 || weight > 999) {
      _showError('请输入 0-999 的整数');
      return;
    }
    if (_introController.text.length > 50) {
      _showError('任务模板简介不可大于 50 个字符');
      return;
    }
    if (_descController.text.length > 5000) {
      _showError('详细说明不可大于 5000 个字符');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final intro = _introController.text.trim();
      final desc = _descController.text.trim();
      final selfEvalDesc = _selfEvalDescController.text.trim();

      bool success;
      if (_isNew) {
        success = await _api.addTaskTemplate(
          taskTemplateCate: _editCate ?? 'goal',
          name: name,
          taskWeight: weight,
          introduction: intro.isEmpty ? null : intro,
          description: desc.isEmpty ? null : desc,
          labelIDs: _editLabelIDs,
          allowCheckType: _editAllowCheckType,
          allowCheckEmployees: _editAllowCheckEmployees,
          isNeedSelfEvaluation: _editIsNeedSelfEvaluation,
          accessoriesUrls: _editAccessoriesUrls,
          sendUser: _editSendUser,
          responsibleStartRemind: _editResponsibleStartRemind,
          responsibleEndRemind: _editResponsibleEndRemind,
          checkStartRemind: _editCheckStartRemind,
          selfEvaluationDesc: selfEvalDesc.isEmpty ? null : selfEvalDesc,
        );
      } else {
        final body = <String, dynamic>{
          'id': widget.templateId,
          'name': name,
          'taskWeight': weight,
        };
        if (_editCate != null) body['taskTemplateCate'] = _editCate;
        if (intro.isNotEmpty) body['introduction'] = intro;
        if (desc.isNotEmpty) body['description'] = desc;
        if (_editLabelIDs != null) body['labelIDs'] = _editLabelIDs;
        if (_editAllowCheckType != null) body['allowCheckType'] = _editAllowCheckType;
        if (_editAllowCheckEmployees != null) body['allowCheckEmployees'] = _editAllowCheckEmployees;
        if (_editIsNeedSelfEvaluation != null) body['isNeedSelfEvaluation'] = _editIsNeedSelfEvaluation;
        if (_editAccessoriesUrls != null) body['accessoriesUrls'] = _editAccessoriesUrls;
        if (_editSendUser != null) body['sendUser'] = _editSendUser;
        if (_editStatus != null) body['status'] = _editStatus;
        if (_editResponsibleStartRemind != null) body['responsibleStartRemind'] = _editResponsibleStartRemind;
        if (_editResponsibleEndRemind != null) body['responsibleEndRemind'] = _editResponsibleEndRemind;
        if (_editCheckStartRemind != null) body['checkStartRemind'] = _editCheckStartRemind;
        if (selfEvalDesc.isNotEmpty) body['selfEvaluationDesc'] = selfEvalDesc;

        success = await _api.editTaskTemplate(
          id: widget.templateId!,
          name: name,
          taskWeight: weight,
          introduction: intro.isEmpty ? null : intro,
          description: desc.isEmpty ? null : desc,
          labelIDs: _editLabelIDs,
          allowCheckType: _editAllowCheckType,
          allowCheckEmployees: _editAllowCheckEmployees,
          isNeedSelfEvaluation: _editIsNeedSelfEvaluation,
          accessoriesUrls: _editAccessoriesUrls,
          sendUser: _editSendUser,
          status: _editStatus,
          responsibleStartRemind: _editResponsibleStartRemind,
          responsibleEndRemind: _editResponsibleEndRemind,
          checkStartRemind: _editCheckStartRemind,
          selfEvaluationDesc: selfEvalDesc.isEmpty ? null : selfEvalDesc,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success) {
        _showSuccess(_isNew ? '新建任务模板成功' : '编辑任务模板成功');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      } else {
        _showError(_isNew ? '新建失败' : '保存失败');
      }
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
            const Icon(CupertinoIcons.checkmark_circle_fill, color: CupertinoColors.activeGreen),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        actions: [
          CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(ctx)),
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
          CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isNew ? '新建任务模板' : '编辑任务模板'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('返回'),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  '保存',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _hasChanges ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                  ),
                ),
        ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('基础信息', [
            _buildTextFieldRow('任务模板名称', _nameController,
                placeholder: '请输入任务模板名称', maxLength: 30),
            _buildDivider(),
            _buildSelectRow('任务模板分类', _getCateLabel(),
                onTap: _showCatePicker),
            _buildDivider(),
            _buildToggleRow('启用状态', _getStatusLabel(),
                isEnabled: _getEffectiveStatus() == 'enabled',
                onChanged: (v) => setState(() {
                  _editStatus = v ? 'enabled' : 'disabled';
                })),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('模板设置', [
            _buildTextFieldRow('任务权重', _weightController,
                placeholder: '请输入权重(0-999)', keyboardType: TextInputType.number, maxLength: 3),
            _buildDivider(),
            _buildTextFieldRow('任务简介', _introController,
                placeholder: '请输入任务简介(最多50字)', maxLength: 50, maxLines: 2),
            _buildDivider(),
            _buildTextFieldRow('详细说明', _descController,
                placeholder: '请输入详细说明(最多5000字)', maxLines: 4),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('验收设置', [
            _buildSelectRow('验收类型', _getAllowCheckTypeLabel(),
                onTap: _showAllowCheckTypePicker),
            _buildDivider(),
            _buildSelectRow('可验收职员', _getAllowCheckEmployeesLabel(),
                onTap: _showAllowCheckEmployeesPicker),
            _buildDivider(),
            _buildToggleRow('需要自评', '员工完成任务后需进行自我评价',
                isEnabled: _getEffectiveIsNeedSelfEvaluation(),
                onChanged: (v) => setState(() => _editIsNeedSelfEvaluation = v)),
            if (_getEffectiveIsNeedSelfEvaluation()) ...[
              _buildDivider(),
              _buildTextFieldRow('自评说明', _selfEvalDescController,
                  placeholder: '请输入自评说明', maxLines: 3),
            ],
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('提醒设置', [
            _buildSelectRow('责任人开始提醒', _getRemindLabel(_editResponsibleStartRemind, _responsibleStartRemindOptions),
                onTap: () => _showRemindPicker('start')),
            _buildDivider(),
            _buildSelectRow('责任人结束提醒', _getRemindLabel(_editResponsibleEndRemind, _responsibleEndRemindOptions),
                onTap: () => _showRemindPicker('end')),
            _buildDivider(),
            _buildSelectRow('验收人提醒', _getRemindLabel(_editCheckStartRemind, _checkStartRemindOptions),
                onTap: () => _showRemindPicker('check')),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildSection('抄送设置', [
            _buildSelectRow('抄送人', _getSendUserLabel(),
                onTap: _showSendUserPicker),
          ]),
          const SizedBox(height: AppSpacing.md),
          // 任务标签
          _buildSection('任务标签', [
            _buildSelectRow('标签', _getLabelNames(),
                onTap: _showLabelPicker),
          ]),
          const SizedBox(height: AppSpacing.md),
          // 附件上传
          _buildSection('附件', [
            _buildAttachmentSection(),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppText.label),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16);

  Widget _buildTextFieldRow(
    String label,
    TextEditingController controller, {
    String? placeholder,
    TextInputType? keyboardType,
    int maxLength = 0,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppText.body),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType: keyboardType,
              maxLines: maxLines,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectRow(String label, String value, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: AppText.body),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '请选择' : value,
                style: TextStyle(
                  fontSize: 15,
                  color: value.isEmpty ? CupertinoColors.placeholderText : CupertinoColors.black,
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, String subtitle,
      {required bool isEnabled, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          CupertinoSwitch(
            value: isEnabled,
            onChanged: onChanged,
            activeTrackColor: CupertinoColors.activeBlue,
          ),
        ],
      ),
    );
  }

  // ── 分类 ─────────────────────────────────────────────────

  String _getCateLabel() {
    final v = _editCate ?? _original?.taskTemplateCate;
    return TaskTemplateCate.fromValue(v)?.label ?? '请选择分类';
  }

  void _showCatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择任务模板分类'),
        actions: TaskTemplateCate.values.map((c) =>
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _editCate = c.value);
              Navigator.pop(ctx);
            },
            child: Text(c.label),
          ),
        ).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  // ── 状态 ─────────────────────────────────────────────────

  String _getStatusLabel() {
    return _getEffectiveStatus() == 'enabled' ? '已启用' : '已停用';
  }

  String _getEffectiveStatus() {
    return _editStatus ?? _original?.status ?? 'enabled';
  }

  // ── 验收类型 ─────────────────────────────────────────────

  String _getAllowCheckTypeLabel() {
    final v = _editAllowCheckType ?? _original?.allowCheckType;
    return AllowCheckType.fromValue(v)?.label ?? '请选择验收类型';
  }

  void _showAllowCheckTypePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择验收类型'),
        actions: AllowCheckType.values.map((c) =>
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _editAllowCheckType = c.value);
              Navigator.pop(ctx);
            },
            child: Text(c.label),
          ),
        ).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  // ── 验收职员 ─────────────────────────────────────────────

  String _getAllowCheckEmployeesLabel() {
    final employees = _editAllowCheckEmployees ?? _original?.allowCheckEmployees ?? [];
    if (employees.isEmpty) return '请选择';
    final names = employees.map((id) {
      final emp = _employeeList?.where((e) => e.userIdent == id).firstOrNull;
      return emp?.name ?? '职员#$id';
    }).toList();
    return names.join('、');
  }

  void _showAllowCheckEmployeesPicker() {
    final selected = List<int>.from(_editAllowCheckEmployees ?? _original?.allowCheckEmployees ?? []);
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
                  const Text('选择验收职员', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey3),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(emp.userIdent);
                              } else {
                                selected.add(emp.userIdent);
                              }
                              _editAllowCheckEmployees = List.from(selected);
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.name ?? '职员', style: const TextStyle(color: CupertinoColors.black, fontSize: 15)),
                                    if (emp.phone != null)
                                      Text(emp.phone!, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
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
                        setState(() => _editAllowCheckEmployees = []);
                        Navigator.pop(ctx);
                      },
                      child: const Text('清空', style: TextStyle(color: CupertinoColors.black)),
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

  // ── 自评 ─────────────────────────────────────────────

  bool _getEffectiveIsNeedSelfEvaluation() {
    return _editIsNeedSelfEvaluation ?? _original?.isNeedSelfEvaluation ?? false;
  }

  // ── 提醒 ─────────────────────────────────────────────

  static const _responsibleStartRemindOptions = [
    (null, '不提醒'),
    (15, '提前15分钟'),
    (30, '提前30分钟'),
    (60, '提前1小时'),
    (120, '提前2小时'),
    (1440, '提前1天'),
  ];

  static const _responsibleEndRemindOptions = [
    (null, '不提醒'),
    (15, '提前15分钟'),
    (30, '提前30分钟'),
    (60, '提前1小时'),
    (120, '提前2小时'),
    (1440, '提前1天'),
  ];

  static const _checkStartRemindOptions = [
    (null, '不提醒'),
    (15, '提前15分钟'),
    (30, '提前30分钟'),
    (60, '提前1小时'),
    (120, '提前2小时'),
    (1440, '提前1天'),
  ];

  String _getRemindLabel(int? value, List<(int?, String)> options) {
    for (final opt in options) {
      if (opt.$1 == value) return opt.$2;
    }
    return '请选择';
  }

  void _showRemindPicker(String type) {
    List<(int?, String)> options;
    void Function(int?) onSelect;

    switch (type) {
      case 'start':
        options = _responsibleStartRemindOptions;
        onSelect = (v) => setState(() => _editResponsibleStartRemind = v);
        break;
      case 'end':
        options = _responsibleEndRemindOptions;
        onSelect = (v) => setState(() => _editResponsibleEndRemind = v);
        break;
      default:
        options = _checkStartRemindOptions;
        onSelect = (v) => setState(() => _editCheckStartRemind = v);
    }

    String title;
    switch (type) {
      case 'start': title = '责任人开始提醒'; break;
      case 'end': title = '责任人结束提醒'; break;
      default: title = '验收人提醒';
    }

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: options.map((opt) =>
          CupertinoActionSheetAction(
            onPressed: () {
              onSelect(opt.$1);
              Navigator.pop(ctx);
            },
            child: Text(opt.$2),
          ),
        ).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  // ── 抄送人 ─────────────────────────────────────────────

  String _getSendUserLabel() {
    final users = _editSendUser ?? _original?.sendUser ?? [];
    if (users.isEmpty) return '请选择';
    final names = users.map((id) {
      final emp = _employeeList?.where((e) => e.userIdent == id).firstOrNull;
      return emp?.name ?? '职员#$id';
    }).toList();
    return names.join('、');
  }

  void _showSendUserPicker() {
    final selected = List<int>.from(_editSendUser ?? _original?.sendUser ?? []);
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
                  const Text('选择抄送人', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey3),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(emp.userIdent);
                              } else {
                                selected.add(emp.userIdent);
                              }
                              _editSendUser = List.from(selected);
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.name ?? '职员', style: const TextStyle(color: CupertinoColors.black, fontSize: 15)),
                                    if (emp.phone != null)
                                      Text(emp.phone!, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
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
                        setState(() => _editSendUser = []);
                        Navigator.pop(ctx);
                      },
                      child: const Text('清空', style: TextStyle(color: CupertinoColors.black)),
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

  // ── 任务标签 ───────────────────────────────────────────

  /// 获取当前选中的标签名称
  String _getLabelNames() {
    final ids = _editLabelIDs ?? _original?.labelIDs ?? [];
    if (ids.isEmpty) return '请选择';
    final names = ids.map((id) => _labelNameCache[id] ?? '标签#$id').toList();
    return names.join('、');
  }

  void _showLabelPicker() {
    final selected = List<int>.from(_editLabelIDs ?? _original?.labelIDs ?? []);

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
                  const Text('选择标签', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey3),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingLabels
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      itemCount: _labels?.length ?? 0,
                      itemBuilder: (context, index) {
                        final label = _labels![index];
                        final isSelected = selected.contains(label.id);
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(label.id);
                              } else {
                                selected.add(label.id);
                              }
                              _editLabelIDs = List.from(selected);
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(label.color.replaceFirst('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(label.name, style: const TextStyle(color: CupertinoColors.black, fontSize: 15)),
                              ),
                              Icon(
                                isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
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
                        setState(() => _editLabelIDs = []);
                        Navigator.pop(ctx);
                      },
                      child: const Text('清空', style: TextStyle(color: CupertinoColors.black)),
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

  // ── 附件展示 ───────────────────────────────────────────

  Widget _buildAttachmentSection() {
    final urls = _editAccessoriesUrls ?? _original?.accessoriesUrls ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已上传附件
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...urls.map((url) => _AttachmentChip(
              url: url,
              onRemove: () => _removeAttachment(url),
            )),
            // 待上传图片
            ..._pendingLocalPaths.map((path) => _PendingAttachmentChip(path: path)),
            // 添加按钮
            GestureDetector(
              onTap: _addAttachment,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: const Icon(CupertinoIcons.plus, color: CupertinoColors.systemGrey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 附件缩略图组件
class _AttachmentChip extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _AttachmentChip({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemGrey5,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, size: 24)),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.xmark, size: 10, color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 待上传图片占位组件
class _PendingAttachmentChip extends StatelessWidget {
  final String path;
  const _PendingAttachmentChip({required this.path});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemGrey5,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CupertinoActivityIndicator(color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

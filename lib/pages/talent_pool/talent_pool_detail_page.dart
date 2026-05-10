import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/talent_pool_api.dart';
import '../../models/talent_pool.dart';
import '../../theme/app_theme.dart';

/// 人才池详情页 Provider
final talentPoolDetailProvider =
    FutureProvider.family<TalentPool?, String>((ref, uuid) async {
  return TalentPoolApi().getVisitorDetail(uuid);
});

/// 人才池详情/编辑页（3步表单）
class TalentPoolDetailPage extends ConsumerStatefulWidget {
  final String? uuid;
  final bool isEdit;

  const TalentPoolDetailPage({
    super.key,
    this.uuid,
    this.isEdit = false,
  });

  @override
  ConsumerState<TalentPoolDetailPage> createState() => _TalentPoolDetailPageState();
}

class _TalentPoolDetailPageState extends ConsumerState<TalentPoolDetailPage> {
  final TalentPoolApi _api = TalentPoolApi();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // 表单数据（内存态）
  late Map<String, dynamic> _formData;

  // 原始数据（用于 pickDiff）
  Map<String, dynamic>? _originalData;

  // 步骤1：基本信息
  final _nameController = TextEditingController();
  final _nationController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _healthyController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _nativePlaceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _qqController = TextEditingController();
  final _politicalController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _specialityController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _personalRemarksController = TextEditingController();
  Sex _selectedSex = Sex.secret;
  int? _birthdayTimestamp;
  Education? _selectedEducation;
  EducationType? _selectedEducationType;

  // 步骤2：家庭背景
  final _contactController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactAddressController = TextEditingController();
  bool? _maritalStatus;

  // 步骤3：附件（图片URL列表）
  List<String> _fullFacedPhotos = [];
  List<String> _idCardFrontPhotos = [];
  List<String> _idCardBackPhotos = [];
  List<String> _bankCardFrontPhotos = [];
  List<String> _bankCardBackPhotos = [];
  List<String> _educationPhotos = [];

  @override
  void initState() {
    super.initState();
    _formData = {};
    if (widget.uuid != null) {
      _loadData();
    }
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      final talent = await _api.getVisitorDetail(widget.uuid!);
      if (talent != null && mounted) {
        _originalData = talent.toJson();
        _populateForm(talent);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(TalentPool t) {
    setState(() {
      _nameController.text = t.name;
      _nationController.text = t.nation ?? '';
      _heightController.text = t.height?.toString() ?? '';
      _weightController.text = t.weight?.toString() ?? '';
      _healthyController.text = t.healthy ?? '';
      _idNumberController.text = t.idNumber ?? '';
      _nativePlaceController.text = t.nativePlace ?? '';
      _phoneController.text = t.phone;
      _emailController.text = t.email ?? '';
      _qqController.text = t.qqNumber ?? '';
      _politicalController.text = t.political ?? '';
      _postalCodeController.text = t.postalCode ?? '';
      _schoolController.text = t.school ?? '';
      _specialityController.text = t.speciality ?? '';
      _hobbyController.text = t.hobby ?? '';
      _personalRemarksController.text = t.personalRemarks ?? '';
      _selectedSex = t.sex;
      _birthdayTimestamp = t.birthday;
      _selectedEducation = Education.fromString(t.education);
      _selectedEducationType = EducationType.fromString(t.educationType);

      _contactController.text = t.contact ?? '';
      _contactPhoneController.text = t.contactPhone ?? '';
      _contactAddressController.text = t.contactAddress ?? '';
      _maritalStatus = t.maritalStatus;

      final imgs = t.images;
      if (imgs != null) {
        _fullFacedPhotos = List.from(imgs.fullFacedPhoto ?? []);
        _idCardFrontPhotos = List.from(imgs.idCardFront ?? []);
        _idCardBackPhotos = List.from(imgs.idCardBack ?? []);
        _bankCardFrontPhotos = List.from(imgs.bankCardFront ?? []);
        _bankCardBackPhotos = List.from(imgs.bankCardBack ?? []);
        _educationPhotos = List.from(imgs.education ?? []);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _healthyController.dispose();
    _idNumberController.dispose();
    _nativePlaceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _qqController.dispose();
    _politicalController.dispose();
    _postalCodeController.dispose();
    _schoolController.dispose();
    _specialityController.dispose();
    _hobbyController.dispose();
    _personalRemarksController.dispose();
    _contactController.dispose();
    _contactPhoneController.dispose();
    _contactAddressController.dispose();
    super.dispose();
  }

  /// 收集当前步骤数据到 _formData
  void _collectCurrentStepData() {
    switch (_currentStep) {
      case 0:
        _formData['name'] = _nameController.text.trim();
        _formData['sex'] = _selectedSex.value;
        _formData['nation'] = _nationController.text.trim();
        _formData['height'] = int.tryParse(_heightController.text.trim());
        _formData['weight'] = int.tryParse(_weightController.text.trim());
        _formData['healthy'] = _healthyController.text.trim();
        _formData['idNumber'] = _idNumberController.text.trim();
        _formData['birthday'] = _birthdayTimestamp;
        _formData['nativePlace'] = _nativePlaceController.text.trim();
        _formData['phone'] = _phoneController.text.trim();
        _formData['email'] = _emailController.text.trim();
        _formData['qqNumber'] = _qqController.text.trim();
        _formData['political'] = _politicalController.text.trim();
        _formData['postalCode'] = _postalCodeController.text.trim();
        _formData['education'] = _selectedEducation?.value;
        _formData['educationType'] = _selectedEducationType?.value;
        _formData['school'] = _schoolController.text.trim();
        _formData['speciality'] = _specialityController.text.trim();
        _formData['hobby'] = _hobbyController.text.trim();
        _formData['personalRemarks'] = _personalRemarksController.text.trim();
        break;
      case 1:
        _formData['contact'] = _contactController.text.trim();
        _formData['contactPhone'] = _contactPhoneController.text.trim();
        _formData['maritalStatus'] = _maritalStatus;
        _formData['contactAddress'] = _contactAddressController.text.trim();
        break;
      case 2:
        _formData['images'] = {
          'fullFacedPhoto': _fullFacedPhotos,
          'idCardFront': _idCardFrontPhotos,
          'idCardBack': _idCardBackPhotos,
          'bankCardFront': _bankCardFrontPhotos,
          'bankCardBack': _bankCardBackPhotos,
          'education': _educationPhotos,
        };
        break;
    }
  }

  /// pickDiff：只返回与原始数据不同的字段
  Map<String, dynamic> _pickDiff() {
    final diff = <String, dynamic>{};
    for (final entry in _formData.entries) {
      final key = entry.key;
      if (key == 'images') {
        // images 单独处理
        final origImages = _originalData?['images'] as Map<String, dynamic>?;
        final newImages = entry.value as Map<String, dynamic>;
        final imageDiff = <String, dynamic>{};
        for (final imgEntry in newImages.entries) {
          final origList = (origImages?[imgEntry.key] as List?)?.cast<String>() ?? [];
          final newList = (imgEntry.value as List).cast<String>();
          if (!_listEquals(origList, newList)) {
            imageDiff[imgEntry.key] = newList;
          }
        }
        if (imageDiff.isNotEmpty) diff['images'] = imageDiff;
      } else {
        final origVal = _originalData?[key];
        final newVal = entry.value;
        if (!_equals(origVal, newVal)) {
          diff[key] = newVal;
        }
      }
    }
    return diff;
  }

  bool _equals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null && b == null) return true;
    return false;
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _save([bool showDialog = true]) async {
    _collectCurrentStepData();
    final diff = _pickDiff();
    if (diff.isEmpty && widget.uuid != null) {
      if (showDialog && mounted) {
        _showToast('没有修改，无需保存');
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      bool success;
      if (widget.uuid != null) {
        success = await _api.editVisitorInfo(diff, widget.uuid!);
      } else {
        success = await _api.editVisitorInfo(_formData, widget.uuid ?? '');
      }
      if (!mounted) return;
      if (success) {
        _originalData = Map.from(_originalData ?? {})..addAll(diff);
        if (showDialog) {
          _showSuccessDialog();
        }
      } else {
        _showToast('保存失败，请重试');
      }
    } catch (e) {
      if (mounted) _showToast('保存失败：$e');
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

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('保存成功'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showToast('请填写姓名');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showToast('请填写手机号');
        return;
      }
    }
    _collectCurrentStepData();
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _prevStep() {
    _collectCurrentStepData();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['基本信息', '家庭背景', '附件上传'];
    final titles = [
      '基本信息',
      '家庭背景',
      '附件上传',
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(titles[_currentStep]),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _prevStep,
          child: _currentStep == 0
              ? const Icon(CupertinoIcons.back)
              : const Icon(CupertinoIcons.chevron_left),
        ),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _save(false),
                child: const Text('保存', style: TextStyle(fontSize: 16)),
              ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: CupertinoColors.destructiveRed)))
                : Column(
                    children: [
                      // 步骤指示器
                      _StepIndicator(steps: steps, current: _currentStep),
                      // 表单内容
                      Expanded(
                        child: IndexedStack(
                          index: _currentStep,
                          children: [
                            _buildBaseInfoStep(),
                            _buildFamilyBackgroundStep(),
                            _buildAttachmentStep(),
                          ],
                        ),
                      ),
                      // 底部按钮
                      _buildBottomActions(),
                    ],
                  ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // 步骤1：基本信息
  // ═══════════════════════════════════════
  Widget _buildBaseInfoStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('基本信息'),
        _buildTextField('姓名', _nameController, required: true, placeholder: '请输入姓名'),
        _buildSexPicker(),
        _buildTextField('民族', _nationController, placeholder: '请输入民族'),
        _buildRow([
          _buildTextField('身高(cm)', _heightController, placeholder: 'cm', keyboardType: TextInputType.number, flex: 1),
          const SizedBox(width: 12),
          _buildTextField('体重(kg)', _weightController, placeholder: 'kg', keyboardType: TextInputType.number, flex: 1),
        ]),
        _buildTextField('健康状况', _healthyController, placeholder: '请输入健康状况'),
        _buildTextField('身份证号', _idNumberController, placeholder: '请输入身份证号', keyboardType: TextInputType.text),
        _buildDatePicker('出生日期', _birthdayTimestamp, (ts) => setState(() => _birthdayTimestamp = ts)),
        _buildTextField('籍贯', _nativePlaceController, placeholder: '请输入籍贯'),
        _buildTextField('手机号', _phoneController, required: true, placeholder: '请输入手机号', keyboardType: TextInputType.phone),
        _buildTextField('邮箱', _emailController, placeholder: '请输入邮箱', keyboardType: TextInputType.emailAddress),
        _buildTextField('QQ号', _qqController, placeholder: '请输入QQ号', keyboardType: TextInputType.number),
        _buildTextField('政治面貌', _politicalController, placeholder: '请输入政治面貌'),
        _buildTextField('邮政编码', _postalCodeController, placeholder: '请输入邮政编码', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _SectionTitle('教育信息'),
        _buildEducationPicker(),
        _buildEducationTypePicker(),
        _buildTextField('毕业院校', _schoolController, placeholder: '请输入毕业院校'),
        _buildTextField('专业', _specialityController, placeholder: '请输入专业'),
        _buildTextField('爱好', _hobbyController, placeholder: '请输入爱好'),
        _buildTextField('个人备注', _personalRemarksController, placeholder: '请输入个人备注', maxLines: 3),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 步骤2：家庭背景
  // ═══════════════════════════════════════
  Widget _buildFamilyBackgroundStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('家庭信息'),
        _buildTextField('紧急联系人', _contactController, placeholder: '请输入紧急联系人姓名'),
        _buildTextField('联系人电话', _contactPhoneController, placeholder: '请输入联系人电话', keyboardType: TextInputType.phone),
        _buildMaritalStatusPicker(),
        _buildTextField('联系地址', _contactAddressController, placeholder: '请输入详细地址', maxLines: 3),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 步骤3：附件上传
  // ═══════════════════════════════════════
  Widget _buildAttachmentStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('证件照片'),
        _ImageUploader(
          label: '一寸免冠照',
          images: _fullFacedPhotos,
          onImagesChanged: (imgs) => setState(() => _fullFacedPhotos = imgs),
        ),
        _ImageUploader(
          label: '身份证正面',
          images: _idCardFrontPhotos,
          onImagesChanged: (imgs) => setState(() => _idCardFrontPhotos = imgs),
        ),
        _ImageUploader(
          label: '身份证背面',
          images: _idCardBackPhotos,
          onImagesChanged: (imgs) => setState(() => _idCardBackPhotos = imgs),
        ),
        const SizedBox(height: 16),
        _SectionTitle('银行卡照片'),
        _ImageUploader(
          label: '银行卡正面',
          images: _bankCardFrontPhotos,
          onImagesChanged: (imgs) => setState(() => _bankCardFrontPhotos = imgs),
        ),
        _ImageUploader(
          label: '银行卡背面',
          images: _bankCardBackPhotos,
          onImagesChanged: (imgs) => setState(() => _bankCardBackPhotos = imgs),
        ),
        const SizedBox(height: 16),
        _SectionTitle('学历证明'),
        _ImageUploader(
          label: '学历照片',
          images: _educationPhotos,
          onImagesChanged: (imgs) => setState(() => _educationPhotos = imgs),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 底部操作按钮
  // ═══════════════════════════════════════
  Widget _buildBottomActions() {
    final isLast = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              onPressed: _prevStep,
              child: Text(
                _currentStep == 0 ? '取消' : '上一步',
                style: const TextStyle(color: CupertinoColors.label),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _isSaving ? null : _nextStep,
              child: Text(isLast ? '保存' : '下一步'),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // 通用表单组件
  // ═══════════════════════════════════════
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel)),
        ),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    String placeholder = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? flex,
  }) {
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              if (required) const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            maxLines: maxLines,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4.resolveFrom(context), width: 0.5),
            ),
          ),
        ],
      ),
    );
    if (flex != null) {
      return Expanded(flex: flex, child: child);
    }
    return child;
  }

  Widget _buildRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSexPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('性别', style: TextStyle(fontSize: 14)), Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 14))]),
          const SizedBox(height: 6),
          CupertinoSlidingSegmentedControl<Sex>(
            groupValue: _selectedSex,
            children: {
              for (final s in Sex.values)
                s: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(s.label, style: const TextStyle(fontSize: 14)),
                ),
            },
            onValueChanged: (v) => setState(() => _selectedSex = v ?? Sex.secret),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, int? timestamp, ValueChanged<int?> onChanged) {
    String display = '请选择';
    if (timestamp != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      display = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showDatePicker(timestamp, onChanged),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4.resolveFrom(context), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(display, style: TextStyle(color: timestamp == null ? CupertinoColors.placeholderText : CupertinoColors.label)),
                  const Icon(CupertinoIcons.calendar, size: 18, color: CupertinoColors.systemGrey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(int? current, ValueChanged<int?> onChanged) {
    DateTime initial = current != null
        ? DateTime.fromMillisecondsSinceEpoch(current * 1000)
        : DateTime.now();
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
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () {
                    onChanged((initial.millisecondsSinceEpoch / 1000).round());
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                maximumDate: DateTime.now(),
                minimumYear: 1900,
                onDateTimeChanged: (dt) => initial = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('学历', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showPicker<Education>(
              items: Education.values,
              selected: _selectedEducation,
              labelBuilder: (e) => e.label,
              onSelected: (e) => setState(() => _selectedEducation = e),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey4.resolveFrom(context), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedEducation?.label ?? '请选择学历',
                    style: TextStyle(color: _selectedEducation == null ? CupertinoColors.placeholderText : CupertinoColors.label),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 18, color: CupertinoColors.systemGrey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTypePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('学历性质', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          CupertinoSlidingSegmentedControl<EducationType>(
            groupValue: _selectedEducationType,
            children: {
              for (final e in EducationType.values)
                e: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(e.label, style: const TextStyle(fontSize: 14)),
                ),
            },
            onValueChanged: (v) => setState(() => _selectedEducationType = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMaritalStatusPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('婚姻状况', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          CupertinoSlidingSegmentedControl<bool>(
            groupValue: _maritalStatus,
            children: const {
              true: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Text('已婚', style: TextStyle(fontSize: 14))),
              false: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Text('未婚', style: TextStyle(fontSize: 14))),
            },
            onValueChanged: (v) => setState(() => _maritalStatus = v),
          ),
        ],
      ),
    );
  }

  void _showPicker<T>({
    required List<T> items,
    required T? selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onSelected,
  }) {
    int initIdx = selected != null ? items.indexOf(selected) : 0;
    if (initIdx < 0) initIdx = 0;
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
                  onSelected(items[initIdx]);
                  Navigator.pop(ctx);
                }),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(initialItem: initIdx),
                onSelectedItemChanged: (idx) => initIdx = idx,
                children: items.map((e) => Center(child: Text(labelBuilder(e)))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 步骤指示器
// ════════════════════════════════════════════════════════════════════════════
class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int current;

  const _StepIndicator({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator.resolveFrom(context), width: 0.5),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == current;
          final isDone = i < current;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: isDone || isActive ? AppColors.accent : CupertinoColors.systemGrey4.resolveFrom(context),
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.accent : isActive ? AppColors.accent.withOpacity(0.15) : CupertinoColors.systemGrey5.resolveFrom(context),
                    border: isActive ? Border.all(color: AppColors.accent, width: 1.5) : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(CupertinoIcons.checkmark, size: 12, color: CupertinoColors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.accent : CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: isDone ? AppColors.accent : CupertinoColors.systemGrey4.resolveFrom(context),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 分组标题
// ════════════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 图片上传组件
// ════════════════════════════════════════════════════════════════════════════
class _ImageUploader extends StatelessWidget {
  final String label;
  final List<String> images;
  final ValueChanged<List<String>> onImagesChanged;

  const _ImageUploader({
    required this.label,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text('(${images.length})', style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 添加按钮
                GestureDetector(
                  onTap: () => _addImage(context),
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey4.resolveFrom(context), width: 0.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.plus_circle, size: 28, color: CupertinoColors.systemGrey),
                        SizedBox(height: 4),
                        Text('添加', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  ),
                ),
                // 已上传图片
                ...images.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: CupertinoColors.systemGrey5.resolveFrom(context),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: entry.value.startsWith('http')
                              ? Image.network(entry.value, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo))
                              : const Icon(CupertinoIcons.photo, size: 32, color: CupertinoColors.systemGrey),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            final updated = List<String>.from(images);
                            updated.removeAt(entry.key);
                            onImagesChanged(updated);
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.destructiveRed,
                            ),
                            child: const Icon(CupertinoIcons.xmark, size: 12, color: CupertinoColors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '提示：长按图片可删除',
            style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          ),
        ],
      ),
    );
  }

  void _addImage(BuildContext context) {
    // 注意：需要 image_picker 包支持，当前为占位实现
    // 接入 image_picker 后替换为实际拍照/相册选择逻辑
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('添加图片'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 接入 image_picker 拍照
              // 调用 ImagePicker().pickImage(source: ImageSource.camera)
            },
            child: const Text('拍照'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 接入 image_picker 相册
              // 调用 ImagePicker().pickImage(source: ImageSource.gallery)
            },
            child: const Text('从相册选择'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }
}

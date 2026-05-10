import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../api/recycle_order_api.dart';
import '../../api/employee_api.dart';
import '../../api/api_client.dart';
import '../../models/employee.dart';
import '../../providers/auth_provider.dart';
import '../../services/token_service.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 回收加单页面（创建回收订单）
/// 流程：搜索设备 → 选择规则 → 答题评估 → 填写信息 → 提交
class RecycleOrderCreatePage extends ConsumerStatefulWidget {
  final int userIdent;

  const RecycleOrderCreatePage({super.key, required this.userIdent});

  @override
  ConsumerState<RecycleOrderCreatePage> createState() =>
      _RecycleOrderCreatePageState();
}

class _RecycleOrderCreatePageState
    extends ConsumerState<RecycleOrderCreatePage> {
  final RecycleOrderApi _api = RecycleOrderApi();
  final EmployeeApi _empApi = EmployeeApi();
  final ImagePicker _picker = ImagePicker();

  /// 当前步骤: 0=搜索设备, 1=选择规则, 2=答题评估, 3=填写信息
  int _step = 0;

  /// 搜索关键词
  final _searchController = TextEditingController();
  List<RecycleRuleSimple> _searchResults = [];
  bool _isSearching = false;

  /// 选中的规则
  RecycleRuleSimple? _selectedRule;
  List<RecycleAnswer> _allAnswers = [];
  Map<int, int> _specAnswers = {}; // 规格题: questionId -> answerId
  List<int> _commonAnswers = []; // 常见问题: answerId[]
  List<int> _otherAnswers = []; // 其他问题: answerId[]
  bool _isLoadingAnswers = false;

  /// 估价结果
  RecyclePriceResult? _priceResult;
  bool _isPricing = false;

  /// 提交信息
  final _serialController = TextEditingController();
  final _markupController = TextEditingController();
  String _paymentType = '银行卡';
  final _embitterController = TextEditingController();
  final _accountController = TextEditingController();
  final _remarksController = TextEditingController();

  /// 照片（5张）
  List<String?> _photos = [null, null, null, null, null];
  bool _isUploadingPhoto = false;

  /// 提交状态
  bool _isSubmitting = false;

  /// 员工信息
  Employee? _currentEmployee;
  int? _currentDepartmentId;

  /// 问题分页索引（保留用于未来多步骤UI）
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
  }

  Future<void> _loadCurrentEmployee() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      final employees = await _empApi.getByUserIdents([user.userIdent]);
      if (employees.isNotEmpty) {
        final emp = employees.first;
        setState(() {
          _currentEmployee = emp;
          _currentDepartmentId =
              emp.currentDepartmentId ?? emp.departmentId;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serialController.dispose();
    _markupController.dispose();
    _embitterController.dispose();
    _accountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ================================================================
  // 步骤0：搜索设备
  // ================================================================
  Future<void> _searchDevice() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await _api.getRecycleRulesByTitles(keyword);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _showError('搜索失败: $e');
    }
  }

  void _selectRule(RecycleRuleSimple rule) {
    setState(() {
      _selectedRule = rule;
      _step = 1;
    });
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    if (_selectedRule == null) return;
    setState(() => _isLoadingAnswers = true);
    try {
      final answers = await _api.getRecycleAnswer(_selectedRule!.id);
      setState(() {
        _allAnswers = answers;
        _isLoadingAnswers = false;
        _step = 2;
        _currentQuestionIndex = 0;
      });
    } catch (e) {
      setState(() => _isLoadingAnswers = false);
      _showError('加载问答失败: $e');
    }
  }

  // ================================================================
  // 步骤2：答题评估
  // ================================================================

  /// 获取按问题分组的规格问题
  List<_QuestionGroup> get _specQuestions {
    final grouped = <int, _QuestionGroup>{};
    for (final a in _allAnswers.where((a) => a.isSpec)) {
      if (!grouped.containsKey(a.questionId)) {
        grouped[a.questionId] = _QuestionGroup(
          questionId: a.questionId,
          question: a.question,
          answers: [],
        );
      }
      grouped[a.questionId]!.answers.add(a);
    }
    return grouped.values.toList();
  }

  /// 获取常见问题列表
  List<RecycleAnswer> get _commonQuestionList {
    return _allAnswers.where((a) => a.isCommon && !a.disability).toList();
  }

  /// 获取其他问题列表
  List<RecycleAnswer> get _otherQuestionList {
    return _allAnswers.where((a) => a.isOther && !a.disability).toList();
  }

  /// 选择规格答案
  void _selectSpecAnswer(int questionId, int answerId) {
    setState(() {
      _specAnswers[questionId] = answerId;
    });
    // 自动跳到下一个规格问题
    final specs = _specQuestions;
    final currentIdx =
        specs.indexWhere((q) => q.questionId == questionId);
    if (currentIdx < specs.length - 1) {
      setState(() {
        _currentQuestionIndex = currentIdx + 1;
      });
    }
  }

  /// 切换常见问题答案
  void _toggleCommonAnswer(int answerId) {
    setState(() {
      if (_commonAnswers.contains(answerId)) {
        _commonAnswers.remove(answerId);
      } else {
        _commonAnswers.add(answerId);
      }
    });
  }

  /// 切换其他问题答案
  void _toggleOtherAnswer(int answerId) {
    setState(() {
      if (_otherAnswers.contains(answerId)) {
        _otherAnswers.remove(answerId);
      } else {
        _otherAnswers.add(answerId);
      }
    });
  }

  /// 检查是否可以进入下一阶段
  bool get _canCalculate {
    // 必须完成所有规格题
    final specs = _specQuestions;
    if (specs.isNotEmpty && _specAnswers.length < specs.length) {
      return false;
    }
    return true;
  }

  Future<void> _calculatePrice() async {
    if (_selectedRule == null) return;

    // 构建 selects 列表
    final selectIds = <int>[
      ..._specAnswers.values,
      ..._commonAnswers,
      ..._otherAnswers,
    ];

    if (selectIds.isEmpty) {
      _showError('请先完成设备评估');
      return;
    }

    setState(() => _isPricing = true);
    try {
      final result = await _api.getRecycleRulePrice(_selectedRule!.id, selectIds);
      setState(() {
        _priceResult = result;
        _isPricing = false;
        _step = 3;
      });
    } catch (e) {
      setState(() => _isPricing = false);
      _showError('估价失败: $e');
    }
  }

  // ================================================================
  // 步骤3：填写信息并提交
  // ================================================================

  /// 计算实际回收金额
  int get _recoveryAmount {
    if (_priceResult == null) return 0;
    final markup = double.tryParse(_markupController.text) ?? 0;
    return _priceResult!.evalAmount + (markup * 100).round();
  }

  /// 构建 selects 列表用于提交
  List<int> get _submitSelects {
    return [
      ..._specAnswers.values,
      ..._commonAnswers,
      ..._otherAnswers,
    ];
  }

  /// 构建 specification 列表（规格答案内容）
  List<String> get _specifications {
    return _specQuestions.map((q) {
      final answerId = _specAnswers[q.questionId];
      final answer = q.answers.firstWhere(
        (a) => a.id == answerId,
        orElse: () => q.answers.first,
      );
      return answer.content;
    }).toList();
  }

  Future<void> _pickPhoto(int index) async {
    // ignore: use_build_context_synchronously
    final source = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择图片来源'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('拍照'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('从相册选择'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source == 0
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      // 上传图片
      final tokenService = TokenService();
      final token = await tokenService.getToken();
      if (token == null || token.isEmpty) {
        _showError('未登录');
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path,
            filename: '${_selectedRule!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg'),
        'token': token,
      });

      final client = ApiClient();
      final resp = await client.uploadFile('/upload', data: formData);

      final url = resp.data['url'] as String? ??
                 resp.data['result'] as String? ?? '';

      if (mounted) {
        setState(() {
          _photos[index] = url;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showError('图片上传失败: $e');
      }
    }
  }

  Future<void> _submit() async {
    // 验证必填项
    if (_serialController.text.trim().isEmpty) {
      _showError('请输入设备序列号');
      return;
    }
    if (_embitterController.text.trim().isEmpty) {
      _showError('请输入打款人');
      return;
    }
    if (_accountController.text.trim().isEmpty) {
      _showError('请输入打款账号');
      return;
    }
    if (_currentDepartmentId == null) {
      _showError('未获取到部门信息');
      return;
    }
    if (_currentEmployee == null) {
      _showError('未获取到员工信息');
      return;
    }
    // 检查5张照片
    if (_photos.where((p) => p != null && p.isNotEmpty).length < 5) {
      _showError('请上传全部5张照片');
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      _showError('未登录');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _api.add(
        customer: widget.userIdent,
        ruleId: _selectedRule!.id,
        serial: _serialController.text.trim(),
        paymentType: _paymentType,
        actualAmount: _recoveryAmount,
        evalAmount: _priceResult?.evalAmount ?? 0,
        costAmount: _priceResult?.costAmount ?? 0,
        department: _currentDepartmentId!,
        operator: user.userIdent,
        selects: _submitSelects,
        images: _photos.whereType<String>().toList(),
        specification: _specifications,
        payInfo:
            '${_embitterController.text.trim()}-${_accountController.text.trim()}',
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result != null && result.isNotEmpty) {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('提交成功'),
              content: Text('回收单号: $result'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                    context.pop();
                  },
                ),
              ],
            ),
          );
        } else {
          _showError('提交失败，请重试');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('提交失败: $e');
      }
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_stepTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
        trailing: _step == 2
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _canCalculate
                    ? () => _calculatePrice()
                    : null,
                child: _isPricing
                    ? const CupertinoActivityIndicator()
                    : Text(
                        '估价',
                        style: TextStyle(
                          color: _canCalculate
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                        ),
                      ),
              )
            : null,
      ),
      child: SafeArea(child: _buildCurrentStep()),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return '搜索设备';
      case 1:
        return '设备详情';
      case 2:
        return '设备评估';
      case 3:
        return '填写信息';
      default:
        return '回收加单';
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildSearchStep();
      case 1:
        return _buildRuleDetailStep();
      case 2:
        return _buildQuestionStep();
      case 3:
        return _buildSubmitStep();
      default:
        return const Center(child: CupertinoActivityIndicator());
    }
  }

  // ================================================================
  // 步骤0：搜索设备
  // ================================================================
  Widget _buildSearchStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: '搜索设备名称或型号',
            onSubmitted: (_) => _searchDevice(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _searchDevice,
              child: _isSearching
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('搜索'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _isSearching
              ? const Center(child: CupertinoActivityIndicator())
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.search,
                              size: 48, color: CupertinoColors.systemGrey),
                          const SizedBox(height: 8),
                          Text('输入设备名称搜索',
                              style: AppText.body.copyWith(
                                  color: CupertinoColors.secondaryLabel)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final rule = _searchResults[i];
                        return _RuleCard(
                          rule: rule,
                          onTap: () => _selectRule(rule),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ================================================================
  // 步骤1：规则详情（加载中）
  // ================================================================
  Widget _buildRuleDetailStep() {
    if (_isLoadingAnswers) {
      return const Center(child: CupertinoActivityIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(height: 16),
          const Text('加载评估问题中...'),
        ],
      ),
    );
  }

  // ================================================================
  // 步骤2：答题评估
  // ================================================================
  Widget _buildQuestionStep() {
    if (_allAnswers.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final specs = _specQuestions;
    final commons = _commonQuestionList;
    final others = _otherQuestionList;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 设备名称
          if (_selectedRule != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF5856D6)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                _selectedRule!.title,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 规格问题
          if (specs.isNotEmpty) ...[
            _SectionTitle('设备规格'),
            const SizedBox(height: AppSpacing.sm),
            ...specs.map((q) => _SpecQuestionWidget(
                  group: q,
                  selectedAnswerId: _specAnswers[q.questionId],
                  onSelect: (answerId) =>
                      _selectSpecAnswer(q.questionId, answerId),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 常见问题
          if (commons.isNotEmpty) ...[
            _SectionTitle('常见问题'),
            const SizedBox(height: AppSpacing.sm),
            ...commons.map((a) => _AnswerToggleItem(
                  answer: a,
                  isSelected: _commonAnswers.contains(a.id),
                  onToggle: () => _toggleCommonAnswer(a.id),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 其他问题
          if (others.isNotEmpty) ...[
            _SectionTitle('其他问题'),
            const SizedBox(height: AppSpacing.sm),
            ...others.map((a) => _AnswerToggleItem(
                  answer: a,
                  isSelected: _otherAnswers.contains(a.id),
                  onToggle: () => _toggleOtherAnswer(a.id),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 完成按钮
          if (_canCalculate)
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isPricing ? null : () => _calculatePrice(),
                child: _isPricing
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white)
                    : const Text('开始估价'),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: CupertinoColors.systemYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                '请完成所有设备规格评估',
                style: TextStyle(color: CupertinoColors.systemOrange),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ================================================================
  // 步骤3：填写信息
  // ================================================================
  Widget _buildSubmitStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 会员信息卡片
          _InfoCard(
            title: '会员信息',
            rows: [
              _InfoRow('会员ID', widget.userIdent.toString()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 设备信息
          _InfoCard(
            title: '设备信息',
            rows: [
              _InfoRow('设备名称', _selectedRule?.title ?? ''),
              _InfoRow(
                '系统估价',
                _priceResult != null
                    ? '¥${_priceResult!.evalAmountYuan.toStringAsFixed(2)}'
                    : '-'),
              _InfoRow(
                '加价金额',
                _priceResult != null
                    ? '¥${_priceResult!.costAmountYuan.toStringAsFixed(2)}'
                    : '-'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 设备序列号
          _InputCard(
            title: '设备序列号',
            child: CupertinoTextField(
              controller: _serialController,
              placeholder: '请输入设备序列号',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 调价
          _InputCard(
            title: '调价金额 (+)',
            child: CupertinoTextField(
              controller: _markupController,
              placeholder: '选填，请输入加价金额',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 照片上传
          _PhotoUploadSection(
            photos: _photos,
            onPick: _pickPhoto,
            isUploading: _isUploadingPhoto,
          ),
          const SizedBox(height: AppSpacing.md),

          // 支付信息
          _InputCard(
            title: '支付信息',
            child: Column(
              children: [
                _FormField(
                  label: '支付方式',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showPaymentTypePicker(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_paymentType,
                            style: const TextStyle(
                                color: CupertinoColors.black)),
                        const Icon(CupertinoIcons.chevron_down,
                            size: 16, color: CupertinoColors.systemGrey),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: CupertinoColors.systemGrey5),
                _FormField(
                  label: '打款人',
                  child: CupertinoTextField(
                    controller: _embitterController,
                    placeholder: '必填',
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(),
                  ),
                ),
                const Divider(height: 1, color: CupertinoColors.systemGrey5),
                _FormField(
                  label: '打款账号',
                  child: CupertinoTextField(
                    controller: _accountController,
                    placeholder: '必填',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 用户备注
          _InputCard(
            title: '用户备注',
            child: CupertinoTextField(
              controller: _remarksController,
              placeholder: '选填',
              maxLines: 3,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 总计
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('实际回收金额', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '¥${(_recoveryAmount / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 提交按钮
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isSubmitting ? null : () => _submit(),
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('提交回收单'),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showPaymentTypePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择支付方式'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _paymentType = '银行卡');
              Navigator.pop(ctx);
            },
            child: const Text('银行卡'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _paymentType = '现金');
              Navigator.pop(ctx);
            },
            child: const Text('现金'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _paymentType = '微信');
              Navigator.pop(ctx);
            },
            child: const Text('微信'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _paymentType = '支付宝');
              Navigator.pop(ctx);
            },
            child: const Text('支付宝'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }
}

// ================================================================
// 辅助组件
// ================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RecycleRuleSimple rule;
  final VoidCallback onTap;
  const _RuleCard({required this.rule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.device_phone_portrait,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rule.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }
}

class _SpecQuestionWidget extends StatelessWidget {
  final _QuestionGroup group;
  final int? selectedAnswerId;
  final void Function(int) onSelect;
  const _SpecQuestionWidget({
    required this.group,
    this.selectedAnswerId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selectedAnswerId != null
              ? AppColors.primary.withValues(alpha: 0.3)
              : CupertinoColors.systemGrey5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.answers.map((answer) {
              final isSelected = selectedAnswerId == answer.id;
              return GestureDetector(
                onTap: () => onSelect(answer.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    answer.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AnswerToggleItem extends StatelessWidget {
  final RecycleAnswer answer;
  final bool isSelected;
  final VoidCallback onToggle;
  const _AnswerToggleItem({
    required this.answer,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : CupertinoColors.systemGrey5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: isSelected ? AppColors.primary : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answer.question,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    answer.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const Divider(height: 1, color: CupertinoColors.systemGrey5),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label,
                        style:
                            TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                    Text(r.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _InputCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InputCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PhotoUploadSection extends StatelessWidget {
  final List<String?> photos;
  final void Function(int) onPick;
  final bool isUploading;
  const _PhotoUploadSection({
    required this.photos,
    required this.onPick,
    required this.isUploading,
  });

  static const _photoLabels = [
    '开机正面关于本机界面图',
    '机身背面照片',
    '指纹/面容图',
    '侧面机身直立照片',
    '手机拆机后主板图',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '验机照片 (5张)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: List.generate(5, (i) {
                final photo = photos[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: isUploading ? null : () => onPick(i),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: photo != null
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.systemGrey4,
                            ),
                          ),
                          child: isUploading
                              ? const Center(
                                  child: CupertinoActivityIndicator(),
                                )
                              : photo != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildPlaceholder(i),
                                      ),
                                    )
                                  : _buildPlaceholder(i),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第${i + 1}张: ${_photoLabels[i]}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              photo != null ? '已上传 ✓' : '点击上传',
                              style: TextStyle(
                                fontSize: 11,
                                color: photo != null
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.camera,
            size: 24, color: CupertinoColors.systemGrey),
        const SizedBox(height: 2),
        Text(
          '${index + 1}',
          style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }
}

class _QuestionGroup {
  final int questionId;
  final String question;
  final List<RecycleAnswer> answers;
  _QuestionGroup({
    required this.questionId,
    required this.question,
    required this.answers,
  });
}

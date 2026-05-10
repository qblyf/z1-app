import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/financial_expense_api.dart';
import '../../models/financial_expense.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 财务结算单页面
/// 对应 PWA /pages/path-d/financial-expense/settlement-order.tsx
///
/// 流程：选择支出单 → 填写结算金额/申请标题/申请内容 → 添加款项 → 提交结算审批
class SettlementOrderPage extends ConsumerStatefulWidget {
  final int expenseId;

  const SettlementOrderPage({super.key, required this.expenseId});

  @override
  ConsumerState<SettlementOrderPage> createState() => _SettlementOrderPageState();
}

class _SettlementOrderPageState extends ConsumerState<SettlementOrderPage> {
  final FinancialExpenseApi _api = financialExpenseApi;

  FinancialExpense? _expense;
  bool _isLoading = true;
  String? _error;

  // 表单字段
  String? _applyTitle;
  String? _applyContent;
  int? _settlementAmount; // 单位：分
  final List<SettlementInfo> _infos = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expense = await _api.fullDetail(widget.expenseId);
      setState(() {
        _expense = expense;
        _applyTitle = expense?.title;
        _applyContent = expense?.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int get _totalAmount => _expense?.totalAmount ?? 0;
  int get _pendingAmount {
    final paid = _infos.fold(0, (sum, info) => sum + info.amount);
    return _settlementAmount != null ? _settlementAmount! - _totalAmount + paid : 0;
  }

  String _renderFen(int fen) => '¥${(fen / 100).toStringAsFixed(2)}';

  Future<void> _submit() async {
    if (_expense == null) return;

    // 校验
    if ((_applyTitle ?? '').trim().isEmpty) {
      _showTip('请输入申请标题');
      return;
    }
    if ((_applyContent ?? '').trim().isEmpty) {
      _showTip('请输入申请内容');
      return;
    }
    if (_settlementAmount == null || _settlementAmount! <= 0) {
      _showTip('请输入结算金额');
      return;
    }
    if (_infos.isEmpty) {
      _showTip('请添加款项信息');
      return;
    }

    // 校验：填写的款项信息与应付金额相符
    final infoTotal = _infos.fold(0, (sum, info) => sum + info.amount);
    if (_settlementAmount! - _totalAmount != infoTotal) {
      _showTip('填写的款项信息与应付金额不相符');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final id = await _api.addSettlementApproval(
        financialExpensesType: _expense!.financialExpensesType,
        businessType: _expense!.businessType,
        title: _applyTitle!.trim(),
        content: _applyContent!.trim(),
        infos: _infos,
        settleAmount: _settlementAmount!,
        associated: _expense!.number,
      );
      if (id != null) {
        _showTip('提交成功！');
        if (mounted) context.pop();
      } else {
        _showTip('提交失败');
      }
    } catch (e) {
      _showTip('提交失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showTip(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showTitleInput() {
    final controller = TextEditingController(text: _applyTitle ?? '');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('申请标题'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: '请输入申请标题',
              maxLength: 50,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              setState(() => _applyTitle = controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showContentInput() {
    final controller = TextEditingController(text: _applyContent ?? '');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('申请内容'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: '请输入申请内容',
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              setState(() => _applyContent = controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAmountInput() {
    final controller = TextEditingController(
      text: _settlementAmount != null ? (_settlementAmount! / 100).toStringAsFixed(2) : '',
    );
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('结算金额'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: '请输入金额（元）',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final yuan = double.tryParse(controller.text.trim());
              if (yuan != null && yuan > 0) {
                setState(() => _settlementAmount = (yuan * 100).round());
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _onAddInfo() {
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('新增款项'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: amountController,
              placeholder: '金额（元）',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: remarkController,
              placeholder: '备注（选填）',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final yuanText = amountController.text.trim();
              final yuan = double.tryParse(yuanText);
              if (yuan == null || yuan <= 0) return;
              final amountFen = (yuan * 100).round();
              setState(() {
                _infos.add(SettlementInfo(
                  key: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: amountFen,
                  remarks: remarkController.text.trim().isEmpty ? null : remarkController.text.trim(),
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
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
        middle: const Text('财务结算单'),
        trailing: _isSubmitting ? const CupertinoActivityIndicator() : null,
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CupertinoActivityIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $_error', style: const TextStyle(color: CupertinoColors.systemRed)),
            const SizedBox(height: 16),
            CupertinoButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_expense == null) return const Center(child: Text('未找到该支出单'));

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBaseInfo(),
                const SizedBox(height: 16),
                _buildExpenseInfos(),
                const SizedBox(height: 12),
                _buildAddInfoButton(),
                const SizedBox(height: 16),
                _buildSettlementInfos(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBaseInfo() {
    final user = ref.read(currentUserProvider).value;
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('基础信息'),
          _infoRow('部门', _expense!.departmentID?.toString() ?? '-'),
          _infoRow('申请人', user?.realName ?? '-'),
          _infoRow('业务类型', _expense!.businessType),
          _infoRow('关联预支支出单', _expense!.number),
          _infoRow('预支金额', _renderFen(_totalAmount)),
          _buildTappableRow(
            label: '结算金额',
            value: _settlementAmount != null ? _renderFen(_settlementAmount!) : '请输入',
            onTap: _showAmountInput,
          ),
          _infoRow('应付金额', _pendingAmount > 0 ? _renderFen(_pendingAmount) : _renderFen(0)),
          _buildTappableRow(
            label: '申请标题',
            value: (_applyTitle ?? '').isEmpty ? '请输入' : _applyTitle!,
            isPlaceholder: (_applyTitle ?? '').isEmpty,
            onTap: _showTitleInput,
          ),
          _buildTappableRow(
            label: '申请内容',
            value: (_applyContent ?? '').isEmpty ? '请输入' : _applyContent!,
            isPlaceholder: (_applyContent ?? '').isEmpty,
            onTap: _showContentInput,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseInfos() {
    if (_expense!.infos.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('预支款项内容'),
          ..._expense!.infos.asMap().entries.map((entry) {
            final idx = entry.key;
            final info = entry.value;
            return _expenseInfoCard(info, idx + 1);
          }),
        ],
      ),
    );
  }

  Widget _expenseInfoCard(FinancialExpenseInfo info, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('款项 $index', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              Text(info.amountDisplay, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          if (info.remarks != null && info.remarks!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(info.remarks!, style: AppText.caption.copyWith(color: CupertinoColors.secondaryLabel)),
          ],
        ],
      ),
    );
  }

  Widget _buildAddInfoButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: AppColors.primary.withValues(alpha: 0.1),
        onPressed: _onAddInfo,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.plus_circle, color: AppColors.primary, size: 18),
            SizedBox(width: 6),
            Text('新增款项', style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementInfos() {
    if (_infos.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('款项内容'),
          ..._infos.asMap().entries.map((entry) {
            final idx = entry.key;
            final info = entry.value;
            return _settlementInfoCard(info, idx + 1);
          }),
        ],
      ),
    );
  }

  Widget _settlementInfoCard(SettlementInfo info, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('款项 $index', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                if (info.remarks != null) ...[
                  const SizedBox(height: 4),
                  Text(info.remarks!, style: AppText.caption),
                ],
              ],
            ),
          ),
          Text(
            '¥${(info.amount / 100).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              setState(() => _infos.removeAt(index - 1));
            },
            child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('提交结算审批'),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 14),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: CupertinoColors.label.resolveFrom(context)),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableRow({
    required String label,
    required String value,
    bool isPlaceholder = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 14),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isPlaceholder
                      ? CupertinoColors.tertiaryLabel.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
